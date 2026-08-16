import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/qualidade_repository.dart';
import '../../domain/entities/palete.dart';
import '../../domain/entities/refugo.dart';
import '../../features/auth/controller/auth_controller.dart';

/// Ações disponíveis ao tocar num palete já apontado — hoje via toque na
/// lista (a leitura de código de barras de verdade só existe a partir do
/// Sprint 6, quando a etiqueta tiver um código real pra ler). Quais ações
/// aparecem depende do perfil de quem toca (ver plano técnico, 9.5):
/// setor dono do palete corrige/exclui, Qualidade pede revisão/segrega,
/// qualquer outro perfil autenticado só pode pedir revisão. Admin vê tudo.
Future<void> abrirAcoesPalete(
  BuildContext context,
  WidgetRef ref, {
  required Palete palete,
  required OrdemProducaoInfo ordem,
}) async {
  if (!palete.sincronizado) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apontamento pendente'),
        content: const Text(
          'Esse palete ainda não foi sincronizado com o servidor — nenhuma ação '
          'dá pra fazer nele até a conexão voltar e o envio ser confirmado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
    return;
  }

  final usuario = ref.read(authControllerProvider).usuario!;
  final ehDoSetor =
      usuario.perfil == palete.setorOrigem || usuario.perfil == 'admin';
  final ehQualidade =
      usuario.perfil == 'qualidade' || usuario.perfil == 'admin';

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: const Text('Pedir revisão'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _abrirDialogoPedirRevisao(
                context,
                ref,
                palete: palete,
                usuarioId: usuario.id,
              );
            },
          ),
          if (ehQualidade && palete.saldoDisponivel > 0)
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Segregar inteiro'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmarSegregarInteiro(
                  context,
                  ref,
                  palete: palete,
                  ordemProducaoId: ordem.id,
                  usuarioId: usuario.id,
                );
              },
            ),
          if (ehDoSetor)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Corrigir quantidade'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _abrirDialogoCorrigir(
                  context,
                  ref,
                  palete: palete,
                  ordem: ordem,
                );
              },
            ),
          if (ehDoSetor && palete.saldoDisponivel > 0)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Excluir totalmente'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _abrirDialogoExcluir(
                  context,
                  ref,
                  palete: palete,
                  ordemProducaoId: ordem.id,
                  responsavelId: usuario.id,
                );
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _abrirDialogoPedirRevisao(
  BuildContext context,
  WidgetRef ref, {
  required Palete palete,
  required String usuarioId,
}) async {
  final formKey = GlobalKey<FormState>();
  final quantidadeController = TextEditingController(
    text: palete.saldoDisponivel.toString(),
  );
  final motivoController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Pedir revisão — palete ${palete.numeroExibicao}'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: quantidadeController,
              decoration: InputDecoration(
                labelText:
                    'Quantidade afetada (máx. ${palete.saldoDisponivel})',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) {
                  return 'Informe um número maior que zero';
                }
                if (n > palete.saldoDisponivel) {
                  return 'Maior que o saldo disponível';
                }
                return null;
              },
            ),
            TextFormField(
              controller: motivoController,
              decoration: const InputDecoration(labelText: 'Motivo'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
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
            await ref
                .read(qualidadeRepositoryProvider)
                .abrirOcorrencia(
                  paleteId: palete.id,
                  quantidadeAfetada: int.parse(quantidadeController.text),
                  motivo: motivoController.text.trim(),
                  abertoPor: usuarioId,
                );
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('Abrir ocorrência'),
        ),
      ],
    ),
  );
}

Future<void> _confirmarSegregarInteiro(
  BuildContext context,
  WidgetRef ref, {
  required Palete palete,
  required String ordemProducaoId,
  required String usuarioId,
}) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Segregar inteiro'),
      content: Text(
        'Reprova o palete ${palete.numeroExibicao} inteiro agora, sem análise — '
        'debita ${palete.saldoDisponivel} do saldo e soma ao refugo da OP. Confirma?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Segregar'),
        ),
      ],
    ),
  );
  if (confirmou == true) {
    await ref
        .read(qualidadeRepositoryProvider)
        .segregarInteiro(
          palete: palete,
          ordemProducaoId: ordemProducaoId,
          usuarioId: usuarioId,
        );
  }
}

Future<void> _abrirDialogoCorrigir(
  BuildContext context,
  WidgetRef ref, {
  required Palete palete,
  required OrdemProducaoInfo ordem,
}) async {
  final ehConversao = palete.setorOrigem == 'conversao';
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(
    text: ehConversao
        ? palete.camadas?.toString() ?? ''
        : palete.alturaMedidaMm?.toStringAsFixed(0) ?? '',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        int? novaQuantidade;
        if (ehConversao) {
          final camadas = int.tryParse(controller.text);
          novaQuantidade = camadas == null
              ? null
              : camadas * ordem.pacotesPorCamada! * ordem.pecasPorPacote!;
        } else {
          final altura = double.tryParse(controller.text.replaceAll(',', '.'));
          novaQuantidade = altura == null
              ? null
              : ((altura / ordem.composicaoEspessuraMm) * ordem.qpPadrao)
                    .floor();
        }

        return AlertDialog(
          title: Text('Corrigir palete ${palete.numeroExibicao}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: ehConversao
                        ? 'Camadas de altura'
                        : 'Altura medida (mm)',
                  ),
                  keyboardType: ehConversao
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (ehConversao) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) {
                        return 'Informe um número maior que zero';
                      }
                    } else {
                      final valor = double.tryParse(
                        (v ?? '').replaceAll(',', '.'),
                      );
                      if (valor == null || valor <= 0) {
                        return 'Informe um número válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  novaQuantidade == null
                      ? 'Nova quantidade: —'
                      : 'Nova quantidade: $novaQuantidade',
                  style: Theme.of(dialogContext).textTheme.titleMedium,
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
                await ref
                    .read(qualidadeRepositoryProvider)
                    .corrigirApontamento(
                      palete: palete,
                      ordem: ordem,
                      novaAlturaMm: ehConversao
                          ? null
                          : double.parse(controller.text.replaceAll(',', '.')),
                      novasCamadas: ehConversao
                          ? int.parse(controller.text)
                          : null,
                    );
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

Future<void> _abrirDialogoExcluir(
  BuildContext context,
  WidgetRef ref, {
  required Palete palete,
  required String ordemProducaoId,
  required String responsavelId,
}) async {
  var motivoSelecionado = motivosRefugo.first;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text('Excluir palete ${palete.numeroExibicao}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Descarta ${palete.saldoDisponivel} '
              '${palete.setorOrigem == 'conversao' ? 'caixas' : 'chapas'} '
              'e soma ao refugo da OP.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: motivoSelecionado,
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: motivosRefugo
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => motivoSelecionado = v!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(qualidadeRepositoryProvider)
                  .excluirTotalmente(
                    palete: palete,
                    ordemProducaoId: ordemProducaoId,
                    responsavelId: responsavelId,
                    motivoRefugo: motivoSelecionado,
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    ),
  );
}
