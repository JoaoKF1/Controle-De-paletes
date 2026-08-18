import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../data/repositories/paletes_repository.dart';
import '../../../data/repositories/qualidade_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../../shared/widgets/lancar_refugo_dialog.dart';
import '../../auth/controller/auth_controller.dart';
import '../../qualidade/view/testes_qualidade_ordem_view.dart';
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
  bool _ultimoPalete = false;

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
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Testes de qualidade',
            onPressed: () => _abrirTestesQualidade(context, ref, ordem),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Lançar refugo',
            onPressed: () => abrirDialogoLancarRefugo(
              context,
              ref,
              ordemProducaoId: ordem.id,
            ),
          ),
          if (ordem.status == 'aberta')
            IconButton(
              icon: const Icon(Icons.task_alt_outlined),
              tooltip: 'Encerrar produção',
              onPressed: () => _encerrarProducao(context, ref, ordem),
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
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _ultimoPalete,
                      onChanged: (v) =>
                          setState(() => _ultimoPalete = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Este é o último palete desta OP'),
                      subtitle: const Text(
                        'Encerra a produção ao confirmar — mesmo que a '
                        'quantidade produzida passe do pedido',
                      ),
                    ),
                    const SizedBox(height: 12),
                    BotaoAcaoPrincipal(
                      texto: _ultimoPalete
                          ? 'Confirmar e encerrar OP'
                          : 'Confirmar apontamento',
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

  /// Atalho pra pular direto pros testes de qualidade desta OP, sem passar
  /// pela lista/busca de OPs em Testes de qualidade (ver plano técnico, 9.6).
  Future<void> _abrirTestesQualidade(
    BuildContext context,
    WidgetRef ref,
    OrdemProducaoInfo ordem,
  ) async {
    final ordemParaTeste = await ref
        .read(qualidadeRepositoryProvider)
        .buscarOrdemParaTeste(ordem.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestesQualidadeOrdemView(ordem: ordemParaTeste),
      ),
    );
  }

  /// Ação explícita da Onduladeira, nunca automática por bater a
  /// quantidade pedida (ver plano técnico, 9.1) — depois de encerrada, a OP
  /// some da lista de "abertas" e não recebe mais apontamento novo, mas
  /// continua disponível pra teste de qualidade (ver 9.6).
  Future<void> _encerrarProducao(
    BuildContext context,
    WidgetRef ref,
    OrdemProducaoInfo ordem,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Encerrar produção?'),
        content: Text(
          'A OP ${ordem.numeroOp} não vai mais aparecer na lista de ordens '
          'em aberto e não vai ser possível apontar novos paletes nela.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    await ref.read(cadastrosRepositoryProvider).encerrarOrdemProducao(ordem.id);
    ref.invalidate(ordensAbertasProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produção encerrada.')));
      Navigator.of(context).pop();
    }
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
      if (_ultimoPalete) {
        await ref
            .read(cadastrosRepositoryProvider)
            .encerrarOrdemProducao(ordem.id);
        ref.invalidate(ordensAbertasProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Palete registrado e produção encerrada.'),
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }
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
