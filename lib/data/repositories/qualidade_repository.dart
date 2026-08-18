import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/ocorrencia_qualidade.dart';
import '../../domain/entities/palete.dart';
import '../../domain/entities/teste_qualidade.dart';
import '../local/app_database.dart';
import '../local/rede.dart';
import '../remote/supabase_provider.dart';

const _selectOcorrenciaComJoins =
    '*, paletes(numero_sequencial, ordens_producao(numero_op))';
const _selectTesteComJoins =
    '*, ordens_producao(numero_op, ficha_tecnica_id), '
    'registrador:profiles!testes_qualidade_registrado_por_fkey(nome)';
const _uuid = Uuid();

/// Débito de saldo genérico: usado tanto quando a Qualidade reprova/segrega
/// quanto quando o próprio setor exclui o que produziu. Nos dois casos o
/// palete perde saldo e a OP ganha um lançamento de refugo — só muda quem
/// aciona e se passa por uma ocorrência antes (ver plano técnico, 9.3/9.4).
///
/// `lancarRefugo` e `abrirOcorrencia` entram na fila offline (Fase 2, ver
/// 9.12) porque não dependem de ler nada fresco do servidor antes. As
/// outras ações desta classe (segregar, resolver, corrigir, excluir) ficam
/// de fora de propósito: todas debitam em cima do saldo *atual* do palete,
/// e fazer isso com dado desatualizado arrisca um débito incorreto — essas
/// continuam exigindo conexão.
class QualidadeRepository {
  final SupabaseClient _client;
  final AppDatabase _db;
  QualidadeRepository(this._client, this._db);

  Future<void> lancarRefugo({
    required String ordemProducaoId,
    required String responsavelId,
    required int quantidade,
    required String motivo,
  }) async {
    final dados = {
      'ordem_producao_id': ordemProducaoId,
      'responsavel_id': responsavelId,
      'quantidade': quantidade,
      'motivo': motivo,
    };
    try {
      await _client.from('refugos').insert(dados).timeout(timeoutRede);
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      await _db.inserirOperacaoPendenteMap(
        id: _uuid.v4(),
        tipo: 'refugo',
        dados: dados,
      );
    }
  }

  Future<void> abrirOcorrencia({
    required String paleteId,
    required int quantidadeAfetada,
    required String motivo,
    required String abertoPor,
  }) async {
    final dados = {
      'palete_id': paleteId,
      'quantidade_afetada': quantidadeAfetada,
      'motivo': motivo,
      'aberto_por': abertoPor,
    };
    try {
      await _client
          .from('ocorrencias_qualidade')
          .insert(dados)
          .timeout(timeoutRede);
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      await _db.inserirOperacaoPendenteMap(
        id: _uuid.v4(),
        tipo: 'ocorrencia_abrir',
        dados: dados,
      );
    }
  }

  /// Teste de qualidade de uma OP (não de um palete — ver plano técnico,
  /// 9.6): entra na fila offline igual aos outros cadastros/lançamentos que
  /// não dependem de ler o estado atual de nada no servidor antes (ver
  /// 9.13) — o tipo `testes_qualidade_criar` já é reconhecido pelo
  /// dispatcher genérico (`Sincronizador._enviar`) sem precisar de um caso
  /// novo. Só dispara a notificação push quando o insert vai direto (não
  /// quando cai pra fila offline — nesse caso ninguém precisa saber ainda,
  /// porque o teste nem existe de verdade no servidor).
  Future<void> registrarTeste({
    required String ordemProducaoId,
    required String registradoPor,
    double? gramaturaMedida,
    double? colunaMedida,
    double? cobbInternoMedido,
    double? cobbExternoMedido,
    double? mullenMedido,
    double? compressaoMedida,
    double? resinaInternaMedida,
    double? resinaExternaMedida,
  }) async {
    final dados = {
      'ordem_producao_id': ordemProducaoId,
      'registrado_por': registradoPor,
      'gramatura_medida': gramaturaMedida,
      'coluna_medida': colunaMedida,
      'cobb_interno_medido': cobbInternoMedido,
      'cobb_externo_medido': cobbExternoMedido,
      'mullen_medido': mullenMedido,
      'compressao_medida': compressaoMedida,
      'resina_interna_medida': resinaInternaMedida,
      'resina_externa_medida': resinaExternaMedida,
    };
    try {
      await _client.from('testes_qualidade').insert(dados).timeout(timeoutRede);
      unawaited(_notificarTeste(ordemProducaoId));
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      await _db.inserirOperacaoPendenteMap(
        id: _uuid.v4(),
        tipo: 'testes_qualidade_criar',
        dados: dados,
      );
    }
  }

