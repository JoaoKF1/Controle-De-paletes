import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/ocorrencia_qualidade.dart';
import '../../domain/entities/palete.dart';
import '../local/app_database.dart';
import '../local/rede.dart';
import '../remote/supabase_provider.dart';

const _selectOcorrenciaComJoins = '*, paletes(numero_sequencial, ordens_producao(numero_op))';
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
      await _db.inserirOperacaoPendenteMap(id: _uuid.v4(), tipo: 'refugo', dados: dados);
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
      await _client.from('ocorrencias_qualidade').insert(dados).timeout(timeoutRede);
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      await _db.inserirOperacaoPendenteMap(id: _uuid.v4(), tipo: 'ocorrencia_abrir', dados: dados);
    }
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
        .update({'status': novoStatus, 'quantidade_reprovada': quantidadeReprovada})
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
      novaQuantidade = novasCamadas! * ordem.pacotesPorCamada! * ordem.pecasPorPacote!;
      alteracoes = {'camadas': novasCamadas, 'quantidade_calculada': novaQuantidade};
    } else {
      novaQuantidade = ((novaAlturaMm! / ordem.composicaoEspessuraMm) * ordem.qpPadrao).floor();
      alteracoes = {'altura_medida_mm': novaAlturaMm, 'quantidade_calculada': novaQuantidade};
    }
    return _client.from('paletes').update(alteracoes).eq('id', palete.id);
  }
}

final qualidadeRepositoryProvider = Provider<QualidadeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return QualidadeRepository(client, db);
});
