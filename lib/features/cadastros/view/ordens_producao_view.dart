import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../domain/entities/ficha_tecnica.dart';
import '../../../domain/entities/ordem_producao.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../apontamento/view/busca_op_view.dart';

final _opsProvider = FutureProvider.autoDispose<List<OrdemProducao>>((ref) {
  return ref.watch(cadastrosRepositoryProvider).listarOrdensProducao();
});

final _fichasParaFormProvider = FutureProvider.autoDispose<List<FichaTecnica>>((
  ref,
) {
  return ref.watch(cadastrosRepositoryProvider).listarFichasTecnicas();
});

class OrdensProducaoView extends ConsumerWidget {
  const OrdensProducaoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsAsync = ref.watch(_opsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Produção'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar OP',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BuscaOpView())),
          ),
        ],
      ),
      body: opsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (ops) {
          if (ops.isEmpty) {
            return const Center(child: Text('Nenhuma OP cadastrada ainda.'));
          }
          return LarguraFormulario(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ops.length,
              itemBuilder: (context, i) {
                final op = ops[i];
                return CartaoLista(
                  title: Text(op.numeroOp),
                  subtitle: Text(
                    '${op.quantidadePedida} ${op.unidadePedido} · ${op.status} · '
                    '${op.dataPedido.day.toString().padLeft(2, '0')}/'
                    '${op.dataPedido.month.toString().padLeft(2, '0')}/'
                    '${op.dataPedido.year}',
                  ),
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
    final fichas = await ref.read(_fichasParaFormProvider.future);

    if (!context.mounted) return;

    if (fichas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre pelo menos 1 Ficha Técnica antes de criar uma OP.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final numeroOpController = TextEditingController();
    final quantidadeController = TextEditingController();
    String fichaIdSelecionada = fichas.first.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Nova Ordem de Produção'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CampoRotulado(
                      rotulo: 'Número da OP',
                      controller: numeroOpController,
                      hint: 'Ex: 802000272-1',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownRotulado(
                      rotulo: 'Ficha Técnica',
                      valor: fichaIdSelecionada,
                      itens: fichas
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.codigoFt),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => fichaIdSelecionada = v!),
                    ),
                    const SizedBox(height: 12),
                    CampoRotulado(
                      rotulo: 'Quantidade pedida',
                      controller: quantidadeController,
                      hint: 'Total do pedido do cliente',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Informe um número maior que zero';
                        }
                        return null;
                      },
                    ),
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
                final op = OrdemProducao(
                  id: '',
                  numeroOp: numeroOpController.text.trim(),
                  fichaTecnicaId: fichaIdSelecionada,
                  quantidadePedida: int.parse(quantidadeController.text),
                  dataPedido: DateTime.now(),
                  status: 'aberta',
                );
                await ref
                    .read(cadastrosRepositoryProvider)
                    .criarOrdemProducao(op);
                ref.invalidate(_opsProvider);
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
