import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/qualidade_repository.dart';
import '../../../domain/entities/teste_qualidade.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import 'testes_qualidade_ordem_view.dart';

final _ordensParaTesteProvider = FutureProvider.autoDispose<List<OrdemParaTeste>>((
  ref,
) {
  return ref.watch(qualidadeRepositoryProvider).listarOrdensParaTeste();
});

/// Ponto de entrada dos testes de qualidade: em vez de listar testes direto,
/// lista as OPs (igual ao resto do app, que é sempre OP-cêntrico —
/// Apontamento, Consulta) separadas em Abertas/Fechadas. O teste em si só
/// aparece depois de entrar numa OP específica (ver `TestesQualidadeOrdemView`).
class TestesQualidadeView extends ConsumerStatefulWidget {
  const TestesQualidadeView({super.key});

  @override
  ConsumerState<TestesQualidadeView> createState() =>
      _TestesQualidadeViewState();
}

class _TestesQualidadeViewState extends ConsumerState<TestesQualidadeView> {
  final _buscaController = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordensAsync = ref.watch(_ordensParaTesteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Testes de qualidade')),
      body: LarguraFormulario(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _buscaController,
                decoration: InputDecoration(
                  hintText: 'Buscar OP',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _filtro = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ordensAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (erro, _) =>
                      Center(child: Text('Erro ao carregar: $erro')),
                  data: (ordens) {
                    final filtradas = _filtro.isEmpty
                        ? ordens
                        : ordens
                              .where(
                                (o) =>
                                    o.numeroOp.toLowerCase().contains(_filtro) ||
                                    o.clienteNome.toLowerCase().contains(
                                      _filtro,
                                    ),
                              )
                              .toList();
                    final abertas = filtradas
                        .where((o) => o.status == 'aberta')
                        .toList();
                    final fechadas = filtradas
                        .where((o) => o.status != 'aberta')
                        .toList();
                    if (filtradas.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma OP encontrada.'),
                      );
                    }
                    return ListView(
                      children: [
                        if (abertas.isNotEmpty) ...[
                          const RotuloSecaoMaiuscula('Abertas'),
                          for (final o in abertas) _CartaoOrdem(ordem: o),
                          const SizedBox(height: 16),
                        ],
                        if (fechadas.isNotEmpty) ...[
                          const RotuloSecaoMaiuscula('Fechadas'),
                          for (final o in fechadas) _CartaoOrdem(ordem: o),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoOrdem extends StatelessWidget {
  final OrdemParaTeste ordem;
  const _CartaoOrdem({required this.ordem});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CartaoLista(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
        child: Icon(Icons.science_outlined, color: colorScheme.primary, size: 20),
      ),
      title: Text(ordem.numeroOp),
      subtitle: Text(
        '${ordem.unidadePedido} · '
        '${ordem.totalTestes == 0 ? 'nenhum teste' : '${ordem.totalTestes} '
              'teste${ordem.totalTestes == 1 ? '' : 's'}'}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TestesQualidadeOrdemView(ordem: ordem),
        ),
      ),
    );
  }
}
