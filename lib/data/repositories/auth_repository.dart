import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/usuario.dart';
import '../remote/supabase_provider.dart';

/// Domínio técnico usado só internamente para transformar o "usuário" (login
/// curto, sem espaço) que a pessoa digita em um email válido pro Supabase
/// Auth — que exige email por baixo dos panos. Ninguém vê nem digita esse
/// email; ele nunca aparece em nenhuma tela.
const _dominioAuthInterno = 'controle-paletes.app';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Session? get sessaoAtual => _client.auth.currentSession;

  Future<void> entrar({required String login, required String senha}) {
    final email = _emailTecnico(login);
    // ignore: avoid_print
    print('[DEBUG] tentando login com email="$email" senha_length=${senha.length}');
    return _client.auth.signInWithPassword(email: email, password: senha);
  }

  Future<void> sair() {
    return _client.auth.signOut();
  }

  /// Busca o perfil do usuário logado na tabela `profiles`.
  Future<Usuario> buscarPerfil(String userId) async {
    final dados = await _client.from('profiles').select().eq('id', userId).single();
    return Usuario.fromMap(dados);
  }

  String _emailTecnico(String login) {
    final loginNormalizado = login.trim().toLowerCase();
    return '$loginNormalizado@$_dominioAuthInterno';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
