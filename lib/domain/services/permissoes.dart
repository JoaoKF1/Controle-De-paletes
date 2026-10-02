/// O que cada perfil vê e faz no app — fonte única pra home e pras telas
/// (ver plano técnico, 2). Esconder botão é só UX: quem garante de verdade
/// é o RLS do banco, que segue a mesma matriz.
///
/// | Tela / ação                    | admin | onduladeira | conversao | qualidade |
/// |--------------------------------|:-----:|:-----------:|:---------:|:---------:|
/// | Fichas técnicas (consulta)     |   ✓   |      ✓      |     ✓     |           |
/// | Fichas técnicas (criar/editar) |   ✓   |             |           |           |
/// | Ordens de produção (consulta)  |   ✓   |      ✓      |     ✓     |           |
/// | Ordens de produção (criar)     |   ✓   |      ✓      |           |           |
/// | Usuários                       |   ✓   |             |           |           |
/// | Ordens em aberto (Onduladeira) |   ✓   |      ✓      |     ✓     |     ✓     |
/// | Ordens disponíveis (Conversão) |   ✓   |      ✓      |     ✓     |     ✓     |
/// | Fila de análise (consulta)     |   ✓   |      ✓      |           |     ✓     |
/// | Resolver ocorrência            |   ✓   |             |           |     ✓     |
/// | Testes de qualidade            |   ✓   |             |           |     ✓     |
/// | Dashboard / Sincronização      |   ✓   |             |           |           |
///
/// Ver a tela de outro setor é só consulta: apontar palete, lançar refugo
/// e encerrar a OP continuam restritos ao setor dono (+ admin).
library;

class Permissoes {
  final String perfil;
  const Permissoes(this.perfil);

  bool get _admin => perfil == 'admin';
  bool get _onduladeira => perfil == 'onduladeira';
  bool get _conversao => perfil == 'conversao';
  bool get _qualidade => perfil == 'qualidade';

  // Home — Cadastros
  bool get verFichasTecnicas => _admin || _onduladeira || _conversao;
  bool get editarFichasTecnicas => _admin;
  bool get verOrdensProducao => _admin || _onduladeira || _conversao;
  bool get criarOrdensProducao => _admin || _onduladeira;
  bool get verUsuarios => _admin;

  // Home — Operacional
  bool get verOrdensOnduladeira =>
      _admin || _onduladeira || _conversao || _qualidade;
  bool get verOrdensConversao =>
      _admin || _onduladeira || _conversao || _qualidade;
  bool get verFilaAnalise => _admin || _onduladeira || _qualidade;
  bool get verTestesQualidade => _admin || _qualidade;

  // Home — Gestão
  bool get verDashboard => _admin;
  bool get verSincronizacao => _admin;

  // Ações dentro das telas operacionais
  bool get apontarOnduladeira => _admin || _onduladeira;
  bool get apontarConversao => _admin || _conversao;
  bool get resolverOcorrencia => _admin || _qualidade;
}
