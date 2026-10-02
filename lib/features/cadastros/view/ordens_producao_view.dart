import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/mensagem_erro.dart';
import '../../../data/repositories/cadastros_repository.dart';
import '../../../domain/entities/ficha_tecnica.dart';
import '../../../domain/entities/ordem_producao.dart';
import '../../../domain/services/calculo_palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../apontamento/view/busca_op_view.dart';
import '../../auth/controller/auth_controller.dart';

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
    // Admin e Onduladeira criam OP (a Onduladeira mede a espessura da chapa
    // no cadastro); Conversão só consulta — ver plano técnico, 2.
    final perfil = ref.watch(authControllerProvider).usuario?.perfil;
    final podeCriar = perfil == 'admin' || perfil == 'onduladeira';

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
        error: (erro, _) =>
            Center(child: Text('Erro ao carregar: ${mensagemErro(erro)}')),
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
                    'espessura ${formatarMm(paraCentesimos(op.espessuraMedidaMm))} mm · '
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
      floatingActionButton: podeCriar
          ? FloatingActionButton(
              onPressed: () => _abrirFormulario(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _abrirFormulario(BuildContext context, WidgetRef ref) async {
    final List<FichaTecnica> fichas;
    try {
      fichas = await ref.read(_fichasParaFormProvider.future);
    } catch (e) {
      if (context.mounted) await mostrarErro(context, e);
      return;
    }

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
    final espessuraController = TextEditingController();
    FichaTecnica? fichaSelecionada;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final espessuraMedida = lerCentesimos(espessuraController.text);
          final esperada = fichaSelecionada == null
              ? null
              : paraCentesimos(fichaSelecionada!.espessuraEsperadaMm);
          final diverge =
              espessuraMedida != null &&
              esperada != null &&
              espessuraDiverge(
                medidaCentesimos: espessuraMedida,
                esperadaCentesimos: esperada,
              );

          return AlertDialog(
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
                      CampoSelecaoComBusca<FichaTecnica>(
                        rotulo: 'Ficha Técnica',
                        valor: fichaSelecionada,
                        itens: fichas,
                        titulo: (f) => f.codigoFt,
                        subtitulo: (f) => '${f.clienteNome} · ${f.composicao}',
                        onSelecionado: (f) =>
                            setState(() => fichaSelecionada = f),
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
                      const SizedBox(height: 12),
                      CampoRotulado(
                        rotulo: 'Espessura medida da chapa (mm)',
                        controller: espessuraController,
                        hint: 'Ex: 3,85',
                        helperText: esperada == null
                            ? 'Medida no início da produção desta OP'
                            : 'Espessura da FT: ${formatarMm(esperada)} mm',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => lerCentesimos(v) == null
                            ? 'Obrigatório: maior que zero, até 2 casas decimais'
                            : null,
                      ),
                      if (diverge) ...[
                        const SizedBox(height: 12),
                        _AvisoEspessura(
                          medida: espessuraMedida,
                          esperada: esperada,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'A espessura não pode ser alterada depois do primeiro '
                        'palete apontado nesta OP.',
                        style: Theme.of(dialogContext).textTheme.bodySmall,
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
                    fichaTecnicaId: fichaSelecionada!.id,
                    quantidadePedida: int.parse(quantidadeController.text),
                    dataPedido: DateTime.now(),
                    status: 'aberta',
                    espessuraMedidaMm: deCentesimos(
                      lerCentesimos(espessuraController.text)!,
                    ),
                  );
                  try {
                    await ref
                        .read(cadastrosRepositoryProvider)
                        .criarOrdemProducao(op);
                  } catch (e) {
                    if (dialogContext.mounted) {
                      await mostrarErro(dialogContext, e);
                    }
                    return;
                  }
                  ref.invalidate(_opsProvider);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
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

/// Aviso (não bloqueia) quando a espessura medida difere mais de 10% da
/// esperada na FT — pode ser erro de digitação ou chapa fora do padrão.
class _AvisoEspessura extends StatelessWidget {
  final int medida;
  final int esperada;
  const _AvisoEspessura({required this.medida, required this.esperada});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cores.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: cores.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Espessura medida (${formatarMm(medida)} mm) difere mais de '
              '$limiteDivergenciaEspessuraPercentual% da espessura da FT '
              '(${formatarMm(esperada)} mm). Confira a medição antes de salvar.',
              style: TextStyle(color: cores.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