  /// OPs pra tela de Testes de qualidade, com cliente/unidade e a contagem
  /// de testes já feitos em cada uma — 2 queries simples (OPs + contagem
  /// de testes agrupada em Dart), no lugar de agregação no banco, mesmo
  /// padrão de `_comProgressoOnduladeira` em `PaletesRepository`.
  Future<List<OrdemParaTeste>> listarOrdensParaTeste() async {
    final ops = await _client
        .from('ordens_producao')
        .select(
          'id, numero_op, status, ficha_tecnica_id, '
          'fichas_tecnicas(clientes(razao_social))',
        )
        .order('data_pedido', ascending: false);
    final testes = await _client
        .from('testes_qualidade')
        .select('ordem_producao_id');
    final contagem = <String, int>{};
    for (final t in testes as List) {
      final id = t['ordem_producao_id'] as String;
      contagem[id] = (contagem[id] ?? 0) + 1;
    }
    return (ops as List).map((o) {
      final numeroOp = o['numero_op'] as String;
      final ft = o['fichas_tecnicas'] as Map<String, dynamic>;
      final cliente = ft['clientes'] as Map<String, dynamic>;
      final id = o['id'] as String;
      return OrdemParaTeste(
        id: id,
        numeroOp: numeroOp,
        fichaTecnicaId: o['ficha_tecnica_id'] as String,
        clienteNome: cliente['razao_social'] as String,
        unidadePedido: numeroOp.startsWith('803') ? 'chapas' : 'caixas',
        status: o['status'] as String,
        totalTestes: contagem[id] ?? 0,
      );
    }).toList();
  }

  /// Mesmo formato de `listarOrdensParaTeste`, mas só pra 1 OP — usado pelo
  /// atalho que pula direto pros testes daquela OP a partir do detalhe da
  /// Onduladeira, sem passar pela lista/busca de Testes de qualidade.
  Future<OrdemParaTeste> buscarOrdemParaTeste(String ordemProducaoId) async {
    final o = await _client
        .from('ordens_producao')
        .select(
          'id, numero_op, status, ficha_tecnica_id, '
          'fichas_tecnicas(clientes(razao_social))',
        )
        .eq('id', ordemProducaoId)
        .single();
    final numeroOp = o['numero_op'] as String;
    final ft = o['fichas_tecnicas'] as Map<String, dynamic>;
    final cliente = ft['clientes'] as Map<String, dynamic>;
    final testes = await _client
        .from('testes_qualidade')
        .select('id')
        .eq('ordem_producao_id', ordemProducaoId);
    return OrdemParaTeste(
      id: o['id'] as String,
      numeroOp: numeroOp,
      fichaTecnicaId: o['ficha_tecnica_id'] as String,
      clienteNome: cliente['razao_social'] as String,
      unidadePedido: numeroOp.startsWith('803') ? 'chapas' : 'caixas',
      status: o['status'] as String,
      totalTestes: (testes as List).length,
    );
  }

  /// Dispara a Edge Function `notificar-teste-qualidade` (push pra
  /// Onduladeira no turno atual — ver plano técnico, 9.6/12). Fire-and-
  /// forget de propósito: notificação é um "a mais", nunca pode fazer o
  /// registro do teste parecer ter falhado se o push não sair.
  Future<void> _notificarTeste(String ordemProducaoId) async {
    try {
      await _client.functions.invoke(
        'notificar-teste-qualidade',
        body: {'ordem_producao_id': ordemProducaoId},
      );
    } catch (_) {
      // Sem Firebase configurado, sem internet, etc. — o teste já foi
      // salvo, a notificação é só um extra.
    }
  }

  Future<List<TesteQualidade>> listarTestesDaOrdem(
    String ordemProducaoId,
  ) async {
    final dados = await _client
        .from('testes_qualidade')
        .select(_selectTesteComJoins)
        .eq('ordem_producao_id', ordemProducaoId)
        .order('criado_em');
    return (dados as List).map((e) => TesteQualidade.fromMap(e)).toList();
  }

  Future<List<OcorrenciaQualidade>> listarEmAnalise() async {
    final dados = await _client
        .from('ocorrencias_qualidade')
        .select(_selectOcorrenciaComJoins)
        .eq('status', 'em_analise')
        .order('data_abertura');
    return (dados as List).map((e) => OcorrenciaQualidade.fromMap(e)).toList();
  }

