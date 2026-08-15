import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../auth/controller/auth_controller.dart';

final _paletesDaOrdemProvider = FutureProvider.autoDispose
    .family<List<Palete>, String>((ref, ordemId) {
  return ref.watch(paletesRepositoryProvider).listarPaletesDaOrdem(ordemId);
});

class OrdemDetalheConversaoView extends ConsumerWidget {
  final OrdemProducaoInfo ordem;

  const OrdemDetalheConversaoView({super.key, required this.ordem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletesAsync = ref.watch(_paletesDaOrdemProvider(ordem.id));

    return Scaffold(
      appBar: AppBar(title: Text('OP ${ordem.numeroOp}')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ordem.clienteNome, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('FT ${ordem.codigoFt} · Pedido: ${ordem.quantidadePedida}'),
                    Text('Status: ${ordem.status}'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: paletesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
              data: (paletes) {
                final daOnduladeira =
                    paletes.where((p) => p.setorOrigem == 'onduladeira').toList();
                final daConversao = paletes.where((p) => p.setorOrigem == 'conversao').toList();
                return ListView(
                  children: [
                    _SecaoPaletes(
                      titulo: 'Produzido pela Onduladeira',
                      paletes: daOnduladeira,
                    ),
                    const Divider(height: 24),
                    _SecaoPaletes(
                      titulo: 'Apontado pela Conversão',
                      paletes: daConversao,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ordem.status == 'aberta'
          ? FloatingActionButton(
              onPressed: () => _abrirFormularioApontamento(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _abrirFormularioApontamento(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final alturaController = TextEditingController();
    String? erro;
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final altura = double.tryParse(alturaController.text.replaceAll(',', '.'));
          final quantidadePrevista = altura == null
              ? null
              : ((altura / ordem.composicaoEspessuraMm) * ordem.qpPadrao).floor();

          return AlertDialog(
            title: const Text('Novo apontamento'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: alturaController,
                    decoration: const InputDecoration(labelText: 'Altura medida (mm)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final valor = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (valor == null || valor <= 0) return 'Informe um número válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tipo de chapa: elaborado'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    quantidadePrevista == null
                        ? 'Quantidade calculada: —'
                        : 'Quantidade calculada: $quantidadePrevista',
                    style: Theme.of(dialogContext).textTheme.titleMedium,
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      erro!,
                      style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: salvando
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => salvando = true);
                        final responsavelId = ref.read(authControllerProvider).usuario!.id;
                        try {
                          await ref
                              .read(paletesRepositoryProvider)
                              .registrarPalete(
                                ordem: ordem,
                                alturaMedidaMm: double.parse(
                                  alturaController.text.replaceAll(',', '.'),
                                ),
                                responsavelId: responsavelId,
                                setorOrigem: 'conversao',
                              );
                          ref.invalidate(_paletesDaOrdemProvider(ordem.id));
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setState(() {
                              salvando = false;
                              erro = e.toString();
                            });
                          }
                        }
                      },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SecaoPaletes extends StatelessWidget {
  final String titulo;
  final List<Palete> paletes;

  const _SecaoPaletes({required this.titulo, required this.paletes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (paletes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhum palete ainda.'),
          )
        else
          ...paletes.map(
            (p) => ListTile(
              title: Text('Palete ${p.numeroSequencial}'),
              subtitle: Text(
                'Altura ${p.alturaMedidaMm.toStringAsFixed(0)}mm · Qtd ${p.quantidadeCalculada}',
              ),
              trailing: Text(DateFormat('HH:mm').format(p.dataHora)),
            ),
          ),
      ],
    );
  }
}
