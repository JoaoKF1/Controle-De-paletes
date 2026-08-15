import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/palete.dart';
import '../remote/supabase_provider.dart';

const _camposFichaTecnica =
    'codigo_ft, qp_padrao, pacotes_por_camada, pecas_por_pacote, '
    'clientes(razao_social), composicoes(espessura_mm)';
const _selectComJoins = '*, fichas_tecnicas($_camposFichaTecnica)';
const _selectComJoinsFiltradoPorFt = '*, fichas_tecnicas!inner($_camposFichaTecnica)';

const _selectPaleteComRevisor = '*, revisor:profiles!paletes_revisado_por_fkey(nome)';

class PaletesRepository {
  final SupabaseClient _client;
  PaletesRepository(this._client);

  Future<List<OrdemProducaoInfo>> listarOrdensAbertas() async {
    final dados = await _client
        .from('ordens_producao')
        .select(_selectComJoins)
        .eq('status', 'aberta')
        .order('data_pedido');
    return (dados as List).map((e) => OrdemProducaoInfo.fromMap(e)).toList();
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
  Future<List<OrdemProducaoInfo>> listarOrdensDisponiveisConversao() async {
    final dados = await _client
        .from('ordens_producao')
        .select('$_selectComJoins, paletes!inner(id)')
        .eq('status', 'aberta')
        .like('numero_op', '802%')
        .eq('paletes.setor_origem', 'onduladeira')
        .order('data_pedido');
    return (dados as List).map((e) => OrdemProducaoInfo.fromMap(e)).toList();
  }

  Future<Palete> buscarPaletePorId(String id) async {
    final dados = await _client.from('paletes').select(_selectPaleteComRevisor).eq('id', id).single();
    return Palete.fromMap(dados);
  }

  Future<List<Palete>> listarPaletesDaOrdem(String ordemProducaoId) async {
    final dados = await _client
        .from('paletes')
        .select(_selectPaleteComRevisor)
        .eq('ordem_producao_id', ordemProducaoId)
        .order('numero_sequencial');
    return (dados as List).map((e) => Palete.fromMap(e)).toList();
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
  Future<void> registrarPalete({
    required OrdemProducaoInfo ordem,
    required String responsavelId,
    required String setorOrigem,
    double? alturaMedidaMm,
    int? camadas,
  }) async {
    final int quantidadeCalculada;
    if (setorOrigem == 'conversao') {
      if (ordem.pacotesPorCamada == null || ordem.pecasPorPacote == null) {
        throw Exception(
          'Ficha Técnica sem dados de paletização da Conversão '
          '(pacotes por camada, peças por pacote).',
        );
      }
      quantidadeCalculada = camadas! * ordem.pacotesPorCamada! * ordem.pecasPorPacote!;
    } else {
      quantidadeCalculada = ((alturaMedidaMm! / ordem.composicaoEspessuraMm) * ordem.qpPadrao).floor();
    }
    final tipoChapa = setorOrigem == 'conversao' || ordem.numeroOp.startsWith('803')
        ? 'elaborado'
        : 'semi_elaborado';

    final ultimo = await _client
        .from('paletes')
        .select('numero_sequencial')
        .eq('ordem_producao_id', ordem.id)
        .order('numero_sequencial', ascending: false)
        .limit(1)
        .maybeSingle();
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
    });
  }
}

final paletesRepositoryProvider = Provider<PaletesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PaletesRepository(client);
});
