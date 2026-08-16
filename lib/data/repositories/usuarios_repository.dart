import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/usuario.dart';
import '../remote/supabase_provider.dart';

/// Criar usuário e trocar senha exigem privilégio de admin do Supabase Auth
/// (service_role), que não pode viver no app — por isso essas duas ações
/// passam pela Edge Function `admin-usuarios`. Editar nome/perfil e
/// desativar são só update em `profiles`, coberto pela RLS de admin.
class UsuariosRepository {
  final SupabaseClient _client;
  UsuariosRepository(this._client);

  Future<List<Usuario>> listarUsuarios() async {
    final dados = await _client.from('profiles').select().order('nome');
    return (dados as List).map((e) => Usuario.fromMap(e)).toList();
  }

  Future<void> criarUsuario({
    required String login,
    required String senha,
    required String nome,
    required String perfil,
  }) async {
    final res = await _client.functions.invoke(
      'admin-usuarios',
      body: {
        'acao': 'criar',
        'login': login,
        'senha': senha,
        'nome': nome,
        'perfil': perfil,
      },
    );
    if (res.status != 200) {
      throw Exception(res.data?['erro'] ?? 'Falha ao criar usuário');
    }
  }

  Future<void> trocarSenha({
    required String userId,
    required String novaSenha,
  }) async {
    final res = await _client.functions.invoke(
      'admin-usuarios',
      body: {'acao': 'trocar_senha', 'user_id': userId, 'senha': novaSenha},
    );
    if (res.status != 200) {
      throw Exception(res.data?['erro'] ?? 'Falha ao trocar senha');
    }
  }

  Future<void> atualizarPerfil({
    required String userId,
    required String nome,
    required String perfil,
  }) {
    return _client
        .from('profiles')
        .update({'nome': nome, 'perfil': perfil})
        .eq('id', userId);
  }

  Future<void> definirAtivo({required String userId, required bool ativo}) {
    return _client.from('profiles').update({'ativo': ativo}).eq('id', userId);
  }
}

final usuariosRepositoryProvider = Provider<UsuariosRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UsuariosRepository(client);
});
