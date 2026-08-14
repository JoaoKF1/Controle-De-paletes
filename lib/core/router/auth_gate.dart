import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controller/auth_controller.dart';
import '../../features/auth/view/home_placeholder_view.dart';
import '../../features/auth/view/login_view.dart';

/// Ponto de entrada do app depois do login: mostra loading, tela de login,
/// ou a home — conforme o estado atual de autenticação.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authControllerProvider).status;

    switch (status) {
      case AuthStatus.autenticado:
        return const HomePlaceholderView();
      case AuthStatus.carregando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.naoAutenticado:
      case AuthStatus.erro:
        return const LoginView();
    }
  }
}
