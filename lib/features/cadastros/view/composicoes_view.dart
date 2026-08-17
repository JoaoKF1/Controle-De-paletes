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
    final espessuraController = TextEditingController();
    var tipoOndaSelecionado = tiposOnda.first;
    var papeisSelecionados = List.generate(
      Composicao.quantidadePapeis(tipoOndaSelecionado),
      (_) => papeisDisponiveis.first,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final codigoGerado = Composicao.gerarCodigo(
            tipoOnda: tipoOndaSelecionado,
            papeis: papeisSelecionados,
          );

          return AlertDialog(
            title: const Text('Nova composição'),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownRotulado(
                        rotulo: 'Tipo de onda',
                        valor: tipoOndaSelecionado,
                        itens: tiposOnda
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          tipoOndaSelecionado = v!;
                          final quantidade = Composicao.quantidadePapeis(v);
                          papeisSelecionados = List.generate(
                            quantidade,
                            (i) => i < papeisSelecionados.length
                                ? papeisSelecionados[i]
                                : papeisDisponiveis.first,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < papeisSelecionados.length; i++) ...[
                        DropdownRotulado(
                          rotulo: 'Papel ${i + 1}',
                          valor: papeisSelecionados[i],
                          itens: papeisDisponiveis
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => papeisSelecionados[i] = v!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      CampoRotulado(
                        rotulo: 'Espessura (mm)',
                        controller: espessuraController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: validarNumeroPositivo,
                      ),
                      const SizedBox(height: 16),
                      CartaoResultado(rotulo: 'Código', valor: codigoGerado),
                    ],
                  ),
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
                    codigo: codigoGerado,
                    espessuraMm: double.parse(
                      espessuraController.text.replaceAll(',', '.'),
                    ),
                    tipoOnda: tipoOndaSelecionado,
                    papeis: papeisSelecionados,
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
          );
        },
      ),
    );
  }
}
