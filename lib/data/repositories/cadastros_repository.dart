import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/entities/composicao.dart';
import '../../domain/entities/ficha_tecnica.dart';
import '../../domain/entities/ordem_producao.dart';
import '../remote/supabase_provider.dart';

/// Repositório único para os 4 cadastros base — todos são operações
/// simples de listar/criar, então não compensa um arquivo por entidade
/// ainda. Se um cadastro ganhar regras próprias complexas, separa depois.
class CadastrosRepository {
  final SupabaseClient _client;
  CadastrosRepository(this._client);

  Future<List<Cliente>> listarClientes() async {
    final dados = await _client.from('clientes').select().order('razao_social');
    return (dados as List).map((e) => Cliente.fromMap(e)).toList();
  }

  Future<void> criarCliente(Cliente cliente) {
    return _client.from('clientes').insert(cliente.toInsertMap());
  }

  Future<List<Composicao>> listarComposicoes() async {
    final dados = await _client.from('composicoes').select().order('codigo');
    return (dados as List).map((e) => Composicao.fromMap(e)).toList();
  }

  Future<void> criarComposicao(Composicao composicao) {
    return _client.from('composicoes').insert(composicao.toInsertMap());
  }

  Future<List<FichaTecnica>> listarFichasTecnicas() async {
    final dados = await _client.from('fichas_tecnicas').select().order('codigo_ft');
    return (dados as List).map((e) => FichaTecnica.fromMap(e)).toList();
  }

  Future<void> criarFichaTecnica(FichaTecnica ficha) {
    return _client.from('fichas_tecnicas').insert(ficha.toInsertMap());
  }

  Future<List<OrdemProducao>> listarOrdensProducao() async {
    final dados = await _client
        .from('ordens_producao')
        .select()
        .order('data_pedido', ascending: false);
    return (dados as List).map((e) => OrdemProducao.fromMap(e)).toList();
  }

  Future<void> criarOrdemProducao(OrdemProducao op) {
    return _client.from('ordens_producao').insert(op.toInsertMap());
  }
}

final cadastrosRepositoryProvider = Provider<CadastrosRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CadastrosRepository(client);
});
