import 'package:flutter/material.dart';

import '../../../domain/entities/ficha_tecnica.dart';
import '../../../domain/entities/teste_qualidade.dart';
import '../../../domain/services/avaliacao_qualidade.dart';
import '../../../shared/widgets/apontamento_kit.dart';

/// Detalhe de um teste já registrado — mesma comparação campo a campo do
/// formulário de registro, só que somente leitura.
class TestesQualidadeDetalheView extends StatelessWidget {
  final TesteQualidade teste;
  final int indice;
  final FichaTecnica ficha;

  const TestesQualidadeDetalheView({
    super.key,
    required this.teste,
    required this.indice,
    required this.ficha,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teste $indice · OP ${teste.numeroOp}')),
      body: LarguraFormulario(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final campo in avaliarTeste(ficha, teste))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _LinhaCampoTeste(campo: campo),
              ),
            const Divider(height: 32),
            Text(
              'Registrado por ${teste.registradoPorNome} · '
              '${teste.criadoEm.day.toString().padLeft(2, '0')}/'
              '${teste.criadoEm.month.toString().padLeft(2, '0')} '
              '${teste.criadoEm.hour.toString().padLeft(2, '0')}:'
              '${teste.criadoEm.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaCampoTeste extends StatelessWidget {
  final CampoAvaliado campo;
  const _LinhaCampoTeste({required this.campo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cor = switch (campo.resultado) {
      ResultadoCampo.aprovado => Colors.green,
      ResultadoCampo.reprovado => colorScheme.error,
      ResultadoCampo.neutro => colorScheme.onSurfaceVariant,
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            campo.label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          campo.medido == null ? '—' : _fmtValor(campo.medido!),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: cor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          child: Text(
            campo.alvoTexto,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

String _fmtValor(double v) {
  var s = v.toStringAsFixed(2);
  s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}
