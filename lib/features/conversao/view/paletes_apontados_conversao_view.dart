import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../../shared/widgets/palete_acoes.dart';

/// Histórico completo dos paletes já apontados numa OP (Onduladeira e
/// Conversão juntas) — fica atrás de um botão na tela de detalhe, pra
/// não poluir o formulário de apontamento com a lista inteira.
class PaletesApontadosConversaoView extends ConsumerWidget {
  final OrdemProducaoInfo ordem;

  const PaletesApontadosConversaoView({super.key, required this.ordem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletesAsync = ref.watch(paletesDaOrdemProvider(ordem.id));

    return Scaffold(
      appBar: AppBar(title: Text('Paletes apontados · OP ${ordem.numeroOp}')),
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

          Future<void> aoTocarPalete(Palete p) async {
            await abrirAcoesPalete(context, ref, palete: p, ordem: ordem);
            ref.invalidate(paletesDaOrdemProvider(ordem.id));
          }

          return LarguraFormulario(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SecaoPaletes(
                  titulo: 'Produzido pela Onduladeira',
                  paletes: daOnduladeira,
                  onTapPalete: aoTocarPalete,
                ),
                const SizedBox(height: 12),
                _SecaoPaletes(
                  titulo: 'Apontado pela Conversão',
                  paletes: daConversao,
                  onTapPalete: aoTocarPalete,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SecaoPaletes extends StatelessWidget {
  final String titulo;
  final List<Palete> paletes;
  final void Function(Palete)? onTapPalete;

  const _SecaoPaletes({
    required this.titulo,
    required this.paletes,
    this.onTapPalete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (paletes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum palete ainda.'),
          )
        else
          ...paletes.map((p) {
            final medida = p.setorOrigem == 'conversao'
                ? 'Camadas ${p.camadas ?? '—'}'
                : 'Altura ${p.alturaMedidaMm?.toStringAsFixed(0) ?? '—'}mm';
            final unidade = p.setorOrigem == 'conversao' ? 'caixas' : 'chapas';
            return CartaoLista(
              leading: !p.sincronizado
                  ? Icon(
                      p.erroSincronizacao != null
                          ? Icons.error_outline
                          : Icons.sync,
                      color: Theme.of(context).colorScheme.error,
                    )
                  : null,
              title: Text(
                'Palete ${p.numeroExibicao}'
                '${p.rotuloSegregacao != null ? ' · ${p.rotuloSegregacao}' : ''}',
                style: p.segregado
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              subtitle: Text(
                '$medida · Saldo ${p.saldoDisponivel}/${p.quantidadeCalculada} $unidade'
                '${p.revisorNome != null ? ' · revisado por ${p.revisorNome}' : ''}'
                '${!p.sincronizado ? ' · PENDENTE DE ENVIO' : ''}'
                '${p.erroSincronizacao != null ? ' · erro: ${p.erroSincronizacao}' : ''}',
              ),
              trailing: Text(DateFormat('dd/MM HH:mm').format(p.dataHora)),
              onTap: onTapPalete == null ? null : () => onTapPalete!(p),
            );
          }),
      ],
    );
  }
}