  /// Resolve uma ocorrência em análise. `quantidadeReprovada` pode ser 0
  /// (libera tudo), igual a `ocorrencia.quantidadeAfetada` (reprova tudo)
  /// ou um valor no meio (libera parcial — só a parte reprovada debita o
  /// palete e vira refugo).
  Future<void> resolverOcorrencia({
    required OcorrenciaQualidade ocorrencia,
    required int quantidadeReprovada,
    required String usuarioId,
    required Palete palete,
    required String ordemProducaoId,
  }) async {
    final novoStatus = quantidadeReprovada > 0 ? 'reprovado' : 'liberado';

    await _client
        .from('ocorrencias_qualidade')
        .update({
          'status': novoStatus,
          'quantidade_reprovada': quantidadeReprovada,
        })
        .eq('id', ocorrencia.id);

    await _client.from('historico_ocorrencia').insert({
      'ocorrencia_id': ocorrencia.id,
      'usuario_id': usuarioId,
      'status_anterior': 'em_analise',
      'status_novo': novoStatus,
    });

    if (quantidadeReprovada > 0) {
      await _debitarESegregar(
        palete: palete,
        ordemProducaoId: ordemProducaoId,
        responsavelId: usuarioId,
        quantidade: quantidadeReprovada,
      );
    }
  }

  /// Qualidade reprova na hora, sem passar por análise. Registra no
  /// histórico igual a uma resolução normal, pra saber quem segregou.
  Future<void> segregarInteiro({
    required Palete palete,
    required String ordemProducaoId,
    required String usuarioId,
  }) async {
    final ocorrenciaCriada = await _client
        .from('ocorrencias_qualidade')
        .insert({
          'palete_id': palete.id,
          'quantidade_afetada': palete.saldoDisponivel,
          'quantidade_reprovada': palete.saldoDisponivel,
          'motivo': 'Segregação total pela Qualidade',
          'status': 'reprovado',
          'aberto_por': usuarioId,
        })
        .select('id')
        .single();

    await _client.from('historico_ocorrencia').insert({
      'ocorrencia_id': ocorrenciaCriada['id'],
      'usuario_id': usuarioId,
      'status_anterior': 'em_analise',
      'status_novo': 'reprovado',
    });

    await _debitarESegregar(
      palete: palete,
      ordemProducaoId: ordemProducaoId,
      responsavelId: usuarioId,
      quantidade: palete.saldoDisponivel,
    );
  }

  /// Apontador descarta o que ele mesmo produziu — vai direto pro refugo,
  /// sem passar pela Qualidade nem abrir ocorrência.
  Future<void> excluirTotalmente({
    required Palete palete,
    required String ordemProducaoId,
    required String responsavelId,
    required String motivoRefugo,
  }) {
    return _debitarESegregar(
      palete: palete,
      ordemProducaoId: ordemProducaoId,
      responsavelId: responsavelId,
      quantidade: palete.saldoDisponivel,
      motivoRefugo: motivoRefugo,
    );
  }

  Future<void> _debitarESegregar({
    required Palete palete,
    required String ordemProducaoId,
    required String responsavelId,
    required int quantidade,
    // 'Outro' cobre os débitos automáticos vindos da Qualidade — o motivo
    // "de verdade" já fica registrado na ocorrência; refugo lançado
    // manualmente pelo próprio setor (excluirTotalmente) informa o motivo.
    String motivoRefugo = 'Outro',
  }) async {
    await _client
        .from('paletes')
        .update({
          'quantidade_reprovada': palete.quantidadeReprovada + quantidade,
          'revisado_por': responsavelId,
        })
        .eq('id', palete.id);

    await _client.from('refugos').insert({
      'ordem_producao_id': ordemProducaoId,
      'responsavel_id': responsavelId,
      'quantidade': quantidade,
      'motivo': motivoRefugo,
    });
  }

  /// Corrige um erro de apontamento (altura errada pra Onduladeira, número
  /// de camadas errado pra Conversão) — recalcula quantidade_calculada com
  /// a mesma fórmula do setor que produziu o palete (ver
  /// PaletesRepository.registrarPalete).
  Future<void> corrigirApontamento({
    required Palete palete,
    required OrdemProducaoInfo ordem,
    double? novaAlturaMm,
    int? novasCamadas,
  }) {
    final int novaQuantidade;
    final Map<String, dynamic> alteracoes;
    if (palete.setorOrigem == 'conversao') {
      novaQuantidade =
          novasCamadas! * ordem.pacotesPorCamada! * ordem.pecasPorPacote!;
      alteracoes = {
        'camadas': novasCamadas,
        'quantidade_calculada': novaQuantidade,
      };
    } else {
      novaQuantidade =
          ((novaAlturaMm! / ordem.composicaoEspessuraMm) * ordem.qpPadrao)
              .floor();
      alteracoes = {
        'altura_medida_mm': novaAlturaMm,
        'quantidade_calculada': novaQuantidade,
      };
    }
    return _client.from('paletes').update(alteracoes).eq('id', palete.id);
  }
}

final qualidadeRepositoryProvider = Provider<QualidadeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return QualidadeRepository(client, db);
});
