import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../data/repositories/qualidade_repository.dart';
import '../../../domain/entities/ocorrencia_qualidade.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../auth/controller/auth_controller.dart';
import 'testes_qualidade_view.dart';

final _emAnaliseProvider =
    FutureProvider.autoDispose<List<OcorrenciaQualidade>>((ref) {
      return ref.watch(qualidadeRepositoryProvider).listarEmAnalise();
    });

class FilaAnaliseView extends ConsumerWidget {
  const FilaAnaliseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final filaAsync = ref.watch(_emAnaliseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario?.nome ?? 'Fila de análise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Testes de qualidade',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TestesQualidadeView()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: filaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (fila) {
          if (fila.isEmpty) {
            return const Center(child: Text('Nenhuma ocorrência em análise.'));
          }
          return LarguraFormulario(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fila.length,
              itemBuilder: (context, i) {
                final o = fila[i];
                return CartaoLista(
                  title: Text(
                    'OP ${o.numeroOp} · Palete ${o.paleteNumeroSequencial}',
                  ),
                  subtitle: Text('${o.motivo} · ${o.quantidadeAfetada} un.'),
                  trailing: Text(
                    DateFormat('dd/MM HH:mm').format(o.dataAbertura),
                  ),
                  onTap: () => _abrirResolucao(context, ref, o),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirResolucao(
    BuildContext context,
    WidgetRef ref,
    OcorrenciaQualidade ocorrencia,
  ) async {
    final formKey = GlobalKey<FormState>();
    final quantidadeController = TextEditingController(text: '0');
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(
            'OP ${ocorrencia.numeroOp} · Palete ${ocorrencia.paleteNumeroSequencial}',
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${ocorrencia.motivo}\n\nQuantidade afetada: ${ocorrencia.quantidadeAfetada}',
                  ),
                  const SizedBox(height: 12),
                  CampoRotulado(
                    rotulo:
                        'Quantidade reprovada (máx. ${ocorrencia.quantidadeAfetada})',
                    controller: quantidadeController,
                    helperText:
                        '0 libera tudo · igual ao afetado reprova tudo · '
                        'valor no meio libera o resto',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Informe um número válido';
                      if (n > ocorrencia.quantidadeAfetada) {
                        return 'Maior que a quantidade afetada';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            setState(() => quantidadeController.text = '0'),
                        child: const Text('Liberar tudo'),
                      ),
                      TextButton(
                        onPressed: () => setState(
                          () => quantidadeController.text = ocorrencia
                              .quantidadeAfetada
                              .toString(),
                        ),
                        child: const Text('Reprovar tudo'),
                      ),
                    ],
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
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => salvando = true);
                      final sucesso = await _resolver(
                        context,
                        ref,
                        ocorrencia,
                        quantidadeReprovada: int.parse(
                          quantidadeController.text,
                        ),
                      );
                      if (sucesso && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      } else if (dialogContext.mounted) {
                        setState(() => salvando = false);
                      }
                    },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _resolver(
    BuildContext context,
    WidgetRef ref,
    OcorrenciaQualidade ocorrencia, {
    required int quantidadeReprovada,
  }) async {
    final usuarioId = ref.read(authControllerProvider).usuario!.id;
    try {
      final palete = await ref
          .read(paletesRepositoryProvider)
          .buscarPaletePorId(ocorrencia.paleteId);
      await ref
          .read(qualidadeRepositoryProvider)
          .resolverOcorrencia(
            ocorrencia: ocorrencia,
            quantidadeReprovada: quantidadeReprovada,
            usuarioId: usuarioId,
            palete: palete,
            ordemProducaoId: palete.ordemProducaoId,
          );
      ref.invalidate(_emAnaliseProvider);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
      return false;
    }
  }
}
