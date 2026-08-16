import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../../shared/widgets/lancar_refugo_dialog.dart';
import '../../auth/controller/auth_controller.dart';
import 'paletes_apontados_view.dart';

/// Detalhe da OP (Onduladeira) com o apontamento embutido na própria tela
/// — nada de navegar pra um formulário à parte: contexto da FT, progresso,
/// campo de altura e o botão de confirmar ficam todos aqui em cima da
/// lista dos paletes já apontados, pra apontar vários seguidos sem sair
/// da tela.
class OrdemDetalheView extends ConsumerStatefulWidget {
  final OrdemProducaoInfo ordem;

  const OrdemDetalheView({super.key, required this.ordem});

  @override
  ConsumerState<OrdemDetalheView> createState() => _OrdemDetalheViewState();
}

class _OrdemDetalheViewState extends ConsumerState<OrdemDetalheView> {
  final _formKey = GlobalKey<FormState>();
  final _alturaController = TextEditingController();
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _alturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordem = widget.ordem;
    final paletesAsync = ref.watch(paletesDaOrdemProvider(ordem.id));
    final altura = double.tryParse(_alturaController.text.replaceAll(',', '.'));
    final quantidadePrevista = altura == null
        ? null
        : ((altura / ordem.composicaoEspessuraMm) * ordem.qpPadrao).floor();

    return Scaffold(
      appBar: AppBar(
        title: Text('OP ${ordem.numeroOp}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Lançar refugo',
            onPressed: () => abrirDialogoLancarRefugo(
              context,
              ref,
              ordemProducaoId: ordem.id,
            ),
          ),
        ],
      ),
      body: paletesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (paletes) {
          // Só chapas da Onduladeira — as caixas que a Conversão apontar
          // nessa mesma OP são outra unidade, não somam aqui (ver
          // `alvoChapasOnduladeira`, plano técnico 9.1).
          final produzido = paletes
              .where((p) => p.setorOrigem == 'onduladeira')
              .fold<int>(0, (s, p) => s + p.quantidadeCalculada);
          final alvo = ordem.alvoChapasOnduladeira;
          return LarguraFormulario(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CartaoInfo(
                    linhas: {
                      'Cliente': ordem.clienteNome,
                      'Composição': ordem.composicaoCodigo,
                      'Medida': ordem.medidaExibicao,
                      'QP padrão': '${ordem.qpPadrao} pilhas',
                    },
                  ),
                  const SizedBox(height: 16),
                  CartaoProgresso(
                    rotulo: 'Produzido nesta OP',
                    valor: '$produzido de $alvo chapas',
                    progresso: alvo == 0 ? 0 : produzido / alvo,
                  ),
                  if (ordem.status == 'aberta') ...[
                    const SizedBox(height: 16),
                    const RotuloSecao('Altura medida (mm)'),
                    TextFormField(
                      controller: _alturaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final valor = double.tryParse(
                          (v ?? '').replaceAll(',', '.'),
                        );
                        if (valor == null || valor <= 0) {
                          return 'Informe um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CartaoInfo(
                      linhas: {
                        'Próximo palete desta OP': 'nº ${paletes.length + 1}',
                      },
                    ),
                    const SizedBox(height: 16),
                    CartaoResultado(
                      rotulo: 'Quantidade calculada',
                      valor: quantidadePrevista == null
                          ? '—'
                          : '$quantidadePrevista chapas',
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _erro!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    BotaoAcaoPrincipal(
                      texto: 'Confirmar apontamento',
                      icone: Icons.check_circle_outline,
                      carregando: _salvando,
                      onPressed: () => _confirmar(ordem),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaletesApontadosView(ordem: ordem),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: Text('Paletes apontados (${paletes.length})'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmar(OrdemProducaoInfo ordem) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    final responsavelId = ref.read(authControllerProvider).usuario!.id;
    try {
      await ref
          .read(paletesRepositoryProvider)
          .registrarPalete(
            ordem: ordem,
            alturaMedidaMm: double.parse(
              _alturaController.text.replaceAll(',', '.'),
            ),
            responsavelId: responsavelId,
            setorOrigem: 'onduladeira',
          );
      ref.invalidate(paletesDaOrdemProvider(ordem.id));
      if (mounted) {
        setState(() {
          _salvando = false;
          _alturaController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = e.toString();
        });
      }
    }
  }
}
