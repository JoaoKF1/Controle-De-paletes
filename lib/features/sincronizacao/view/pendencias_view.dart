import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/sincronizador.dart';
import '../../../shared/widgets/apontamento_kit.dart';

final _paletesPendentesProvider = StreamProvider.autoDispose<List<LocalPalete>>(
  (ref) {
    return ref.watch(appDatabaseProvider).observarPaletesPendentes();
  },
);
final _operacoesPendentesProvider =
    StreamProvider.autoDispose<List<PendingOperation>>((ref) {
      return ref.watch(appDatabaseProvider).observarOperacoesPendentes();
    });

/// Tudo que ainda não sincronizou com o servidor — apontamentos de palete
/// e a fila genérica (refugo, pedir revisão, cadastros). Atualiza sozinha
/// conforme a sincronização processa a fila (ver plano técnico, 9.12).
class PendenciasView extends ConsumerWidget {
  const PendenciasView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletesAsync = ref.watch(_paletesPendentesProvider);
    final operacoesAsync = ref.watch(_operacoesPendentesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendências de sincronização'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar agora',
            onPressed: () => ref.read(sincronizadorProvider).sincronizarTudo(),
          ),
        ],
      ),
      body: LarguraFormulario(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Apontamentos de palete',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            paletesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (erro, _) => Text('Erro: $erro'),
              data: (paletes) {
                if (paletes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhum apontamento pendente.'),
                  );
                }
                return Column(
                  children: paletes
                      .map(
                        (p) => CartaoLista(
                          leading: Icon(
                            p.erroSincronizacao != null
                                ? Icons.error_outline
                                : Icons.sync,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            '${p.setorOrigem} · quantidade ${p.quantidadeCalculada}',
                          ),
                          subtitle: Text(
                            'Criado às ${DateFormat('dd/MM HH:mm').format(p.dataHora)}'
                            '${p.erroSincronizacao != null ? '\nErro: ${p.erroSincronizacao}' : ''}',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Refugo, ocorrências e cadastros',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            operacoesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (erro, _) => Text('Erro: $erro'),
              data: (operacoes) {
                if (operacoes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhuma operação pendente.'),
                  );
                }
                return Column(
                  children: operacoes
                      .map(
                        (o) => CartaoLista(
                          leading: Icon(
                            o.erro != null ? Icons.error_outline : Icons.sync,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(o.tipo),
                          subtitle: Text(
                            'Criado às ${DateFormat('dd/MM HH:mm').format(o.criadoEm)}'
                            '${o.erro != null ? '\nErro: ${o.erro}' : ''}',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
