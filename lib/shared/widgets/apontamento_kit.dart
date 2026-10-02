import 'package:flutter/material.dart';

import '../../domain/services/avaliacao_qualidade.dart';

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
/// pra selects com poucas opções fixas (ex.: tipo de onda, perfil, turno).
/// Lista grande (ex.: Ficha Técnica) usa `CampoSelecaoComBusca`.
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

/// Campo de texto livre com sugestões do que já foi digitado antes (ex.:
/// cliente e papéis da Ficha Técnica) — mesmo visual do `CampoRotulado`.
/// Aceita qualquer valor novo; as sugestões só evitam variações de
/// grafia do mesmo nome.
class CampoComSugestao extends StatefulWidget {
  final String rotulo;
  final TextEditingController controller;
  final List<String> sugestoes;
  final String? hint;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  const CampoComSugestao({
    super.key,
    required this.rotulo,
    required this.controller,
    required this.sugestoes,
    this.hint,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  State<CampoComSugestao> createState() => _CampoComSugestaoState();
}

class _CampoComSugestaoState extends State<CampoComSugestao> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RotuloSecao(widget.rotulo),
        RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: (valor) {
            final termo = valor.text.trim().toLowerCase();
            return widget.sugestoes
                .where(
                  (s) =>
                      s.toLowerCase().contains(termo) &&
                      s.toLowerCase() != termo,
                )
                .take(8);
          },
          onSelected: (s) => widget.onChanged?.call(s),
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(hintText: widget.hint),
                validator: widget.validator,
                textCapitalization: widget.textCapitalization,
                onChanged: widget.onChanged,
                onFieldSubmitted: (_) => onSubmit(),
              ),
          optionsViewBuilder: (context, onSelected, opcoes) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  maxWidth: 360,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final opcao in opcoes)
                      ListTile(
                        dense: true,
                        title: Text(opcao),
                        onTap: () => onSelected(opcao),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Seleção de 1 item numa lista potencialmente grande (ex.: Ficha Técnica
/// no cadastro de OP) — o campo abre um diálogo com busca em vez de um
/// dropdown, que fica inutilizável com centenas de itens. Valida como
/// campo obrigatório do `Form`.
class CampoSelecaoComBusca<T> extends StatelessWidget {
  final String rotulo;
  final T? valor;
  final List<T> itens;
  final String Function(T) titulo;
  final String Function(T)? subtitulo;
  final ValueChanged<T> onSelecionado;
  final String hint;

  const CampoSelecaoComBusca({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.itens,
    required this.titulo,
    this.subtitulo,
    required this.onSelecionado,
    this.hint = 'Toque para buscar',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RotuloSecao(rotulo),
        FormField<T>(
          // Key pelo valor: o FormField guarda o próprio estado, então
          // precisa ser recriado quando a seleção muda por fora.
          key: ValueKey(valor),
          initialValue: valor,
          validator: (v) => v == null ? 'Obrigatório' : null,
          builder: (estado) => InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final escolhido = await _abrirBusca(context);
              if (escolhido != null) onSelecionado(escolhido);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: hint,
                errorText: estado.errorText,
                suffixIcon: const Icon(Icons.search),
              ),
              isEmpty: valor == null,
              child: valor == null
                  ? null
                  : Text(
                      subtitulo == null
                          ? titulo(valor as T)
                          : '${titulo(valor as T)} · ${subtitulo!(valor as T)}',
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<T?> _abrirBusca(BuildContext context) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) {
        var termo = '';
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final filtrados = itens.where((item) {
              final texto = '${titulo(item)} ${subtitulo?.call(item) ?? ''}'
                  .toLowerCase();
              return texto.contains(termo.trim().toLowerCase());
            }).toList();
            return AlertDialog(
              title: Text(rotulo),
              content: SizedBox(
                width: 420,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Buscar…',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => termo = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtrados.isEmpty
                          ? const Center(child: Text('Nada encontrado.'))
                          : ListView.builder(
                              itemCount: filtrados.length,
                              itemBuilder: (_, i) {
                                final item = filtrados[i];
                                return ListTile(
                                  title: Text(titulo(item)),
                                  subtitle: subtitulo == null
                                      ? null
                                      : Text(subtitulo!(item)),
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
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

/// Selo de aprovado/reprovado/neutro pra um campo de teste de qualidade —
/// neutro (cinza) quando o campo não foi medido ou a FT não tem alvo/faixa
/// cadastrado pra comparar, nunca um selo único pro teste inteiro (ver
/// plano técnico, 9.6).
class SeloAprovacao extends StatelessWidget {
  final ResultadoCampo resultado;
  const SeloAprovacao(this.resultado, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (cor, icone, texto) = switch (resultado) {
      ResultadoCampo.aprovado => (Colors.green, Icons.check_circle, 'Aprovado'),
      ResultadoCampo.reprovado => (
        colorScheme.error,
        Icons.cancel,
        'Reprovado',
      ),
      ResultadoCampo.neutro => (
        colorScheme.onSurfaceVariant,
        Icons.remove_circle_outline,
        '—',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 4),
          Text(
            texto,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cor,
              fontWeight: FontWeight.w600,
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
