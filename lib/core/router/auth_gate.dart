import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/apontamento/view/ordens_abertas_view.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/auth/view/home_placeholder_view.dart';
import '../../features/auth/view/login_view.dart';
import '../../features/cadastros/view/cadastros_home_view.dart';

/// Ponto de entrada do app depois do login: mostra loading, tela de login,
/// ou a home certa conforme o perfil — admin vai para os cadastros,
/// Onduladeira vai para as ordens em aberto; Conversão e Qualidade seguem
/// na tela temporária até seus sprints específicos.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    switch (authState.status) {
      case AuthStatus.autenticado:
        switch (authState.usuario?.perfil) {
          case 'admin':
            return const CadastrosHomeView();
          case 'onduladeira':
            return const OrdensAbertasView();
          default:
            return const HomePlaceholderView();
        }
      case AuthStatus.carregando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.naoAutenticado:
      case AuthStatus.erro:
        return const LoginView();
    }
  }
}
