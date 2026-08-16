import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../domain/entities/cliente.dart';
import '../../../domain/entities/composicao.dart';
import '../../../domain/entities/ficha_tecnica.dart';
import '../../../shared/widgets/apontamento_kit.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fichas técnicas')),
      body: fichasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (fichas) {
          if (fichas.isEmpty) {
            return const Center(
              child: Text('Nenhuma ficha técnica cadastrada ainda.'),
            );
          }
          return LarguraFormulario(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fichas.length,
              itemBuilder: (context, i) {
                final f = fichas[i];
                return CartaoLista(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    child: Icon(
                      Icons.description,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(f.codigoFt),
                  subtitle: Text(
                    '${f.medidaExibicao} · QP padrão: ${f.qpPadrao}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirFormulario(context, ref, existente: f),
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

  Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    FichaTecnica? existente,
  }) async {
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
    final codigoController = TextEditingController(
      text: existente?.codigoFt ?? '',
    );
    final comprimentoController = TextEditingController(
      text: existente?.comprimentoMm.toString() ?? '',
    );
    final larguraController = TextEditingController(
      text: existente?.larguraMm.toString() ?? '',
    );
    final qpController = TextEditingController(
      text: existente?.qpPadrao.toString() ?? '',
    );
    final referenciaController = TextEditingController(
      text: existente?.referencia ?? '',
    );
    final gramaturaController = TextEditingController(
      text: existente?.gramatura?.toString() ?? '',
    );
    final colunaController = TextEditingController(
      text: existente?.coluna?.toString() ?? '',
    );
    final cobbInternoController = TextEditingController(
      text: existente?.cobbInterno?.toString() ?? '',
    );
    final cobbExternoController = TextEditingController(
      text: existente?.cobbExterno?.toString() ?? '',
    );
    final mullenController = TextEditingController(
      text: existente?.mullen?.toString() ?? '',
    );
    final compressaoController = TextEditingController(
      text: existente?.compressao?.toString() ?? '',
    );
    final resinaInternaController = TextEditingController(
      text: existente?.resinaInterna ?? '',
    );
    final resinaExternaController = TextEditingController(
      text: existente?.resinaExterna ?? '',
    );
    final vinco1Controller = TextEditingController(
      text: existente?.vinco1Mm?.toString() ?? '',
    );
    final vinco2Controller = TextEditingController(
      text: existente?.vinco2Mm?.toString() ?? '',
    );
    final vinco3Controller = TextEditingController(
      text: existente?.vinco3Mm?.toString() ?? '',
    );
    final vinco4Controller = TextEditingController(
      text: existente?.vinco4Mm?.toString() ?? '',
    );
    final vinco5Controller = TextEditingController(
      text: existente?.vinco5Mm?.toString() ?? '',
    );
    final pacotesPorCamadaController = TextEditingController(
      text: existente?.pacotesPorCamada?.toString() ?? '',
    );
    final pecasPorPacoteController = TextEditingController(
      text: existente?.pecasPorPacote?.toString() ?? '',
    );
    final arranjoController = TextEditingController(
      text: existente?.arranjo?.toString() ?? '',
    );
    String? clienteIdSelecionado = existente?.clienteId ?? clientes.first.id;
    String? composicaoIdSelecionada =
        existente?.composicaoId ?? composicoes.first.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(
            existente == null ? 'Nova ficha técnica' : 'Editar ficha técnica',
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Campo(
                      rotulo: 'Código FT',
                      controller: codigoController,
                      hint: 'Ex: 055234',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _RotuloDropdown(
                      rotulo: 'Cliente',
                      valor: clienteIdSelecionado,
                      itens: clientes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.razaoSocial),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => clienteIdSelecionado = v),
                    ),
                    const SizedBox(height: 12),
                    _RotuloDropdown(
                      rotulo: 'Composição',
                      valor: composicaoIdSelecionada,
                      itens: composicoes
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
                    const SizedBox(height: 12),
                    _linha(
                      _Campo(
                        rotulo: 'Comprimento (mm)',
                        controller: comprimentoController,
                        hint: 'Ex: 733',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validarNumeroPositivo,
                      ),
                      _Campo(
                        rotulo: 'Largura (mm)',
                        controller: larguraController,
                        hint: 'Ex: 1.964',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validarNumeroPositivo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloSecaoMaiuscula('Vincos (opcional)'),
                    _linha(
                      _Campo(
                        rotulo: 'Vinco 1',
                        controller: vinco1Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _Campo(
                        rotulo: 'Vinco 2',
                        controller: vinco2Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _linha(
                      _Campo(
                        rotulo: 'Vinco 3',
                        controller: vinco3Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _Campo(
                        rotulo: 'Vinco 4',
                        controller: vinco4Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Campo(
                      rotulo: 'Vinco 5',
                      controller: vinco5Controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _linha(
                      _Campo(
                        rotulo: 'QP padrão',
                        controller: qpController,
                        hint: 'Nº de pilhas',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'Maior que zero';
                          }
                          return null;
                        },
                      ),
                      _Campo(
                        rotulo: 'Referência',
                        controller: referenciaController,
                        hint: 'Opcional',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloSecaoMaiuscula('Qualidade (opcional)'),
                    _linha(
                      _Campo(
                        rotulo: 'Gramatura',
                        controller: gramaturaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _Campo(
                        rotulo: 'Coluna',
                        controller: colunaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _linha(
                      _Campo(
                        rotulo: 'Cobb interno',
                        controller: cobbInternoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _Campo(
                        rotulo: 'Cobb externo',
                        controller: cobbExternoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _linha(
                      _Campo(
                        rotulo: 'Mullen',
                        controller: mullenController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _Campo(
                        rotulo: 'Compressão',
                        controller: compressaoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _linha(
                      _Campo(
                        rotulo: 'Resina interna',
                        controller: resinaInternaController,
                      ),
                      _Campo(
                        rotulo: 'Resina externa',
                        controller: resinaExternaController,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloSecaoMaiuscula(
                      'Paletização da Conversão (só p/ OP 802)',
                    ),
                    _linha(
                      _Campo(
                        rotulo: 'Pacotes por camada',
                        controller: pacotesPorCamadaController,
                        keyboardType: TextInputType.number,
                      ),
                      _Campo(
                        rotulo: 'Peças por pacote',
                        controller: pecasPorPacoteController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Campo(
                      rotulo: 'Arranjo (caixas por chapa)',
                      controller: arranjoController,
                      hint: 'Vazio = 1 caixa por chapa',
                      keyboardType: TextInputType.number,
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
                final ficha = FichaTecnica(
                  id: existente?.id ?? '',
                  codigoFt: codigoController.text.trim(),
                  clienteId: clienteIdSelecionado!,
                  composicaoId: composicaoIdSelecionada!,
                  comprimentoMm: double.parse(
                    comprimentoController.text.replaceAll(',', '.'),
                  ),
                  larguraMm: double.parse(
                    larguraController.text.replaceAll(',', '.'),
                  ),
                  qpPadrao: int.parse(qpController.text),
                  referencia: referenciaController.text.trim().isEmpty
                      ? null
                      : referenciaController.text.trim(),
                  ativo: existente?.ativo ?? true,
                  gramatura: double.tryParse(
                    gramaturaController.text.replaceAll(',', '.'),
                  ),
                  coluna: double.tryParse(
                    colunaController.text.replaceAll(',', '.'),
                  ),
                  cobbInterno: double.tryParse(
                    cobbInternoController.text.replaceAll(',', '.'),
                  ),
                  cobbExterno: double.tryParse(
                    cobbExternoController.text.replaceAll(',', '.'),
                  ),
                  mullen: double.tryParse(
                    mullenController.text.replaceAll(',', '.'),
                  ),
                  compressao: double.tryParse(
                    compressaoController.text.replaceAll(',', '.'),
                  ),
                  resinaInterna: resinaInternaController.text.trim().isEmpty
                      ? null
                      : resinaInternaController.text.trim(),
                  resinaExterna: resinaExternaController.text.trim().isEmpty
                      ? null
                      : resinaExternaController.text.trim(),
                  vinco1Mm: double.tryParse(
                    vinco1Controller.text.replaceAll(',', '.'),
                  ),
                  vinco2Mm: double.tryParse(
                    vinco2Controller.text.replaceAll(',', '.'),
                  ),
                  vinco3Mm: double.tryParse(
                    vinco3Controller.text.replaceAll(',', '.'),
                  ),
                  vinco4Mm: double.tryParse(
                    vinco4Controller.text.replaceAll(',', '.'),
                  ),
                  vinco5Mm: double.tryParse(
                    vinco5Controller.text.replaceAll(',', '.'),
                  ),
                  pacotesPorCamada: int.tryParse(
                    pacotesPorCamadaController.text,
                  ),
                  pecasPorPacote: int.tryParse(pecasPorPacoteController.text),
                  arranjo: int.tryParse(arranjoController.text),
                );
                final repo = ref.read(cadastrosRepositoryProvider);
                if (existente == null) {
                  await repo.criarFichaTecnica(ficha);
                } else {
                  await repo.atualizarFichaTecnica(ficha);
                }
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

Widget _linha(Widget a, Widget b) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(child: a),
    const SizedBox(width: 12),
    Expanded(child: b),
  ],
);

String? _validarNumeroPositivo(String? v) {
  final valor = double.tryParse((v ?? '').replaceAll(',', '.'));
  if (valor == null || valor <= 0) return 'Obrigatório';
  return null;
}

class _Campo extends StatelessWidget {
  final String rotulo;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Campo({
    required this.rotulo,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RotuloSecao(rotulo),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }
}

class _RotuloDropdown extends StatelessWidget {
  final String rotulo;
  final String? valor;
  final List<DropdownMenuItem<String>> itens;
  final ValueChanged<String?> onChanged;

  const _RotuloDropdown({
    required this.rotulo,
    required this.valor,
    required this.itens,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RotuloSecao(rotulo),
        DropdownButtonFormField<String>(
          initialValue: valor,
          items: itens,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
