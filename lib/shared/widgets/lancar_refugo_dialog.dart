import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/qualidade_repository.dart';
import '../../domain/entities/refugo.dart';
import '../../features/auth/controller/auth_controller.dart';

/// Lançamento de refugo — independente de um palete específico, vinculado
/// só à OP (ver plano técnico, 9.3). Disponível pra qualquer operador do
/// setor onde ocorreu.
Future<void> abrirDialogoLancarRefugo(
  BuildContext context,
  WidgetRef ref, {
  required String ordemProducaoId,
}) async {
  final formKey = GlobalKey<FormState>();
  final quantidadeController = TextEditingController();
  var motivoSelecionado = motivosRefugo.first;
  final usuario = ref.read(authControllerProvider).usuario!;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Lançar refugo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantidadeController,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) {
                    return 'Informe um número maior que zero';
                  }
                  return null;
                },
              ),
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
                  .lancarRefugo(
                    ordemProducaoId: ordemProducaoId,
                    responsavelId: usuario.id,
                    quantidade: int.parse(quantidadeController.text),
                    motivo: motivoSelecionado,
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}
