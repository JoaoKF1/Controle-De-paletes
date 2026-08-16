import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/apontamento_kit.dart';
import '../../apontamento/view/ordens_abertas_view.dart';
import '../../auth/controller/auth_controller.dart';
import '../../conversao/view/ordens_disponiveis_view.dart';
import '../../dashboard/view/dashboard_view.dart';
import '../../qualidade/view/fila_analise_view.dart';
import '../../sincronizacao/view/pendencias_view.dart';
import 'clientes_view.dart';
import 'composicoes_view.dart';
import 'fichas_tecnicas_view.dart';
import 'ordens_producao_view.dart';
import 'usuarios_view.dart';

const _rotulosPerfil = {
  'admin': 'Administrador',
  'onduladeira': 'Onduladeira',
  'conversao': 'Conversão',
  'qualidade': 'Qualidade',
};

String _iniciais(String nome) {
  final partes = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
      .toUpperCase();
}

class CadastrosHomeView extends ConsumerWidget {
  const CadastrosHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LarguraFormulario(
          maxWidth: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        _iniciais(usuario?.nome ?? '?'),
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario?.nome ?? '',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _rotulosPerfil[usuario?.perfil] ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).sair(),
                      icon: const Icon(Icons.logout),
                      tooltip: 'Sair',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    RotuloSecaoMaiuscula('CADASTROS'),
                    _GradeMenu(
                      itens: [
                        _ItemMenu(
                          icone: Icons.business,
                          titulo: 'Clientes',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ClientesView(),
                            ),
                          ),
                        ),
                        _ItemMenu(
                          icone: Icons.layers,
                          titulo: 'Composições',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ComposicoesView(),
                            ),
                          ),
                        ),
                        _ItemMenu(
                          icone: Icons.description,
                          titulo: 'Fichas técnicas',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FichasTecnicasView(),
                            ),
                          ),
                        ),
                        _ItemMenu(
                          icone: Icons.assignment,
                          titulo: 'Ordens de produção',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrdensProducaoView(),
                            ),
                          ),
                        ),
                        _ItemMenu(
                          icone: Icons.people,
                          titulo: 'Usuários',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UsuariosView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    RotuloSecaoMaiuscula('OPERACIONAL'),
                    _GradeMenu(
                      itens: [
                        _ItemMenu(
                          icone: Icons.layers_outlined,
                          titulo: 'Ordens em aberto',
                          distintivo: 'Onduladeira',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrdensAbertasView(),
                            ),
                          ),
                        ),
                        _ItemMenu(
                          icone: Icons.print_outlined,
                          titulo: 'Ordens disponíveis',
                          distintivo: 'Conversão',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrdensDisponiveisView(),
                            ),
                          ),
                        ),
                        _ItemMenu(
                          icone: Icons.shield_outlined,
                          titulo: 'Fila de análise',
                          distintivo: 'Qualidade',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FilaAnaliseView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    RotuloSecaoMaiuscula('GESTÃO'),
                    _GradeMenu(
                      itens: [
                        _ItemMenu(
                          icone: Icons.bar_chart,
                          titulo: 'Dashboard',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DashboardView(),
                            ),
                          ),
                        ),
                        _ItemMenu(
                          icone: Icons.sync,
                          titulo: 'Sincronização',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PendenciasView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Distribui os cartões em linhas de largura igual, com o número de
/// colunas calculado a partir do espaço disponível — 2 no celular, 3+ em
/// telas largas (desktop), sem precisar de breakpoints fixos.
class _GradeMenu extends StatelessWidget {
  final List<_ItemMenu> itens;
  const _GradeMenu({required this.itens});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = (constraints.maxWidth / 220).floor().clamp(1, 4);
        final linhas = <Widget>[];
        for (var i = 0; i < itens.length; i += colunas) {
          final fatia = itens.skip(i).take(colunas).toList();
          linhas.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < colunas; c++) ...[
                      if (c > 0) const SizedBox(width: 12),
                      Expanded(
                        child: c < fatia.length ? fatia[c] : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return Column(children: linhas);
      },
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? distintivo;
  final VoidCallback onTap;

  const _ItemMenu({
    required this.icone,
    required this.titulo,
    this.distintivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icone, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              if (distintivo != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    distintivo!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
