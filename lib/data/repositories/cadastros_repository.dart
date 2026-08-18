import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/entities/composicao.dart';
import '../../domain/entities/ficha_tecnica.dart';
import '../../domain/entities/ordem_producao.dart';
import '../local/app_database.dart';
import '../local/rede.dart';
import '../remote/supabase_provider.dart';

const _uuid = Uuid();

/// Repositório único para os 4 cadastros base — todos são operações
/// simples de listar/criar, então não compensa um arquivo por entidade
/// ainda. Se um cadastro ganhar regras próprias complexas, separa depois.
///
/// Escrita entra na fila offline (Fase 2 do modo offline, ver plano
/// técnico 9.12) se a rede falhar — o dado não se perde, mas as listas
/// aqui não mostram o item como "pendente" (diferente de paletes, que tem
/// cache próprio): a confirmação visual de que ainda não sincronizou fica
/// só na tela de Pendências.
class CadastrosRepository {
  final SupabaseClient _client;
  final AppDatabase _db;
  CadastrosRepository(this._client, this._db);

  Future<List<Cliente>> listarClientes() async {
    final dados = await _client.from('clientes').select().order('razao_social');
    return (dados as List).map((e) => Cliente.fromMap(e)).toList();
  }

  Future<void> criarCliente(Cliente cliente) {
    return _tentarOuEnfileirar('clientes', cliente.toInsertMap());
  }

  Future<List<Composicao>> listarComposicoes() async {
    final dados = await _client.from('composicoes').select().order('codigo');
    return (dados as List).map((e) => Composicao.fromMap(e)).toList();
  }

  Future<void> criarComposicao(Composicao composicao) {
    return _tentarOuEnfileirar('composicoes', composicao.toInsertMap());
  }

  Future<List<FichaTecnica>> listarFichasTecnicas() async {
    final dados = await _client
        .from('fichas_tecnicas')
        .select()
        .order('codigo_ft');
    return (dados as List).map((e) => FichaTecnica.fromMap(e)).toList();
  }

  Future<void> criarFichaTecnica(FichaTecnica ficha) {
    return _tentarOuEnfileirar('fichas_tecnicas', ficha.toInsertMap());
  }

  Future<void> atualizarFichaTecnica(FichaTecnica ficha) {
    return _tentarOuEnfileirar(
      'fichas_tecnicas',
      ficha.toInsertMap(),
      idParaAtualizar: ficha.id,
    );
  }

  Future<FichaTecnica> buscarFichaTecnicaPorId(String id) async {
    final dados = await _client
        .from('fichas_tecnicas')
        .select()
        .eq('id', id)
        .single();
    return FichaTecnica.fromMap(dados);
  }

  Future<List<OrdemProducao>> listarOrdensProducao() async {
    final dados = await _client
        .from('ordens_producao')
        .select()
        .order('data_pedido', ascending: false);
    return (dados as List).map((e) => OrdemProducao.fromMap(e)).toList();
  }

  Future<void> criarOrdemProducao(OrdemProducao op) {
    return _tentarOuEnfileirar('ordens_producao', op.toInsertMap());
  }

  /// Encerra a produção de uma OP — ação explícita da Onduladeira (nunca
  /// automática por bater a quantidade pedida, ver plano técnico 9.1),
  /// depois disso ela some das listas de "abertas" e não recebe mais
  /// apontamento novo. Continua normalmente disponível pra teste de
  /// qualidade (ver 9.6) — testar depois de fechada é o caso comum.
  Future<void> encerrarOrdemProducao(String id) {
    return _tentarOuEnfileirar(
      'ordens_producao',
      {'status': 'concluida'},
      idParaAtualizar: id,
    );
  }

  /// `idParaAtualizar` null = insert; preenchido = update daquele id.
  Future<void> _tentarOuEnfileirar(
    String tabela,
    Map<String, dynamic> dados, {
    String? idParaAtualizar,
  }) async {
    try {
      if (idParaAtualizar == null) {
        await _client.from(tabela).insert(dados).timeout(timeoutRede);
      } else {
        await _client
            .from(tabela)
            .update(dados)
            .eq('id', idParaAtualizar)
            .timeout(timeoutRede);
      }
    } catch (e) {
      if (!falhaDeRede(e)) rethrow;
      await _db.inserirOperacaoPendenteMap(
        id: _uuid.v4(),
        tipo: idParaAtualizar == null
            ? '${tabela}_criar'
            : '${tabela}_atualizar',
        dados: idParaAtualizar == null
            ? dados
            : {...dados, 'id': idParaAtualizar},
      );
    }
  }
}

final cadastrosRepositoryProvider = Provider<CadastrosRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return CadastrosRepository(client, db);
});
