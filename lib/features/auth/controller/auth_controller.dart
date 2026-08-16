import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/usuario.dart';

enum AuthStatus { carregando, autenticado, naoAutenticado, erro }

class AuthControllerState {
  final AuthStatus status;
  final Usuario? usuario;
  final String? mensagemErro;

  const AuthControllerState({
    required this.status,
    this.usuario,
    this.mensagemErro,
  });

  const AuthControllerState.carregando() : this(status: AuthStatus.carregando);

  const AuthControllerState.naoAutenticado()
    : this(status: AuthStatus.naoAutenticado);

  const AuthControllerState.autenticado(Usuario usuario)
    : this(status: AuthStatus.autenticado, usuario: usuario);

  const AuthControllerState.erro(String mensagem)
    : this(status: AuthStatus.erro, mensagemErro: mensagem);
}

class AuthController extends Notifier<AuthControllerState> {
  @override
  AuthControllerState build() {
    // build() precisa retornar de forma síncrona. Usamos Future.microtask
    // para rodar _init() só DEPOIS que build() retornar — se chamássemos
    // _init() direto, a parte síncrona dela (quando não há sessão salva)
    // rodaria antes do build() terminar, e o "return carregando()" logo
    // abaixo sobrescreveria o estado certo que _init() acabou de definir.
    Future.microtask(_init);
    return const AuthControllerState.carregando();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _init() async {
    final sessao = _repository.sessaoAtual;
    if (sessao == null) {
      state = const AuthControllerState.naoAutenticado();
      return;
    }
    await _carregarPerfil(sessao.user.id);
  }

  Future<void> entrar({required String login, required String senha}) async {
    state = const AuthControllerState.carregando();
    try {
      await _repository.entrar(login: login, senha: senha);
      final sessao = _repository.sessaoAtual;
      if (sessao == null) {
        state = const AuthControllerState.erro('Não foi possível autenticar.');
        return;
      }
      await _carregarPerfil(sessao.user.id);
    } on AuthException catch (e) {
      state = AuthControllerState.erro(e.message);
    } catch (_) {
      state = const AuthControllerState.erro(
        'Erro inesperado. Tente novamente.',
      );
    }
  }

  Future<void> sair() async {
    await _repository.sair();
    state = const AuthControllerState.naoAutenticado();
  }

  Future<void> _carregarPerfil(String userId) async {
    try {
      final usuario = await _repository.buscarPerfil(userId);
      if (!usuario.ativo) {
        await _repository.sair();
        state = const AuthControllerState.erro(
          'Usuário inativo. Fale com o Admin.',
        );
        return;
      }
      state = AuthControllerState.autenticado(usuario);
    } catch (_) {
      state = const AuthControllerState.erro(
        'Login feito, mas não encontramos seu perfil cadastrado. Fale com o Admin.',
      );
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(AuthController.new);
