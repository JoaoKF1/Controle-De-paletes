import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../auth/controller/auth_controller.dart';
import 'ordem_detalhe_conversao_view.dart';

/// Tela operacional da Conversão: só OPs 802 que a Onduladeira já começou
/// a produzir e ainda não foram concluídas — mesmo padrão de "sem
/// poluição" da tela da Onduladeira (ver plano técnico, seção 9.2).
final _ordensDisponiveisProvider = FutureProvider.autoDispose<List<OrdemProducaoInfo>>((ref) {
  return ref.watch(paletesRepositoryProvider).listarOrdensDisponiveisConversao();
});

class OrdensDisponiveisView extends ConsumerWidget {
  const OrdensDisponiveisView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final ordensAsync = ref.watch(_ordensDisponiveisProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario?.nome ?? 'Ordens disponíveis'),
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
            return const Center(child: Text('Nenhuma OP disponível pra Conversão ainda.'));
          }
          return ListView.separated(
            itemCount: ordens.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final op = ordens[i];
              return ListTile(
                title: Text(op.numeroOp),
                subtitle: Text('${op.clienteNome} · FT ${op.codigoFt}'),
                trailing: Text('${op.quantidadePedida}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrdemDetalheConversaoView(ordem: op)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
