import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/auth_controller.dart';

/// Tela temporária pós-login. Cada perfil vai ganhar sua própria tela
/// inicial (Onduladeira: Ordens em aberto, Conversão: Ordens disponíveis,
/// etc.) nos próximos sprints — isso aqui só confirma que a autenticação
/// está funcionando de ponta a ponta.
class HomePlaceholderView extends ConsumerWidget {
  const HomePlaceholderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario?.nome ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Logado como "${usuario?.perfil ?? ''}".\n'
          'As telas de cada setor entram nos próximos sprints.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
