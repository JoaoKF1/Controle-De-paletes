import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/paletes_repository.dart';
import '../../../domain/entities/palete.dart';
import '../../../shared/widgets/apontamento_kit.dart';
import 'ordem_detalhe_view.dart';

enum _ModoBusca { porOp, porFt }

/// Busca detalhada, separada da tela operacional: aqui entram tanto OPs
/// abertas quanto finalizadas — quem quer isso já está atrás de um
/// histórico, não do dia a dia.
class BuscaOpView extends ConsumerStatefulWidget {
  const BuscaOpView({super.key});

  @override
  ConsumerState<BuscaOpView> createState() => _BuscaOpViewState();
}

class _BuscaOpViewState extends ConsumerState<BuscaOpView> {
  final _termoController = TextEditingController();
  _ModoBusca _modo = _ModoBusca.porOp;
  bool _buscando = false;
  String? _erro;
  List<OrdemProducaoInfo> _resultados = [];

  @override
  void dispose() {
    _termoController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final termo = _termoController.text.trim();
    if (termo.isEmpty) return;
    setState(() {
      _buscando = true;
      _erro = null;
    });
    try {
      final repo = ref.read(paletesRepositoryProvider);
      final resultados = _modo == _ModoBusca.porOp
          ? await _buscarPorOp(repo, termo)
          : await repo.buscarPorFichaTecnica(termo);
      setState(() => _resultados = resultados);
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<List<OrdemProducaoInfo>> _buscarPorOp(
    PaletesRepository repo,
    String numeroOp,
  ) async {
    final ordem = await repo.buscarPorNumeroOp(numeroOp);
    return ordem == null ? [] : [ordem];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar OP')),
      body: LarguraFormulario(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_ModoBusca>(
                segments: const [
                  ButtonSegment(value: _ModoBusca.porOp, label: Text('Por OP')),
                  ButtonSegment(value: _ModoBusca.porFt, label: Text('Por FT')),
                ],
                selected: {_modo},
                onSelectionChanged: (s) => setState(() => _modo = s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _termoController,
                      decoration: InputDecoration(
                        labelText: _modo == _ModoBusca.porOp
                            ? 'Número da OP'
                            : 'Código da FT',
                      ),
                      onSubmitted: (_) => _buscar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _buscando ? null : _buscar,
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(
                  _erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: _buscando
                    ? const Center(child: CircularProgressIndicator())
                    : _resultados.isEmpty
                    ? const Center(child: Text('Nenhum resultado ainda.'))
                    : ListView.builder(
                        itemCount: _resultados.length,
                        itemBuilder: (context, i) {
                          final op = _resultados[i];
                          return CartaoLista(
                            title: Text(op.numeroOp),
                            subtitle: Text(
                              '${op.clienteNome} · FT ${op.codigoFt} · ${op.status}',
                            ),
                            trailing: Text('${op.quantidadePedida}'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrdemDetalheView(ordem: op),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
