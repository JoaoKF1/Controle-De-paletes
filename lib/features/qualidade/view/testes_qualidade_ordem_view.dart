import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cadastros_repository.dart';
import '../../../data/repositories/qualidade_repository.dart';
import '../../../domain/entities/ficha_tecnica.dart';
import '../../../domain/entities/teste_qualidade.dart';
import '../../../domain/services/avaliacao_qualidade.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../auth/controller/auth_controller.dart';
import 'testes_qualidade_detalhe_view.dart';

final _fichaDaOrdemProvider = FutureProvider.autoDispose.family<FichaTecnica, String>((
  ref,
  fichaTecnicaId,
) {
  return ref
      .read(cadastrosRepositoryProvider)
      .buscarFichaTecnicaPorId(fichaTecnicaId);
});

final _testesDaOrdemProvider = FutureProvider.autoDispose
    .family<List<TesteQualidade>, String>((ref, ordemProducaoId) {
      return ref
          .read(qualidadeRepositoryProvider)
          .listarTestesDaOrdem(ordemProducaoId);
    });

/// Chave de cada campo do teste, na ordem em que aparece no formulário e no
/// detalhe — compartilhada entre o registro (editável) e o detalhe
/// (somente leitura).
const camposTeste = [
  'gramatura',
  'coluna',
  'cobbInterno',
  'cobbExterno',
  'mullen',
  'compressao',
  'resinaInterna',
  'resinaExterna',
];

const rotulosCampoTeste = {
  'gramatura': 'Gramatura',
  'coluna': 'Coluna',
  'cobbInterno': 'Cobb interno',
  'cobbExterno': 'Cobb externo',
  'mullen': 'Mullen',
  'compressao': 'Compressão',
  'resinaInterna': 'Resina interna',
  'resinaExterna': 'Resina externa',
};

TesteQualidade testeParaAvaliar(Map<String, double?> v) => TesteQualidade(
  id: '',
  ordemProducaoId: '',
  numeroOp: '',
  fichaTecnicaId: '',
  registradoPorNome: '',
  criadoEm: DateTime.now(),
  gramaturaMedida: v['gramatura'],
  colunaMedida: v['coluna'],
  cobbInternoMedido: v['cobbInterno'],
  cobbExternoMedido: v['cobbExterno'],
  mullenMedido: v['mullen'],
  compressaoMedida: v['compressao'],
  resinaInternaMedida: v['resinaInterna'],
  resinaExternaMedida: v['resinaExterna'],
);

/// Lista os testes já registrados numa OP específica — o contexto da OP já
/// está definido ao entrar aqui, então o formulário de novo teste não
/// precisa mais perguntar qual OP é.
class TestesQualidadeOrdemView extends ConsumerWidget {
  final OrdemParaTeste ordem;
  const TestesQualidadeOrdemView({super.key, required this.ordem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fichaAsync = ref.watch(_fichaDaOrdemProvider(ordem.fichaTecnicaId));
    final testesAsync = ref.watch(_testesDaOrdemProvider(ordem.id));
    final perfil = ref.watch(authControllerProvider).usuario?.perfil;
    // Só quem registra teste de verdade (RLS só libera insert pra
    // qualidade/admin — ver plano técnico, 9.11) vê o botão de novo teste;
    // os outros perfis usam esta tela só pra consulta.
    final podeRegistrar = perfil == 'qualidade' || perfil == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('OP ${ordem.numeroOp}'),
            Text(
              '${ordem.clienteNome} · ${ordem.unidadePedido}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).appBarTheme.foregroundColor?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
      body: testesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (testes) {
          if (testes.isEmpty) {
            return const Center(
              child: Text('Nenhum teste registrado nesta OP ainda.'),
            );
          }
          return LarguraFormulario(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: testes.length,
              itemBuilder: (context, i) {
                final t = testes[i];
                return CartaoLista(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.6),
                    child: Icon(
                      Icons.science_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text('Teste ${i + 1}'),
                  subtitle: Text(_dataExibicao(t.criadoEm)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final ficha = await ref.read(
                      _fichaDaOrdemProvider(ordem.fichaTecnicaId).future,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TestesQualidadeDetalheView(
                          teste: t,
                          indice: i + 1,
                          ficha: ficha,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: !podeRegistrar
          ? null
          : fichaAsync.maybeWhen(
              data: (ficha) => FloatingActionButton(
                onPressed: () => _abrirNovoTeste(context, ref, ficha),
                child: const Icon(Icons.add),
              ),
              orElse: () => null,
            ),
    );
  }

  String _dataExibicao(DateTime data) {
    final agora = DateTime.now();
    final hoje =
        agora.year == data.year &&
        agora.month == data.month &&
        agora.day == data.day;
    final hora =
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
    if (hoje) return 'Hoje, $hora';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}, $hora';
  }

  Future<void> _abrirNovoTeste(
    BuildContext context,
    WidgetRef ref,
    FichaTecnica ficha,
  ) async {
    final controllers = {
      for (final campo in camposTeste) campo: TextEditingController(),
    };
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Map<String, double?> lerValores() => {
            for (final campo in camposTeste)
              campo: double.tryParse(
                controllers[campo]!.text.replaceAll(',', '.'),
              ),
          };

          return AlertDialog(
            title: Text('Novo teste · OP ${ordem.numeroOp}'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final campo in camposTeste)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CampoTesteEditavel(
                          campo: campo,
                          controller: controllers[campo]!,
                          ficha: ficha,
                          valores: lerValores(),
                          onChanged: () => setState(() {}),
                        ),
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
                        setState(() => salvando = true);
                        final valores = lerValores();
                        final usuarioId =
                            ref.read(authControllerProvider).usuario!.id;
                        await ref
                            .read(qualidadeRepositoryProvider)
                            .registrarTeste(
                              ordemProducaoId: ordem.id,
                              registradoPor: usuarioId,
                              gramaturaMedida: valores['gramatura'],
                              colunaMedida: valores['coluna'],
                              cobbInternoMedido: valores['cobbInterno'],
                              cobbExternoMedido: valores['cobbExterno'],
                              mullenMedido: valores['mullen'],
                              compressaoMedida: valores['compressao'],
                              resinaInternaMedida: valores['resinaInterna'],
                              resinaExternaMedida: valores['resinaExterna'],
                            );
                        ref.invalidate(_testesDaOrdemProvider(ordem.id));
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

/// Campo do formulário de registro: valor medido editável + selo que
/// atualiza ao vivo conforme o operador digita, comparando com o alvo/faixa
/// da FT da OP.
class _CampoTesteEditavel extends StatelessWidget {
  final String campo;
  final TextEditingController controller;
  final FichaTecnica ficha;
  final Map<String, double?> valores;
  final VoidCallback onChanged;

  const _CampoTesteEditavel({
    required this.campo,
    required this.controller,
    required this.ficha,
    required this.valores,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final avaliados = avaliarTeste(ficha, testeParaAvaliar(valores));
    final avaliado = avaliados[camposTeste.indexOf(campo)];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CampoRotulado(
            rotulo: rotulosCampoTeste[campo]!,
            controller: controller,
            hint: 'Opcional',
            helperText: avaliado.alvoTexto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: SeloAprovacao(avaliado.resultado),
        ),
      ],
    );
  }
}
