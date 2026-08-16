import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../../shared/widgets/palete_acoes.dart';

/// Histórico completo dos paletes já apontados numa OP (Onduladeira) —
/// fica atrás de um botão na tela de detalhe, pra não poluir o
/// formulário de apontamento com a lista inteira.
class PaletesApontadosView extends ConsumerWidget {
  final OrdemProducaoInfo ordem;

  const PaletesApontadosView({super.key, required this.ordem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletesAsync = ref.watch(paletesDaOrdemProvider(ordem.id));

    return Scaffold(
      appBar: AppBar(title: Text('Paletes apontados · OP ${ordem.numeroOp}')),
      body: paletesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (paletes) {
          if (paletes.isEmpty) {
            return const Center(child: Text('Nenhum palete apontado ainda.'));
          }
          return LarguraFormulario(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paletes.length,
              itemBuilder: (context, i) {
                final p = paletes[i];
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
                    'Saldo ${p.saldoDisponivel}/${p.quantidadeCalculada} chapas'
                    '${p.revisorNome != null ? ' · revisado por ${p.revisorNome}' : ''}'
                    '${!p.sincronizado ? ' · PENDENTE DE ENVIO' : ''}'
                    '${p.erroSincronizacao != null ? ' · erro: ${p.erroSincronizacao}' : ''}',
                  ),
                  trailing: Text(DateFormat('dd/MM HH:mm').format(p.dataHora)),
                  onTap: () async {
                    await abrirAcoesPalete(
                      context,
                      ref,
                      palete: p,
                      ordem: ordem,
                    );
                    ref.invalidate(paletesDaOrdemProvider(ordem.id));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
