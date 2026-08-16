import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/palete.dart';
import '../local/app_database.dart';
import '../local/rede.dart';
import '../remote/supabase_provider.dart';

const _camposFichaTecnica =
    'codigo_ft, qp_padrao, pacotes_por_camada, pecas_por_pacote, '
    'clientes(razao_social), composicoes(espessura_mm)';
const _selectComJoins = '*, fichas_tecnicas($_camposFichaTecnica)';
const _selectComJoinsFiltradoPorFt = '*, fichas_tecnicas!inner($_camposFichaTecnica)';

const _selectPaleteComRevisor = '*, revisor:profiles!paletes_revisado_por_fkey(nome)';

const _uuid = Uuid();

/// Camada de dados de OP/palete, com fallback pro cache local (Drift)
/// quando a rede falha — ver plano técnico, seção de modo offline. Só
/// cobre a leitura de OPs/paletes e o apontamento em si (Fase 1); refugo,
/// ocorrências e cadastros continuam exigindo conexão por enquanto.
class PaletesRepository {
  final SupabaseClient _client;
  final AppDatabase _db;
  PaletesRepository(this._client, this._db);

  Future<List<OrdemProducaoInfo>> listarOrdensAbertas() async {
    try {
      final dados = await _client
          .from('ordens_producao')
          .select(_selectComJoins)
          .eq('status', 'aberta')
          .order('data_pedido')
          .timeout(timeoutRede);
      final ordens = (dados as List).map((e) => OrdemProducaoInfo.fromMap(e)).toList();
      await _db.upsertOrdens(ordens.map(_paraLocalOrdem).toList(), podarAusentes: true);
      return ordens;
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      final cache = await _db.listarOrdensCache();
      return cache.map(_deLocalOrdem).toList();
    }
  }

  Future<OrdemProducaoInfo?> buscarPorNumeroOp(String numeroOp) async {
    final dados = await _client
        .from('ordens_producao')
        .select(_selectComJoins)
        .eq('numero_op', numeroOp)
        .maybeSingle();
    return dados == null ? null : OrdemProducaoInfo.fromMap(dados);
  }

  Future<List<OrdemProducaoInfo>> buscarPorFichaTecnica(String codigoFt) async {
    final dados = await _client
        .from('ordens_producao')
        .select(_selectComJoinsFiltradoPorFt)
        .eq('fichas_tecnicas.codigo_ft', codigoFt)
        .order('data_pedido');
    return (dados as List).map((e) => OrdemProducaoInfo.fromMap(e)).toList();
  }

  /// Só entram OPs com prefixo 802 (as que precisam de Conversão — ver
  /// plano técnico, seção 1) que já têm pelo menos 1 palete apontado pela
  /// Onduladeira. Não exige que a Onduladeira tenha terminado a OP: a
  /// Conversão pode ir processando à medida que os paletes saem de lá.
  ///
  /// Offline, o filtro fica mais simples (só prefixo + status, sem
  /// confirmar que já tem palete da Onduladeira) — degradação aceitável
  /// enquanto não há conexão pra checar de verdade.
  Future<List<OrdemProducaoInfo>> listarOrdensDisponiveisConversao() async {
    try {
      final dados = await _client
          .from('ordens_producao')
          .select('$_selectComJoins, paletes!inner(id)')
          .eq('status', 'aberta')
          .like('numero_op', '802%')
          .eq('paletes.setor_origem', 'onduladeira')
          .order('data_pedido')
          .timeout(timeoutRede);
      final ordens = (dados as List).map((e) => OrdemProducaoInfo.fromMap(e)).toList();
      await _db.upsertOrdens(ordens.map(_paraLocalOrdem).toList());
      return ordens;
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      final cache = await _db.listarOrdensCache();
      return cache
          .where((o) => o.status == 'aberta' && o.numeroOp.startsWith('802'))
          .map(_deLocalOrdem)
          .toList();
    }
  }

  Future<Palete> buscarPaletePorId(String id) async {
    final dados = await _client.from('paletes').select(_selectPaleteComRevisor).eq('id', id).single();
    return Palete.fromMap(dados);
  }

