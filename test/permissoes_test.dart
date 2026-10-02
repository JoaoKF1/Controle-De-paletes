import 'package:controle_paletes/domain/services/permissoes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matriz combinada com a gestão (ver plano técnico, 2) — se algum desses
/// testes quebrar, é mudança de regra de acesso, não só de código.
void main() {
  Map<String, bool> mapa(Permissoes p) => {
    'verFichasTecnicas': p.verFichasTecnicas,
    'editarFichasTecnicas': p.editarFichasTecnicas,
    'verOrdensProducao': p.verOrdensProducao,
    'criarOrdensProducao': p.criarOrdensProducao,
    'verUsuarios': p.verUsuarios,
    'verOrdensOnduladeira': p.verOrdensOnduladeira,
    'verOrdensConversao': p.verOrdensConversao,
    'verFilaAnalise': p.verFilaAnalise,
    'verTestesQualidade': p.verTestesQualidade,
    'verDashboard': p.verDashboard,
    'verSincronizacao': p.verSincronizacao,
    'apontarOnduladeira': p.apontarOnduladeira,
    'apontarConversao': p.apontarConversao,
    'resolverOcorrencia': p.resolverOcorrencia,
  };

  test('admin vê e faz tudo', () {
    expect(mapa(const Permissoes('admin')).values, everyElement(isTrue));
  });

  test('onduladeira', () {
    expect(mapa(const Permissoes('onduladeira')), {
      'verFichasTecnicas': true,
      'editarFichasTecnicas': false,
      'verOrdensProducao': true,
      'criarOrdensProducao': true,
      'verUsuarios': false,
      'verOrdensOnduladeira': true,
      'verOrdensConversao': true,
      'verFilaAnalise': true,
      'verTestesQualidade': false,
      'verDashboard': false,
      'verSincronizacao': false,
      'apontarOnduladeira': true,
      'apontarConversao': false,
      'resolverOcorrencia': false,
    });
  });

  test('conversao', () {
    expect(mapa(const Permissoes('conversao')), {
      'verFichasTecnicas': true,
      'editarFichasTecnicas': false,
      'verOrdensProducao': true,
      'criarOrdensProducao': false,
      'verUsuarios': false,
      'verOrdensOnduladeira': true,
      'verOrdensConversao': true,
      'verFilaAnalise': false,
      'verTestesQualidade': false,
      'verDashboard': false,
      'verSincronizacao': false,
      'apontarOnduladeira': false,
      'apontarConversao': true,
      'resolverOcorrencia': false,
    });
  });

  test('qualidade', () {
    expect(mapa(const Permissoes('qualidade')), {
      'verFichasTecnicas': false,
      'editarFichasTecnicas': false,
      'verOrdensProducao': false,
      'criarOrdensProducao': false,
      'verUsuarios': false,
      'verOrdensOnduladeira': true,
      'verOrdensConversao': true,
      'verFilaAnalise': true,
      'verTestesQualidade': true,
      'verDashboard': false,
      'verSincronizacao': false,
      'apontarOnduladeira': false,
      'apontarConversao': false,
      'resolverOcorrencia': true,
    });
  });

  test('perfil desconhecido não vê nada', () {
    expect(mapa(const Permissoes('outro')).values, everyElement(isFalse));
  });
}
