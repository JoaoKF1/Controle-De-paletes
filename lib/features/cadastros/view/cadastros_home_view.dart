import 'package:flutter/material.dart';

import '../../auth/controller/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../apontamento/view/ordens_abertas_view.dart';
import '../../conversao/view/ordens_disponiveis_view.dart';
import '../../dashboard/view/dashboard_view.dart';
import '../../qualidade/view/fila_analise_view.dart';
import 'clientes_view.dart';
import 'composicoes_view.dart';
import 'fichas_tecnicas_view.dart';
import 'ordens_producao_view.dart';
import 'usuarios_view.dart';

class CadastrosHomeView extends ConsumerWidget {
  const CadastrosHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario?.nome ?? 'Cadastros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CadastroTile(
            icone: Icons.business,
            titulo: 'Clientes',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClientesView()),
            ),
          ),
          _CadastroTile(
            icone: Icons.layers,
            titulo: 'Composições (tipos de onda)',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ComposicoesView()),
            ),
          ),
          _CadastroTile(
            icone: Icons.description,
            titulo: 'Fichas Técnicas',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FichasTecnicasView()),
            ),
          ),
          _CadastroTile(
            icone: Icons.assignment,
            titulo: 'Ordens de Produção',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdensProducaoView()),
            ),
          ),
          _CadastroTile(
            icone: Icons.people,
            titulo: 'Usuários',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UsuariosView()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _CadastroTile(
            icone: Icons.factory,
            titulo: 'Ordens em aberto (Onduladeira)',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdensAbertasView()),
            ),
          ),
          _CadastroTile(
            icone: Icons.print,
            titulo: 'Ordens disponíveis (Conversão)',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdensDisponiveisView()),
            ),
          ),
          _CadastroTile(
            icone: Icons.fact_check_outlined,
            titulo: 'Fila de análise (Qualidade)',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FilaAnaliseView()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _CadastroTile(
            icone: Icons.bar_chart,
            titulo: 'Dashboard',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardView()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CadastroTile extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  const _CadastroTile({
    required this.icone,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icone),
        title: Text(titulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
