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

/// Valida que o máximo de uma faixa não fica menor que o mínimo já
/// digitado — os dois são opcionais, então só valida quando ambos estão
/// preenchidos (o check constraint do banco é a garantia final, isso aqui
/// só evita o erro feio chegando lá).
String? _validarFaixaMax(TextEditingController minController, String? v) {
  final minValor = double.tryParse(minController.text.replaceAll(',', '.'));
  final maxValor = double.tryParse((v ?? '').replaceAll(',', '.'));
  if (minValor != null && maxValor != null && maxValor < minValor) {
    return 'Menor que o mínimo';
  }
  return null;
}

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
    final cobbInternoMinController = TextEditingController(
      text: existente?.cobbInternoMin?.toString() ?? '',
    );
    final cobbInternoMaxController = TextEditingController(
      text: existente?.cobbInternoMax?.toString() ?? '',
    );
    final cobbExternoMinController = TextEditingController(
      text: existente?.cobbExternoMin?.toString() ?? '',
    );
    final cobbExternoMaxController = TextEditingController(
      text: existente?.cobbExternoMax?.toString() ?? '',
    );
    final mullenController = TextEditingController(
      text: existente?.mullen?.toString() ?? '',
    );
    final compressaoController = TextEditingController(
      text: existente?.compressao?.toString() ?? '',
    );
    final resinaInternaMinController = TextEditingController(
      text: existente?.resinaInternaMin?.toString() ?? '',
    );
    final resinaInternaMaxController = TextEditingController(
      text: existente?.resinaInternaMax?.toString() ?? '',
    );
    final resinaExternaMinController = TextEditingController(
      text: existente?.resinaExternaMin?.toString() ?? '',
    );
    final resinaExternaMaxController = TextEditingController(
      text: existente?.resinaExternaMax?.toString() ?? '',
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
                    CampoRotulado(
                      rotulo: 'Código FT',
                      controller: codigoController,
                      hint: 'Ex: 055234',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownRotulado(
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
                    DropdownRotulado(
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
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Comprimento (mm)',
                        controller: comprimentoController,
                        hint: 'Ex: 733',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: validarNumeroPositivo,
                      ),
                      CampoRotulado(
                        rotulo: 'Largura (mm)',
                        controller: larguraController,
                        hint: 'Ex: 1.964',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: validarNumeroPositivo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloSecaoMaiuscula('Vincos (opcional)'),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Vinco 1',
                        controller: vinco1Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Vinco 2',
                        controller: vinco2Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Vinco 3',
                        controller: vinco3Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Vinco 4',
                        controller: vinco4Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CampoRotulado(
                      rotulo: 'Vinco 5',
                      controller: vinco5Controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    linhaDupla(
                      CampoRotulado(
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
                      CampoRotulado(
                        rotulo: 'Referência',
                        controller: referenciaController,
                        hint: 'Opcional',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloSecaoMaiuscula('Qualidade (opcional)'),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Gramatura',
                        controller: gramaturaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Coluna',
                        controller: colunaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Mullen',
                        controller: mullenController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Compressão',
                        controller: compressaoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloSecaoMaiuscula(
                      'Faixas de Cobb e Resina (mín/máx, opcional)',
                    ),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Cobb interno mín.',
                        controller: cobbInternoMinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Cobb interno máx.',
                        controller: cobbInternoMaxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            _validarFaixaMax(cobbInternoMinController, v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Cobb externo mín.',
                        controller: cobbExternoMinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Cobb externo máx.',
                        controller: cobbExternoMaxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            _validarFaixaMax(cobbExternoMinController, v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Resina interna mín.',
                        controller: resinaInternaMinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Resina interna máx.',
                        controller: resinaInternaMaxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            _validarFaixaMax(resinaInternaMinController, v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Resina externa mín.',
                        controller: resinaExternaMinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      CampoRotulado(
                        rotulo: 'Resina externa máx.',
                        controller: resinaExternaMaxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            _validarFaixaMax(resinaExternaMinController, v),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloSecaoMaiuscula(
                      'Paletização da Conversão (só p/ OP 802)',
                    ),
                    linhaDupla(
                      CampoRotulado(
                        rotulo: 'Pacotes por camada',
                        controller: pacotesPorCamadaController,
                        keyboardType: TextInputType.number,
                      ),
                      CampoRotulado(
                        rotulo: 'Peças por pacote',
                        controller: pecasPorPacoteController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CampoRotulado(
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
                  cobbInternoMin: double.tryParse(
                    cobbInternoMinController.text.replaceAll(',', '.'),
                  ),
                  cobbInternoMax: double.tryParse(
                    cobbInternoMaxController.text.replaceAll(',', '.'),
                  ),
                  cobbExternoMin: double.tryParse(
                    cobbExternoMinController.text.replaceAll(',', '.'),
                  ),
                  cobbExternoMax: double.tryParse(
                    cobbExternoMaxController.text.replaceAll(',', '.'),
                  ),
                  mullen: double.tryParse(
                    mullenController.text.replaceAll(',', '.'),
                  ),
                  compressao: double.tryParse(
                    compressaoController.text.replaceAll(',', '.'),
                  ),
                  resinaInternaMin: double.tryParse(
                    resinaInternaMinController.text.replaceAll(',', '.'),
                  ),
                  resinaInternaMax: double.tryParse(
                    resinaInternaMaxController.text.replaceAll(',', '.'),
                  ),
                  resinaExternaMin: double.tryParse(
                    resinaExternaMinController.text.replaceAll(',', '.'),
                  ),
                  resinaExternaMax: double.tryParse(
                    resinaExternaMaxController.text.replaceAll(',', '.'),
                  ),
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
