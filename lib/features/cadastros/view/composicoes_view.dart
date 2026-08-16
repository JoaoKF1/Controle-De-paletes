import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../domain/entities/composicao.dart';
import '../../../shared/widgets/apontamento_kit.dart';

final _composicoesProvider = FutureProvider.autoDispose<List<Composicao>>((
  ref,
) {
  return ref.watch(cadastrosRepositoryProvider).listarComposicoes();
});

class ComposicoesView extends ConsumerWidget {
  const ComposicoesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composicoesAsync = ref.watch(_composicoesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Composições')),
      body: composicoesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (composicoes) {
          if (composicoes.isEmpty) {
            return const Center(
              child: Text('Nenhuma composição cadastrada ainda.'),
            );
          }
          return LarguraFormulario(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: composicoes.length,
              itemBuilder: (context, i) {
                final c = composicoes[i];
                return CartaoLista(
                  title: Text(c.codigo),
                  subtitle: Text('Espessura: ${c.espessuraMm} mm'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final espessuraController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova composição'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                CampoRotulado(
                  rotulo: 'Código',
                  controller: codigoController,
                  hint: 'Ex: T140M130T140/B',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                CampoRotulado(
                  rotulo: 'Espessura (mm)',
                  controller: espessuraController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: validarNumeroPositivo,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final composicao = Composicao(
                id: '',
                codigo: codigoController.text.trim(),
                espessuraMm: double.parse(
                  espessuraController.text.replaceAll(',', '.'),
                ),
              );
              await ref
                  .read(cadastrosRepositoryProvider)
                  .criarComposicao(composicao);
              ref.invalidate(_composicoesProvider);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