  Future<List<Palete>> listarPaletesDaOrdem(String ordemProducaoId) async {
    try {
      final dados = await _client
          .from('paletes')
          .select(_selectPaleteComRevisor)
          .eq('ordem_producao_id', ordemProducaoId)
          .order('numero_sequencial')
          .timeout(timeoutRede);
      final paletes = (dados as List).map((e) => Palete.fromMap(e)).toList();
      await _db.upsertPaletesSincronizados(ordemProducaoId, paletes.map(_paraLocalPalete).toList());
      final pendentes = (await _db.listarPaletesCache(ordemProducaoId))
          .where((p) => !p.sincronizado)
          .map(_deLocalPalete);
      return [...paletes, ...pendentes];
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      final cache = await _db.listarPaletesCache(ordemProducaoId);
      return cache.map(_deLocalPalete).toList();
    }
  }

  /// Onduladeira: quantidade = (altura ÷ espessura da composição) ×
  /// qp_padrão da FT — conta chapas, medindo altura em mm.
  /// Conversão: quantidade = camadas × pacotes por camada × peças por
  /// pacote — conta caixas já paletizadas, contando camadas direto (não
  /// mede mm — ver plano técnico, 9.1).
  ///
  /// numero_sequencial é o próximo da OP (não por setor — o unique
  /// constraint do banco é só em ordem_producao_id + numero_sequencial);
  /// se dois apontamentos colidirem nesse número, o banco rejeita e o app
  /// mostra o erro (fluxo de um operador por vez, então a colisão é rara).
  ///
  /// tipo_chapa nunca é escolha do usuário. Pra Conversão é sempre
  /// 'elaborado' (ela só processa OP 802, que sai da Onduladeira ainda
  /// semi-elaborada e vira elaborada ao passar por lá). Pra Onduladeira
  /// depende do prefixo da OP: 803 já é o produto final ('elaborado', vai
  /// direto pra Expedição sem Conversão); 802 ainda é intermediário
  /// ('semi_elaborado', precisa da Conversão depois) — ver plano técnico,
  /// seção 1.
  ///
  /// Se a rede falhar, grava um apontamento pendente no cache local (com
  /// um id gerado no aparelho) em vez de propagar o erro — o número
  /// sequencial definitivo só é atribuído quando sincronizar de verdade,
  /// pra não colidir com outro aparelho que apontou offline pra mesma OP
  /// (ver plano técnico, modo offline).
  Future<void> registrarPalete({
    required OrdemProducaoInfo ordem,
    required String responsavelId,
    required String setorOrigem,
    double? alturaMedidaMm,
    int? camadas,
  }) async {
    final quantidadeCalculada = _calcularQuantidade(
      ordem: ordem,
      setorOrigem: setorOrigem,
      alturaMedidaMm: alturaMedidaMm,
      camadas: camadas,
    );
    final tipoChapa = setorOrigem == 'conversao' || ordem.numeroOp.startsWith('803')
        ? 'elaborado'
        : 'semi_elaborado';

    try {
      final ultimo = await _client
          .from('paletes')
          .select('numero_sequencial')
          .eq('ordem_producao_id', ordem.id)
          .order('numero_sequencial', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(timeoutRede);
      final proximoNumero = (ultimo?['numero_sequencial'] as int? ?? 0) + 1;

      await _client.from('paletes').insert({
        'ordem_producao_id': ordem.id,
        'numero_sequencial': proximoNumero,
        'altura_medida_mm': alturaMedidaMm,
        'camadas': camadas,
        'quantidade_calculada': quantidadeCalculada,
        'tipo_chapa': tipoChapa,
        'setor_origem': setorOrigem,
        'responsavel_id': responsavelId,
      }).timeout(timeoutRede);
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      await _db.inserirPendente(
        LocalPaletesCompanion.insert(
          id: _uuid.v4(),
          ordemProducaoId: ordem.id,
          alturaMedidaMm: Value(alturaMedidaMm),
          camadas: Value(camadas),
          quantidadeCalculada: quantidadeCalculada,
          tipoChapa: tipoChapa,
          setorOrigem: setorOrigem,
          responsavelId: responsavelId,
          dataHora: DateTime.now(),
          saldoDisponivel: quantidadeCalculada,
          sincronizado: const Value(false),
        ),
      );
    }
  }

  /// Manda pro servidor tudo que ficou pendente offline. Falha item a
  /// item — um apontamento com erro não trava os outros — e guarda a
  /// mensagem de erro pra aparecer na lista em vez de ficar tentando de
  /// novo sozinho sem avisar ninguém.
  Future<void> sincronizarPendentes() async {
    final pendentes = await _db.listarPendentes();
    for (final pendente in pendentes) {
      try {
        final ultimo = await _client
            .from('paletes')
            .select('numero_sequencial')
            .eq('ordem_producao_id', pendente.ordemProducaoId)
            .order('numero_sequencial', ascending: false)
            .limit(1)
            .maybeSingle()
            .timeout(timeoutRede);
        final proximoNumero = (ultimo?['numero_sequencial'] as int? ?? 0) + 1;

        await _client.from('paletes').insert({
          'ordem_producao_id': pendente.ordemProducaoId,
          'numero_sequencial': proximoNumero,
          'altura_medida_mm': pendente.alturaMedidaMm,
          'camadas': pendente.camadas,
          'quantidade_calculada': pendente.quantidadeCalculada,
          'tipo_chapa': pendente.tipoChapa,
          'setor_origem': pendente.setorOrigem,
          'responsavel_id': pendente.responsavelId,
        }).timeout(timeoutRede);
        await _db.removerPalete(pendente.id);
      } catch (e) {
        await _db.marcarErroSincronizacao(pendente.id, e.toString());
      }
    }
  }

  int _calcularQuantidade({
    required OrdemProducaoInfo ordem,
    required String setorOrigem,
    double? alturaMedidaMm,
    int? camadas,
  }) {
    if (setorOrigem == 'conversao') {
      if (ordem.pacotesPorCamada == null || ordem.pecasPorPacote == null) {
        throw Exception(
          'Ficha Técnica sem dados de paletização da Conversão '
          '(pacotes por camada, peças por pacote).',
        );
      }
      return camadas! * ordem.pacotesPorCamada! * ordem.pecasPorPacote!;
    }
    return ((alturaMedidaMm! / ordem.composicaoEspessuraMm) * ordem.qpPadrao).floor();
  }
}

LocalOrdensCompanion _paraLocalOrdem(OrdemProducaoInfo o) => LocalOrdensCompanion.insert(
      id: o.id,
      numeroOp: o.numeroOp,
      quantidadePedida: o.quantidadePedida,
      dataPedido: o.dataPedido,
      status: o.status,
      codigoFt: o.codigoFt,
      qpPadrao: o.qpPadrao,
      clienteNome: o.clienteNome,
      composicaoEspessuraMm: o.composicaoEspessuraMm,
      pacotesPorCamada: Value(o.pacotesPorCamada),
      pecasPorPacote: Value(o.pecasPorPacote),
    );

OrdemProducaoInfo _deLocalOrdem(LocalOrden o) => OrdemProducaoInfo(
      id: o.id,
      numeroOp: o.numeroOp,
      quantidadePedida: o.quantidadePedida,
      dataPedido: o.dataPedido,
      status: o.status,
      codigoFt: o.codigoFt,
      qpPadrao: o.qpPadrao,
      clienteNome: o.clienteNome,
      composicaoEspessuraMm: o.composicaoEspessuraMm,
      pacotesPorCamada: o.pacotesPorCamada,
      pecasPorPacote: o.pecasPorPacote,
    );

LocalPaletesCompanion _paraLocalPalete(Palete p) => LocalPaletesCompanion.insert(
      id: p.id,
      ordemProducaoId: p.ordemProducaoId,
      numeroSequencial: Value(p.numeroSequencial),
      alturaMedidaMm: Value(p.alturaMedidaMm),
      camadas: Value(p.camadas),
      quantidadeCalculada: p.quantidadeCalculada,
      tipoChapa: p.tipoChapa,
      setorOrigem: p.setorOrigem,
      responsavelId: p.responsavelId,
      dataHora: p.dataHora,
      quantidadeReprovada: Value(p.quantidadeReprovada),
      saldoDisponivel: p.saldoDisponivel,
      revisorNome: Value(p.revisorNome),
      sincronizado: const Value(true),
    );

Palete _deLocalPalete(LocalPalete p) => Palete(
      id: p.id,
      ordemProducaoId: p.ordemProducaoId,
      numeroSequencial: p.numeroSequencial,
      alturaMedidaMm: p.alturaMedidaMm,
      camadas: p.camadas,
      quantidadeCalculada: p.quantidadeCalculada,
      tipoChapa: p.tipoChapa,
      setorOrigem: p.setorOrigem,
      responsavelId: p.responsavelId,
      dataHora: p.dataHora,
      quantidadeReprovada: p.quantidadeReprovada,
      saldoDisponivel: p.saldoDisponivel,
      revisorNome: p.revisorNome,
      sincronizado: p.sincronizado,
      erroSincronizacao: p.erroSincronizacao,
    );

final paletesRepositoryProvider = Provider<PaletesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return PaletesRepository(client, db);
});
