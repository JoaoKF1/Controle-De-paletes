import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../domain/entities/cliente.dart';

final _clientesProvider = FutureProvider.autoDispose<List<Cliente>>((ref) {
  return ref.watch(cadastrosRepositoryProvider).listarClientes();
});

class ClientesView extends ConsumerWidget {
  const ClientesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(_clientesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: clientesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (clientes) {
          if (clientes.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado ainda.'));
          }
          return ListView.separated(
            itemCount: clientes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = clientes[i];
              return ListTile(
                title: Text(c.razaoSocial),
                subtitle: Text('${c.cidade} - ${c.uf}'),
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
    final razaoSocialController = TextEditingController();
    final cidadeController = TextEditingController();
    final ufController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo cliente'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: razaoSocialController,
                decoration: const InputDecoration(labelText: 'Razão social'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: ufController,
                decoration: const InputDecoration(labelText: 'UF'),
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
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
              final cliente = Cliente(
                id: '',
                razaoSocial: razaoSocialController.text.trim(),
                cidade: cidadeController.text.trim(),
                uf: ufController.text.trim().toUpperCase(),
                ativo: true,
              );
              await ref.read(cadastrosRepositoryProvider).criarCliente(cliente);
              ref.invalidate(_clientesProvider);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
