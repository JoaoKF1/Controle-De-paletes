import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../domain/entities/cliente.dart';
import '../../../domain/entities/composicao.dart';
import '../../../domain/entities/ficha_tecnica.dart';

final _fichasProvider = FutureProvider.autoDispose<List<FichaTecnica>>((ref) {
  return ref.watch(cadastrosRepositoryProvider).listarFichasTecnicas();
});

final _clientesParaFormProvider = FutureProvider.autoDispose<List<Cliente>>((
  ref,
) {
  return ref.watch(cadastrosRepositoryProvider).listarClientes();
});

final _composicoesParaFormProvider =
    FutureProvider.autoDispose<List<Composicao>>((ref) {
      return ref.watch(cadastrosRepositoryProvider).listarComposicoes();
    });

class FichasTecnicasView extends ConsumerWidget {
  const FichasTecnicasView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fichasAsync = ref.watch(_fichasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fichas Técnicas')),
      body: fichasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (fichas) {
          if (fichas.isEmpty) {
            return const Center(
              child: Text('Nenhuma ficha técnica cadastrada ainda.'),
            );
          }
          return ListView.separated(
            itemCount: fichas.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = fichas[i];
              return ListTile(
                title: Text(f.codigoFt),
                subtitle: Text('${f.medidaChapa} · QP padrão: ${f.qpPadrao}'),
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
    final clientes = await ref.read(_clientesParaFormProvider.future);
    final composicoes = await ref.read(_composicoesParaFormProvider.future);

    if (!context.mounted) return;

    if (clientes.isEmpty || composicoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre pelo menos 1 Cliente e 1 Composição antes de criar uma FT.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final medidaController = TextEditingController();
    final qpController = TextEditingController();
    final referenciaController = TextEditingController();
    String? clienteIdSelecionado = clientes.first.id;
    String? composicaoIdSelecionada = composicoes.first.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Nova Ficha Técnica'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codigoController,
                    decoration: const InputDecoration(labelText: 'Código FT'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: clienteIdSelecionado,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: clientes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.razaoSocial),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => clienteIdSelecionado = v),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: composicaoIdSelecionada,
                    decoration: const InputDecoration(labelText: 'Composição'),
                    items: composicoes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.codigo),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => composicaoIdSelecionada = v),
                  ),
                  TextFormField(
                    controller: medidaController,
                    decoration: const InputDecoration(
                      labelText: 'Medida da chapa (ex: 733 x 1.964)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  TextFormField(
                    controller: qpController,
                    decoration: const InputDecoration(
                      labelText: 'QP padrão (nº de pilhas)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) {
                        return 'Informe um número maior que zero';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: referenciaController,
                    decoration: const InputDecoration(
                      labelText: 'Referência (opcional)',
                    ),
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
                final ficha = FichaTecnica(
                  id: '',
                  codigoFt: codigoController.text.trim(),
                  clienteId: clienteIdSelecionado!,
                  composicaoId: composicaoIdSelecionada!,
                  medidaChapa: medidaController.text.trim(),
                  qpPadrao: int.parse(qpController.text),
                  referencia: referenciaController.text.trim().isEmpty
                      ? null
                      : referenciaController.text.trim(),
                  ativo: true,
                );
                await ref
                    .read(cadastrosRepositoryProvider)
                    .criarFichaTecnica(ficha);
                ref.invalidate(_fichasProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
