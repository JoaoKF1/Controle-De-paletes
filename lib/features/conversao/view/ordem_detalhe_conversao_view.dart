import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../../shared/widgets/lancar_refugo_dialog.dart';
import '../../auth/controller/auth_controller.dart';
import 'paletes_apontados_conversao_view.dart';

/// Detalhe da OP (Conversão) com o apontamento embutido na própria tela —
/// mesmo padrão da Onduladeira: contexto da FT, chapas disponíveis, campo
/// de camadas e o botão de confirmar ficam todos aqui em cima das duas
/// listas de paletes (Onduladeira/Conversão).
class OrdemDetalheConversaoView extends ConsumerStatefulWidget {
  final OrdemProducaoInfo ordem;

  const OrdemDetalheConversaoView({super.key, required this.ordem});

  @override
  ConsumerState<OrdemDetalheConversaoView> createState() =>
      _OrdemDetalheConversaoViewState();
}

class _OrdemDetalheConversaoViewState
    extends ConsumerState<OrdemDetalheConversaoView> {
  final _formKey = GlobalKey<FormState>();
  final _camadasController = TextEditingController();
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _camadasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordem = widget.ordem;
    final paletesAsync = ref.watch(paletesDaOrdemProvider(ordem.id));
    final semPaletizacao =
        ordem.pacotesPorCamada == null || ordem.pecasPorPacote == null;
    final camadas = int.tryParse(_camadasController.text);
    final quantidadePrevista = (camadas == null || semPaletizacao)
        ? null
        : camadas * ordem.pacotesPorCamada! * ordem.pecasPorPacote!;

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
          final daOnduladeira = paletes
              .where((p) => p.setorOrigem == 'onduladeira')
              .toList();
          final daConversao = paletes
              .where((p) => p.setorOrigem == 'conversao')
              .toList();
          final chapasTotal = daOnduladeira.fold<int>(
            0,
            (s, p) => s + p.saldoDisponivel,
          );
          final caixasProduzidas = daConversao.fold<int>(
            0,
            (s, p) => s + p.quantidadeCalculada,
          );
          // Arranjo: quantas caixas saem de 1 chapa impressa/vincada — sem
          // isso, 1 caixa apontada sempre debitava 1 chapa inteira, o que
          // deixava "chapas disponíveis" negativo pra qualquer FT com
          // arranjo > 1 (ver plano técnico, 9.1).
          final chapasConsumidas = (caixasProduzidas / ordem.arranjoEfetivo)
              .ceil();
          final chapasDisponiveis = chapasTotal - chapasConsumidas;

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
                    rotulo: 'Chapas disponíveis para conversão',
                    valor: '$chapasDisponiveis de $chapasTotal chapas',
                    progresso: chapasTotal == 0
                        ? 0
                        : chapasConsumidas / chapasTotal,
                  ),
                  if (ordem.status == 'aberta' && semPaletizacao) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Ficha Técnica sem dados de paletização (pacotes por camada, peças por '
                      'pacote) — cadastre em Fichas Técnicas antes de apontar.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ] else if (ordem.status == 'aberta') ...[
                    const SizedBox(height: 16),
                    const RotuloSecao('Camadas de altura'),
                    TextFormField(
                      controller: _camadasController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Informe um número maior que zero';
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
                          : '$quantidadePrevista caixas',
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
                          builder: (_) =>
                              PaletesApontadosConversaoView(ordem: ordem),
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
            camadas: int.parse(_camadasController.text),
            responsavelId: responsavelId,
            setorOrigem: 'conversao',
          );
      ref.invalidate(paletesDaOrdemProvider(ordem.id));
      if (mounted) {
        setState(() {
          _salvando = false;
          _camadasController.clear();
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
