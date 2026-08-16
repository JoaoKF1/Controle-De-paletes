import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/sincronizador.dart';

final _paletesPendentesProvider = StreamProvider.autoDispose<List<LocalPalete>>((ref) {
  return ref.watch(appDatabaseProvider).observarPaletesPendentes();
});
final _operacoesPendentesProvider = StreamProvider.autoDispose<List<PendingOperation>>((ref) {
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
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Apontamentos de palete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          paletesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (erro, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Erro: $erro')),
            data: (paletes) {
              if (paletes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum apontamento pendente.'),
                );
              }
              return Column(
                children: paletes
                    .map(
                      (p) => ListTile(
                        leading: Icon(
                          p.erroSincronizacao != null ? Icons.error_outline : Icons.sync,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text('${p.setorOrigem} · quantidade ${p.quantidadeCalculada}'),
                        subtitle: Text(
                          'Criado às ${DateFormat('dd/MM HH:mm').format(p.dataHora)}'
                          '${p.erroSincronizacao != null ? '\nErro: ${p.erroSincronizacao}' : ''}',
                        ),
                        isThreeLine: p.erroSincronizacao != null,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('Refugo, ocorrências e cadastros', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          operacoesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (erro, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Erro: $erro')),
            data: (operacoes) {
              if (operacoes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma operação pendente.'),
                );
              }
              return Column(
                children: operacoes
                    .map(
                      (o) => ListTile(
                        leading: Icon(
                          o.erro != null ? Icons.error_outline : Icons.sync,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(o.tipo),
                        subtitle: Text(
                          'Criado às ${DateFormat('dd/MM HH:mm').format(o.criadoEm)}'
                          '${o.erro != null ? '\nErro: ${o.erro}' : ''}',
                        ),
                        isThreeLine: o.erro != null,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
