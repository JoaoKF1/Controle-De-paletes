import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/utils/mensagem_erro.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/push_notifications_service.dart';
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
    } catch (e) {
      // Sem conexão, o Supabase Auth devolve um AuthException com a falha
      // de rede no texto — mensagemErro() trata isso antes de cair na
      // mensagem crua do Auth (que vem em inglês).
      state = AuthControllerState.erro(mensagemErro(e));
    }
  }

  Future<void> sair() async {
    final usuario = state.usuario;
    if (usuario != null) {
      // Aparelho deixa de receber push desse usuário depois do logout.
      await ref.read(pushNotificationsServiceProvider).remover(usuario.id);
    }
    try {
      await _repository.sair();
    } catch (_) {
      // Sem conexão o signOut remoto falha, mas a sessão local já é
      // apagada — o usuário sai do mesmo jeito.
    }
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
      // Fire-and-forget: registra o token de push desse aparelho (só faz
      // algo de verdade no Android — ver PushNotificationsService). Nunca
      // deve travar nem falhar o login.
      unawaited(
        ref.read(pushNotificationsServiceProvider).registrar(usuario.id),
      );
    } on PostgrestException catch (e) {
      // PGRST116 = `.single()` não achou nenhuma linha: o usuário existe no
      // Auth mas não tem perfil em `profiles`. Qualquer outro código é
      // problema do servidor, não de cadastro — não esconde a causa.
      state = AuthControllerState.erro(
        e.code == 'PGRST116'
            ? 'Login feito, mas não encontramos seu perfil cadastrado. '
                  'Fale com o Admin.'
            : mensagemErro(e),
      );
    } catch (e) {
      state = AuthControllerState.erro(mensagemErro(e));
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(AuthController.new);
