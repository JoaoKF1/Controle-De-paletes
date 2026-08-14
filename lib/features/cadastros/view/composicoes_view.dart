import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../domain/entities/composicao.dart';

final _composicoesProvider = FutureProvider.autoDispose<List<Composicao>>((ref) {
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
            return const Center(child: Text('Nenhuma composição cadastrada ainda.'));
          }
          return ListView.separated(
            itemCount: composicoes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = composicoes[i];
              return ListTile(
                title: Text(c.codigo),
                subtitle: Text('Espessura: ${c.espessuraMm} mm'),
              );
            },
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
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código (ex: T140M130T140/B)',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: espessuraController,
                decoration: const InputDecoration(labelText: 'Espessura (mm)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final valor = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (valor == null || valor <= 0) return 'Informe um valor maior que zero';
                  return null;
                },
              ),
            ],
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
                espessuraMm: double.parse(espessuraController.text.replaceAll(',', '.')),
              );
              await ref.read(cadastrosRepositoryProvider).criarComposicao(composicao);
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
