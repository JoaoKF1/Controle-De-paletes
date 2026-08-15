/// Produção somada de um dia, separada por setor — pra o gráfico de
/// tendência do dashboard (ver plano técnico, seção de relatórios).
class ProducaoDia {
  final DateTime dia;
  final int onduladeira;
  final int conversao;

  const ProducaoDia({required this.dia, required this.onduladeira, required this.conversao});
}

/// Total de refugo somado por motivo — todos os lançamentos, manuais e os
/// automáticos vindos de reprovação/exclusão (ver plano técnico, 9.3).
class RefugoPorMotivo {
  final String motivo;
  final int quantidade;

  const RefugoPorMotivo({required this.motivo, required this.quantidade});
}

class ResumoDashboard {
  final int opsAbertas;
  final int opsConcluidas;
  final int ocorrenciasEmAnalise;

  const ResumoDashboard({
    required this.opsAbertas,
    required this.opsConcluidas,
    required this.ocorrenciasEmAnalise,
  });
}
