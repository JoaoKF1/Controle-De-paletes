import 'package:flutter/material.dart';

/// Peças visuais compartilhadas pelos formulários de apontamento e pelas
/// telas de OP — mesma linguagem em todo o app: rótulo discreto acima de
/// cada campo, cartão de destaque com barra de progresso, cartão central
/// pro resultado calculado, botão de ação principal de alto contraste, e
/// um wrapper de largura máxima pra formulários ficarem confortáveis tanto
/// no celular quanto no desktop.

/// Rótulo pequeno e discreto usado acima de cada campo/seção.
class RotuloSecao extends StatelessWidget {
  final String texto;
  const RotuloSecao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Rótulo de seção em caixa alta — separa blocos dentro de uma tela ou
/// formulário mais longo (ex.: seções da home de Cadastros, "Qualidade" e
/// "Paletização" no formulário de Ficha Técnica). Mais forte que
/// `RotuloSecao`, que é só o rótulo de um campo individual.
class RotuloSecaoMaiuscula extends StatelessWidget {
  final String texto;
  const RotuloSecaoMaiuscula(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Campo de texto com `RotuloSecao` acima e hint dentro — o padrão de
/// formulário usado em toda tela de cadastro do app, no lugar do label
/// flutuante padrão do Material.
class CampoRotulado extends StatelessWidget {
  final String rotulo;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final String? helperText;

  const CampoRotulado({
    super.key,
    required this.rotulo,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RotuloSecao(rotulo),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint, helperText: helperText),
          validator: validator,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
        ),
      ],
    );
  }
}

/// Dropdown com `RotuloSecao` acima — mesmo padrão do `CampoRotulado`,
/// pra selects em formulários de cadastro (Cliente, Composição, Ficha
/// Técnica etc.).
class DropdownRotulado extends StatelessWidget {
  final String rotulo;
  final String? valor;
  final List<DropdownMenuItem<String>> itens;
  final ValueChanged<String?> onChanged;

  const DropdownRotulado({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.itens,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RotuloSecao(rotulo),
        DropdownButtonFormField<String>(
          initialValue: valor,
          items: itens,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Duas colunas de mesma largura lado a lado — pra pares de campos
/// relacionados num formulário (ex.: Comprimento/Largura, QP padrão/
/// Referência).
Widget linhaDupla(Widget a, Widget b) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(child: a),
    const SizedBox(width: 12),
    Expanded(child: b),
  ],
);

/// Validador padrão pra campo numérico obrigatório e maior que zero
/// (aceita vírgula como separador decimal).
String? validarNumeroPositivo(String? v) {
  final valor = double.tryParse((v ?? '').replaceAll(',', '.'));
  if (valor == null || valor <= 0) return 'Obrigatório';
  return null;
}

/// Cartão neutro com uma ou mais linhas de rótulo+valor — usado tanto pra
/// mostrar dados de referência (Cliente, Composição, Medida, QP padrão)
/// quanto pra uma linha avulsa (ex.: "Próximo palete desta OP"). Sem o tom
/// azul do CartaoProgresso/CartaoResultado porque essa informação é só
/// consulta, não é o destaque da tela.
class CartaoInfo extends StatelessWidget {
  final Map<String, String> linhas;

  const CartaoInfo({super.key, required this.linhas});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (final entrada in linhas.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entrada.key,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      entrada.value,
                      textAlign: TextAlign.right,
                      style: textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Cartão de destaque com uma métrica e, opcionalmente, uma barra de
/// progresso (produzido vs. alvo) — mesma informação mostrada do mesmo
/// jeito no formulário de apontamento e no cabeçalho do detalhe da OP.
class CartaoProgresso extends StatelessWidget {
  final String rotulo;
  final String valor;
  final double? progresso;
  final VoidCallback? onTap;

  const CartaoProgresso({
    super.key,
    required this.rotulo,
    required this.valor,
    this.progresso,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentual = progresso == null
        ? null
        : (progresso!.clamp(0, 1) * 100).round();
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rotulo,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colorScheme.primary),
                        ),
                        if (percentual != null)
                          Text(
                            '$percentual%',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (progresso != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progresso!.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão central com o resultado calculado — mesmo tom do CartaoProgresso,
/// mas sem barra, focado só no número final antes de confirmar.
class CartaoResultado extends StatelessWidget {
  final String rotulo;
  final String valor;

  const CartaoResultado({super.key, required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            rotulo,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão de ação principal, full-width e de alto contraste — sempre a
/// última coisa na tela, deixando óbvio qual é a ação que fecha o
/// formulário.
class BotaoAcaoPrincipal extends StatelessWidget {
  final String texto;
  final IconData icone;
  final VoidCallback? onPressed;
  final bool carregando;

  const BotaoAcaoPrincipal({
    super.key,
    required this.texto,
    required this.icone,
    required this.onPressed,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: carregando ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.inverseSurface,
          foregroundColor: colorScheme.onInverseSurface,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: carregando
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onInverseSurface,
                ),
              )
            : Icon(icone),
        label: Text(texto),
      ),
    );
  }
}

/// Largura máxima confortável em telas largas (desktop) — em telas
/// estreitas (celular) ocupa a largura toda normalmente. 480 serve bem
/// formulários e listas de uma coluna; telas em grade (ex.: home de
/// Cadastros) passam um `maxWidth` maior pra caber mais colunas.
class LarguraFormulario extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const LarguraFormulario({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Linha de lista em formato de cartão arredondado — usada nas listas de
/// OP e de paletes pra manter o mesmo acabamento visual em vez do
/// ListTile "cru" direto no Scaffold.
class CartaoLista extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  // 0..1, opcional — uma barra fina embaixo do conteúdo, pra prévia de
  // progresso nas listas de OP sem precisar abrir o detalhe.
  final double? progresso;

  const CartaoLista({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.progresso,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: leading,
              title: title,
              subtitle: subtitle,
              trailing: trailing,
            ),
            if (progresso != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresso!.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
