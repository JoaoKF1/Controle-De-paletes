import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import '../../auth/controller/auth_controller.dart';
import 'ordem_detalhe_view.dart';

/// Tela operacional da Onduladeira: só OPs ainda não finalizadas, pra não
/// misturar com o histórico. A busca com todas as OPs (abertas e
/// concluídas) fica centralizada em Cadastros > Ordens de Produção.
final _ordensAbertasProvider =
    FutureProvider.autoDispose<List<OrdemProducaoInfo>>((ref) {
      return ref.watch(paletesRepositoryProvider).listarOrdensAbertas();
    });

class OrdensAbertasView extends ConsumerWidget {
  const OrdensAbertasView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final ordensAsync = ref.watch(_ordensAbertasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario?.nome ?? 'Ordens em aberto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: ordensAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (ordens) {
          if (ordens.isEmpty) {
            return const Center(child: Text('Nenhuma OP em aberto.'));
          }
          return LarguraFormulario(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ordens.length,
              itemBuilder: (context, i) {
                final op = ordens[i];
                final progresso =
                    (op.progressoAtual == null || op.progressoAlvo == null)
                    ? null
                    : op.progressoAlvo == 0
                    ? 0.0
                    : op.progressoAtual! / op.progressoAlvo!;
                return CartaoLista(
                  title: Text(op.numeroOp),
                  subtitle: Text(
                    '${op.clienteNome} · FT ${op.codigoFt}'
                    '${op.progressoAtual != null ? ' · ${op.progressoAtual}/${op.progressoAlvo} chapas' : ''}',
                  ),
                  trailing: Text('${op.quantidadePedida}'),
                  progresso: progresso,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrdemDetalheView(ordem: op),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
