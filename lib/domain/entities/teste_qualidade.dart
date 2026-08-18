/// OP com o resumo que a tela de Testes de qualidade precisa mostrar na
/// lista — cliente, unidade e quantos testes já tem, sem carregar a FT
/// inteira nem os testes em si (isso só é buscado quando a OP é aberta).
class OrdemParaTeste {
  final String id;
  final String numeroOp;
  final String fichaTecnicaId;
  final String clienteNome;
  final String unidadePedido;
  final String status;
  final int totalTestes;

  const OrdemParaTeste({
    required this.id,
    required this.numeroOp,
    required this.fichaTecnicaId,
    required this.clienteNome,
    required this.unidadePedido,
    required this.status,
    required this.totalTestes,
  });
}

/// Teste de qualidade de uma OP (não de um palete específico — ver plano
/// técnico, 9.6): a Qualidade mede o que testou de verdade naquele lote e
/// registra aqui. Todos os 8 campos são opcionais — nem toda chapa tem,
/// por exemplo, Cobb ou Resina testado.
class TesteQualidade {
  final String id;
  final String ordemProducaoId;
  final String numeroOp;
  final String fichaTecnicaId;
  final String registradoPorNome;
  final DateTime criadoEm;
  final double? gramaturaMedida;
  final double? colunaMedida;
  final double? cobbInternoMedido;
  final double? cobbExternoMedido;
  final double? mullenMedido;
  final double? compressaoMedida;
  final double? resinaInternaMedida;
  final double? resinaExternaMedida;

  const TesteQualidade({
    required this.id,
    required this.ordemProducaoId,
    required this.numeroOp,
    required this.fichaTecnicaId,
    required this.registradoPorNome,
    required this.criadoEm,
    this.gramaturaMedida,
    this.colunaMedida,
    this.cobbInternoMedido,
    this.cobbExternoMedido,
    this.mullenMedido,
    this.compressaoMedida,
    this.resinaInternaMedida,
    this.resinaExternaMedida,
  });

  factory TesteQualidade.fromMap(Map<String, dynamic> map) {
    final ordem = map['ordens_producao'] as Map<String, dynamic>;
    final registrador = map['registrador'] as Map<String, dynamic>;
    return TesteQualidade(
      id: map['id'] as String,
      ordemProducaoId: map['ordem_producao_id'] as String,
      numeroOp: ordem['numero_op'] as String,
      fichaTecnicaId: ordem['ficha_tecnica_id'] as String,
      registradoPorNome: registrador['nome'] as String,
      criadoEm: DateTime.parse(map['criado_em'] as String).toLocal(),
      gramaturaMedida: (map['gramatura_medida'] as num?)?.toDouble(),
      colunaMedida: (map['coluna_medida'] as num?)?.toDouble(),
      cobbInternoMedido: (map['cobb_interno_medido'] as num?)?.toDouble(),
      cobbExternoMedido: (map['cobb_externo_medido'] as num?)?.toDouble(),
      mullenMedido: (map['mullen_medido'] as num?)?.toDouble(),
      compressaoMedida: (map['compressao_medida'] as num?)?.toDouble(),
      resinaInternaMedida: (map['resina_interna_medida'] as num?)?.toDouble(),
      resinaExternaMedida: (map['resina_externa_medida'] as num?)?.toDouble(),
    );
  }
}
