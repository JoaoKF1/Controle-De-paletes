/// Cálculo de quantidade de chapas da Onduladeira em aritmética inteira
/// exata — nunca em ponto flutuante (ver plano técnico, 9.1).
///
/// Por que: `double` não representa a maioria dos decimais exatamente
/// (4,35 vira 4,3499…), e a fórmula arredonda **pra baixo**. Exemplo real:
/// altura 1037,59 mm, espessura 2,54, QP 2 dá exatamente 817 chapas, mas
/// em `double` sai 816,99999… → 816 — uma chapa a menos por causa do
/// arredondamento binário (ver test/calculo_palete_test.dart). Aqui todo valor em mm é
/// convertido pra **centésimos de mm** (inteiro) antes da conta; como
/// altura e espessura são medidas com no máximo 2 casas decimais, a
/// conversão é exata e a divisão inteira dá o `floor` correto sempre.
library;

/// Casas decimais aceitas pra altura e espessura (precisão da medição na
/// fábrica).
const casasDecimaisMedida = 2;

/// Lê um número digitado (`"3,85"`, `"3.85"`, `"1200"`) direto em
/// centésimos de mm, sem passar por `double`. Retorna `null` se não for um
/// número positivo válido ou tiver mais de 2 casas decimais.
int? lerCentesimos(String? texto) {
  final limpo = (texto ?? '').trim().replaceAll(',', '.');
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(limpo);
  if (match == null) return null;
  final inteiro = int.parse(match.group(1)!);
  final fracao = (match.group(2) ?? '').padRight(2, '0');
  final valor = inteiro * 100 + int.parse(fracao);
  return valor > 0 ? valor : null;
}

/// Converte um valor que já veio do banco (`numeric(6,2)` chega como
/// `double` no JSON) pra centésimos. `round` corrige o erro binário de
/// representação (3,85 × 100 = 384,99999…) — seguro porque o banco nunca
/// guarda mais de 2 casas.
int paraCentesimos(double valorMm) => (valorMm * 100).round();

/// Volta de centésimos pra mm, só pra gravar/exibir — nunca usar o
/// resultado pra calcular quantidade.
double deCentesimos(int centesimos) => centesimos / 100;

/// `floor((altura ÷ espessura) × qp_padrao)`, exato. Reordenado como
/// `(altura × qp) ÷ espessura` em inteiros: mesma conta, sem perda.
int quantidadeChapasOnduladeira({
  required int alturaCentesimos,
  required int espessuraCentesimos,
  required int qpPadrao,
}) {
  if (espessuraCentesimos <= 0) {
    throw ArgumentError.value(espessuraCentesimos, 'espessura', 'deve ser > 0');
  }
  return (alturaCentesimos * qpPadrao) ~/ espessuraCentesimos;
}

/// Limite do aviso de espessura medida muito diferente da esperada na FT.
const limiteDivergenciaEspessuraPercentual = 10;

/// `true` se a espessura medida diferir da esperada em **mais** de 10%
/// (exatamente 10% não avisa). Comparação em inteiros:
/// `|medida − esperada| × 100 > esperada × 10`.
bool espessuraDiverge({
  required int medidaCentesimos,
  required int esperadaCentesimos,
}) {
  final diferenca = (medidaCentesimos - esperadaCentesimos).abs();
  return diferenca * 100 >
      esperadaCentesimos * limiteDivergenciaEspessuraPercentual;
}

/// Formata centésimos como `"3,85"` (sempre 2 casas, vírgula decimal).
String formatarMm(int centesimos) {
  final inteiro = centesimos ~/ 100;
  final fracao = (centesimos % 100).toString().padLeft(2, '0');
  return '$inteiro,$fracao';
}
