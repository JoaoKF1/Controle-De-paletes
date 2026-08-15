/// Ocorrência aberta sobre um palete já apontado. `status` começa em
/// `em_analise`; só a Qualidade decide `liberado`/`reprovado` — ver plano
/// técnico, seção 9.4.
class OcorrenciaQualidade {
  final String id;
  final String paleteId;
  final int quantidadeAfetada;
  final String motivo;
  final String status;
  final String abertoPor;
  final DateTime dataAbertura;

  // Contexto pra exibição — vem de join com paletes/ordens_producao.
  final int paleteNumeroSequencial;
  final String numeroOp;

  const OcorrenciaQualidade({
    required this.id,
    required this.paleteId,
    required this.quantidadeAfetada,
    required this.motivo,
    required this.status,
    required this.abertoPor,
    required this.dataAbertura,
    required this.paleteNumeroSequencial,
    required this.numeroOp,
  });

  factory OcorrenciaQualidade.fromMap(Map<String, dynamic> map) {
    final palete = map['paletes'] as Map<String, dynamic>;
    final ordem = palete['ordens_producao'] as Map<String, dynamic>;
    return OcorrenciaQualidade(
      id: map['id'] as String,
      paleteId: map['palete_id'] as String,
      quantidadeAfetada: map['quantidade_afetada'] as int,
      motivo: map['motivo'] as String,
      status: map['status'] as String,
      abertoPor: map['aberto_por'] as String,
      dataAbertura: DateTime.parse(map['data_abertura'] as String),
      paleteNumeroSequencial: palete['numero_sequencial'] as int,
      numeroOp: ordem['numero_op'] as String,
    );
  }
}
