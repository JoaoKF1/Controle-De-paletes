import '../entities/ficha_tecnica.dart';
import '../entities/teste_qualidade.dart';

/// Selo de um campo do teste: `neutro` quando não dá pra comparar (campo
/// não medido nesse teste, ou sem alvo/faixa cadastrado na FT) — nunca um
/// selo único pro teste inteiro, cada campo mostra o seu (ver plano
/// técnico, 9.6).
enum ResultadoCampo { neutro, aprovado, reprovado }

/// Um campo de qualidade já avaliado, pronto pra exibir: rótulo, valor
/// medido (null se não preenchido), o alvo/faixa da FT em texto e o
/// resultado da comparação.
class CampoAvaliado {
  final String label;
  final double? medido;
  final String alvoTexto;
  final ResultadoCampo resultado;

  const CampoAvaliado({
    required this.label,
    required this.medido,
    required this.alvoTexto,
    required this.resultado,
  });
}

/// Tolerância fixa aplicada aos campos de valor único (Gramatura, Coluna,
/// Mullen, Compressão) — 5% pros 4, por enquanto sem tolerância própria por
/// campo. Cobb e Resina não usam tolerância: a FT já cadastra a faixa
/// (mín/máx) direto, porque na fábrica os dois sempre trabalham em faixa,
/// nunca em valor único (ver plano técnico, 9.6).
const toleranciaPadrao = 0.05;

/// Monta os 8 campos do teste já avaliados contra a FT da OP — usado tanto
/// no formulário de registro (feedback ao vivo enquanto digita) quanto na
/// tela de detalhe de um teste já salvo.
List<CampoAvaliado> avaliarTeste(FichaTecnica ft, TesteQualidade teste) => [
  _porTolerancia('Gramatura', teste.gramaturaMedida, ft.gramatura),
  _porTolerancia('Coluna', teste.colunaMedida, ft.coluna),
  _porFaixa(
    'Cobb interno',
    teste.cobbInternoMedido,
    ft.cobbInternoMin,
    ft.cobbInternoMax,
  ),
  _porFaixa(
    'Cobb externo',
    teste.cobbExternoMedido,
    ft.cobbExternoMin,
    ft.cobbExternoMax,
  ),
  _porTolerancia('Mullen', teste.mullenMedido, ft.mullen),
  _porTolerancia('Compressão', teste.compressaoMedida, ft.compressao),
  _porFaixa(
    'Resina interna',
    teste.resinaInternaMedida,
    ft.resinaInternaMin,
    ft.resinaInternaMax,
  ),
  _porFaixa(
    'Resina externa',
    teste.resinaExternaMedida,
    ft.resinaExternaMin,
    ft.resinaExternaMax,
  ),
];

CampoAvaliado _porTolerancia(String label, double? medido, double? alvo) {
  if (alvo == null) {
    return CampoAvaliado(
      label: label,
      medido: medido,
      alvoTexto: 'sem alvo cadastrado',
      resultado: ResultadoCampo.neutro,
    );
  }
  final alvoTexto = 'alvo ${_fmt(alvo)}';
  if (medido == null) {
    return CampoAvaliado(
      label: label,
      medido: null,
      alvoTexto: alvoTexto,
      resultado: ResultadoCampo.neutro,
    );
  }
  final min = alvo * (1 - toleranciaPadrao);
  final max = alvo * (1 + toleranciaPadrao);
  return CampoAvaliado(
    label: label,
    medido: medido,
    alvoTexto: alvoTexto,
    resultado: (medido >= min && medido <= max)
        ? ResultadoCampo.aprovado
        : ResultadoCampo.reprovado,
  );
}

CampoAvaliado _porFaixa(String label, double? medido, double? min, double? max) {
  if (min == null || max == null) {
    return CampoAvaliado(
      label: label,
      medido: medido,
      alvoTexto: 'sem faixa cadastrada',
      resultado: ResultadoCampo.neutro,
    );
  }
  final alvoTexto = 'faixa ${_fmt(min)}-${_fmt(max)}';
  if (medido == null) {
    return CampoAvaliado(
      label: label,
      medido: null,
      alvoTexto: alvoTexto,
      resultado: ResultadoCampo.neutro,
    );
  }
  return CampoAvaliado(
    label: label,
    medido: medido,
    alvoTexto: alvoTexto,
    resultado: (medido >= min && medido <= max)
        ? ResultadoCampo.aprovado
        : ResultadoCampo.reprovado,
  );
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
