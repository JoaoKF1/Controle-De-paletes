import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/palete.dart';
import '../remote/supabase_provider.dart';

const _selectComJoins =
    '*, fichas_tecnicas(codigo_ft, qp_padrao, clientes(razao_social), composicoes(espessura_mm))';
const _selectComJoinsFiltradoPorFt =
    '*, fichas_tecnicas!inner(codigo_ft, qp_padrao, clientes(razao_social), composicoes(espessura_mm))';

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

  Future<List<Palete>> listarPaletesDaOrdem(String ordemProducaoId) async {
    final dados = await _client
        .from('paletes')
        .select()
        .eq('ordem_producao_id', ordemProducaoId)
        .order('numero_sequencial');
    return (dados as List).map((e) => Palete.fromMap(e)).toList();
  }

  /// quantidade_calculada = (altura ÷ espessura da composição) × qp_padrão
  /// da FT, arredondado pra baixo — só conta chapa inteira. numero_sequencial
  /// é o próximo da OP; se dois apontamentos colidirem nesse número, o
  /// unique constraint do banco rejeita e o app mostra o erro (fluxo de um
  /// operador por vez, então a colisão é rara).
  Future<void> registrarPalete({
    required OrdemProducaoInfo ordem,
    required double alturaMedidaMm,
    required String tipoChapa,
    required String responsavelId,
  }) async {
    final quantidadeCalculada =
        ((alturaMedidaMm / ordem.composicaoEspessuraMm) * ordem.qpPadrao).floor();

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
      'quantidade_calculada': quantidadeCalculada,
      'tipo_chapa': tipoChapa,
      'setor_origem': 'onduladeira',
      'responsavel_id': responsavelId,
    });
  }
}

final paletesRepositoryProvider = Provider<PaletesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PaletesRepository(client);
});
