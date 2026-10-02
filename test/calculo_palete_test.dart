import 'package:controle_paletes/domain/services/calculo_palete.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lerCentesimos', () {
    test('aceita vírgula, ponto e inteiro', () {
      expect(lerCentesimos('3,85'), 385);
      expect(lerCentesimos('3.85'), 385);
      expect(lerCentesimos('3,8'), 380);
      expect(lerCentesimos('1200'), 120000);
      expect(lerCentesimos(' 4,1 '), 410);
    });

    test('rejeita mais de 2 casas, zero, negativo e lixo', () {
      expect(lerCentesimos('3,856'), isNull);
      expect(lerCentesimos('0'), isNull);
      expect(lerCentesimos('0,00'), isNull);
      expect(lerCentesimos('-3'), isNull);
      expect(lerCentesimos('abc'), isNull);
      expect(lerCentesimos(''), isNull);
      expect(lerCentesimos(null), isNull);
      expect(lerCentesimos('1.200,5'), isNull);
    });
  });

  group('paraCentesimos', () {
    test('corrige erro binário de valores vindos do banco', () {
      // 4.35 * 100 == 434.99999999999994 em double
      expect(4.35 * 100, lessThan(435));
      expect(paraCentesimos(4.35), 435);
      expect(paraCentesimos(0.29), 29);
      expect(paraCentesimos(3.85), 385);
      expect(paraCentesimos(1.1), 110);
      expect(paraCentesimos(1200), 120000);
    });
  });

  group('quantidadeChapasOnduladeira', () {
    test('casos em que a fórmula antiga em double perdia 1 chapa', () {
      // 1037,59 × 2 ÷ 2,54 = 817 exatos, mas em double dá 816,99999…
      // (encontrado por força bruta sobre a fórmula antiga).
      expect(((1037.59 / 2.54) * 2).floor(), 816);
      expect(
        quantidadeChapasOnduladeira(
          alturaCentesimos: lerCentesimos('1037,59')!,
          espessuraCentesimos: lerCentesimos('2,54')!,
          qpPadrao: 2,
        ),
        817,
      );
      expect(((1055.37 / 2.54) * 4).floor(), 1661);
      expect(
        quantidadeChapasOnduladeira(
          alturaCentesimos: lerCentesimos('1055,37')!,
          espessuraCentesimos: lerCentesimos('2,54')!,
          qpPadrao: 4,
        ),
        1662,
      );
    });

    test('caso real: 1200 mm, espessura 3,85, QP 4', () {
      // 1200 / 3.85 = 311.688… × 4 = 1246.75 → 1246
      expect(
        quantidadeChapasOnduladeira(
          alturaCentesimos: 120000,
          espessuraCentesimos: 385,
          qpPadrao: 4,
        ),
        1246,
      );
    });

    test('conta exata não perde a última chapa', () {
      // 1155 / 3.85 = 300 exatos × 2 = 600
      expect(
        quantidadeChapasOnduladeira(
          alturaCentesimos: 115500,
          espessuraCentesimos: 385,
          qpPadrao: 2,
        ),
        600,
      );
    });

    test('espessura zero é erro, nunca divide', () {
      expect(
        () => quantidadeChapasOnduladeira(
          alturaCentesimos: 100,
          espessuraCentesimos: 0,
          qpPadrao: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('espessuraDiverge', () {
    test('avisa só acima de 10%', () {
      // esperada 4,00: 4,40 é exatamente 10% → não avisa; 4,41 avisa.
      expect(
        espessuraDiverge(medidaCentesimos: 440, esperadaCentesimos: 400),
        isFalse,
      );
      expect(
        espessuraDiverge(medidaCentesimos: 441, esperadaCentesimos: 400),
        isTrue,
      );
      expect(
        espessuraDiverge(medidaCentesimos: 360, esperadaCentesimos: 400),
        isFalse,
      );
      expect(
        espessuraDiverge(medidaCentesimos: 359, esperadaCentesimos: 400),
        isTrue,
      );
    });
  });

  test('formatarMm', () {
    expect(formatarMm(385), '3,85');
    expect(formatarMm(380), '3,80');
    expect(formatarMm(5), '0,05');
  });
}
