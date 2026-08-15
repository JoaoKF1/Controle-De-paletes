import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/lancar_refugo_dialog.dart';
import '../../../shared/widgets/palete_acoes.dart';
import '../../auth/controller/auth_controller.dart';

final _paletesDaOrdemProvider = FutureProvider.autoDispose
    .family<List<Palete>, String>((ref, ordemId) {
  return ref.watch(paletesRepositoryProvider).listarPaletesDaOrdem(ordemId);
});

class OrdemDetalheView extends ConsumerWidget {
  final OrdemProducaoInfo ordem;

  const OrdemDetalheView({super.key, required this.ordem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletesAsync = ref.watch(_paletesDaOrdemProvider(ordem.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('OP ${ordem.numeroOp}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Lançar refugo',
            onPressed: () => abrirDialogoLancarRefugo(context, ref, ordemProducaoId: ordem.id),
          ),
        ],
      ),
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
                if (paletes.isEmpty) {
                  return const Center(child: Text('Nenhum palete apontado ainda.'));
                }
                return ListView.separated(
                  itemCount: paletes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = paletes[i];
                    return ListTile(
                      title: Text(
                        'Palete ${p.numeroSequencial}'
                        '${p.rotuloSegregacao != null ? ' · ${p.rotuloSegregacao}' : ''}',
                        style: p.segregado
                            ? TextStyle(color: Theme.of(context).colorScheme.error)
                            : null,
                      ),
                      subtitle: Text(
                        'Altura ${p.alturaMedidaMm?.toStringAsFixed(0) ?? '—'}mm · '
                        'Saldo ${p.saldoDisponivel}/${p.quantidadeCalculada} · ${p.tipoChapa}'
                        '${p.revisorNome != null ? ' · revisado por ${p.revisorNome}' : ''}',
                      ),
                      trailing: Text(DateFormat('HH:mm').format(p.dataHora)),
                      onTap: () async {
                        await abrirAcoesPalete(context, ref, palete: p, ordem: ordem);
                        ref.invalidate(_paletesDaOrdemProvider(ordem.id));
                      },
                    );
                  },
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tipo de chapa: ${ordem.tipoChapaOnduladeira}'),
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
                                setorOrigem: 'onduladeira',
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
