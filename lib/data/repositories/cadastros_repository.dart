import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/ficha_tecnica.dart';
import '../../domain/entities/ordem_producao.dart';
import '../local/app_database.dart';
import '../local/rede.dart';
import '../remote/supabase_provider.dart';

const _uuid = Uuid();

class SugestoesFichaTecnica {
  final List<String> clientes;
  final List<String> papeis;
  const SugestoesFichaTecnica({required this.clientes, required this.papeis});
}

/// Repositório único para os cadastros base (FT e OP) — todos são operações
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

  /// Sugestões pro formulário de FT: nomes de cliente e papéis já usados em
  /// outras FTs. Não existe cadastro próprio de Cliente/Papel (o ERP é a
  /// fonte) — sugerir o que já foi digitado evita "ACME" e "Acme Ltda"
  /// virarem clientes diferentes na busca.
  Future<SugestoesFichaTecnica> listarSugestoesFichaTecnica() async {
    final dados = await _client
        .from('fichas_tecnicas')
        .select('cliente_nome, papel_1, papel_2, papel_3, papel_4, papel_5');
    final clientes = <String>{};
    final papeis = <String>{};
    for (final f in dados as List) {
      clientes.add(f['cliente_nome'] as String);
      for (var i = 1; i <= 5; i++) {
        final papel = f['papel_$i'] as String?;
        if (papel != null) papeis.add(papel);
      }
    }
    return SugestoesFichaTecnica(
      clientes: clientes.toList()..sort(),
      papeis: papeis.toList()..sort(),
    );
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
    return _tentarOuEnfileirar('ordens_producao', {
      'status': 'concluida',
    }, idParaAtualizar: id);
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
        final atualizadas = await _client
            .from(tabela)
            .update(dados)
            .eq('id', idParaAtualizar)
            .select('id')
            .timeout(timeoutRede);
        // Update barrado pelo RLS não dá erro no PostgREST — só afeta 0
        // linhas. Sem essa checagem o app dizia "salvo" sem ter salvo nada
        // (era o que acontecia com "Encerrar produção" da Onduladeira).
        if ((atualizadas as List).isEmpty) {
          throw const PostgrestException(
            message: 'Nenhum registro alterado',
            code: '42501',
          );
        }
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
