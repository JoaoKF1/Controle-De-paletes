import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/sync_trigger.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/auth/view/login_view.dart';
import '../../features/home/view/home_view.dart';

/// Ponto de entrada do app depois do login: mostra loading, tela de login,
/// ou a tela inicial — a mesma pra todos os perfis; o que muda por perfil
/// são os botões visíveis nela (ver `Permissoes`, plano técnico 2).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    switch (authState.status) {
      case AuthStatus.autenticado:
        ref.watch(syncTriggerProvider);
        return const HomeView();
      case AuthStatus.carregando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.naoAutenticado:
      case AuthStatus.erro:
        return const LoginView();
    }
  }
}
