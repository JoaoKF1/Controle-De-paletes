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

class OrdemDetalheConversaoView extends ConsumerWidget {
  final OrdemProducaoInfo ordem;

  const OrdemDetalheConversaoView({super.key, required this.ordem});

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
                final daOnduladeira =
                    paletes.where((p) => p.setorOrigem == 'onduladeira').toList();
                final daConversao = paletes.where((p) => p.setorOrigem == 'conversao').toList();
                Future<void> aoTocarPalete(Palete p) async {
                  await abrirAcoesPalete(context, ref, palete: p, ordem: ordem);
                  ref.invalidate(_paletesDaOrdemProvider(ordem.id));
                }

                // Chapas total: o que a Onduladeira já produziu pra essa OP,
                // líquido de qualquer reprovação de qualidade do lado dela.
                // Chapas disponíveis: esse total menos o que a Conversão já
                // consumiu apontando (1 caixa apontada = 1 chapa debitada —
                // ver plano técnico, 9.1).
                final chapasTotal = daOnduladeira.fold<int>(
                  0,
                  (soma, p) => soma + p.saldoDisponivel,
                );
                final chapasConsumidas = daConversao.fold<int>(
                  0,
                  (soma, p) => soma + p.quantidadeCalculada,
                );
                final chapasDisponiveis = chapasTotal - chapasConsumidas;

                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Chapas total: $chapasTotal · Chapas disponíveis: $chapasDisponiveis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: chapasDisponiveis < 0
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SecaoPaletes(
                      titulo: 'Produzido pela Onduladeira',
                      paletes: daOnduladeira,
                      onTapPalete: aoTocarPalete,
                    ),
                    const Divider(height: 24),
                    _SecaoPaletes(
                      titulo: 'Apontado pela Conversão',
                      paletes: daConversao,
                      onTapPalete: aoTocarPalete,
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
    if (ordem.pacotesPorCamada == null || ordem.pecasPorPacote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ficha Técnica sem dados de paletização (pacotes por camada, peças por '
            'pacote) — cadastre em Fichas Técnicas antes de apontar.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final camadasController = TextEditingController();
    String? erro;
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final camadas = int.tryParse(camadasController.text);
          final quantidadePrevista =
              camadas == null ? null : camadas * ordem.pacotesPorCamada! * ordem.pecasPorPacote!;

          return AlertDialog(
            title: const Text('Novo apontamento'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: camadasController,
                    decoration: const InputDecoration(labelText: 'Camadas de altura'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Informe um número maior que zero';
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
                                camadas: int.parse(camadasController.text),
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
  final void Function(Palete)? onTapPalete;

  const _SecaoPaletes({required this.titulo, required this.paletes, this.onTapPalete});

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
          ...paletes.map((p) {
            final medida = p.setorOrigem == 'conversao'
                ? 'Camadas ${p.camadas ?? '—'}'
                : 'Altura ${p.alturaMedidaMm?.toStringAsFixed(0) ?? '—'}mm';
            return ListTile(
              title: Text(
                'Palete ${p.numeroSequencial}'
                '${p.rotuloSegregacao != null ? ' · ${p.rotuloSegregacao}' : ''}',
                style: p.segregado
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              subtitle: Text(
                '$medida · Saldo ${p.saldoDisponivel}/${p.quantidadeCalculada}'
                '${p.revisorNome != null ? ' · revisado por ${p.revisorNome}' : ''}',
              ),
              trailing: Text(DateFormat('HH:mm').format(p.dataHora)),
              onTap: onTapPalete == null ? null : () => onTapPalete!(p),
            );
          }),
      ],
    );
  }
}
