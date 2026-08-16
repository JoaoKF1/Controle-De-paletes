class FichaTecnica {
  final String id;
  final String codigoFt;
  final String clienteId;
  final String composicaoId;
  final double comprimentoMm;
  final double larguraMm;
  final int qpPadrao;
  final String? referencia;
  final bool ativo;

  // Especificações de qualidade do produto — próprias de cada FT, não da
  // Composição (que é compartilhada entre várias FTs). Todas opcionais.
  final double? gramatura;
  final double? coluna;
  final double? cobbInterno;
  final double? cobbExterno;
  final double? mullen;
  final double? compressao;
  final String? resinaInterna;
  final String? resinaExterna;

  // Vincos: linhas de dobra que viram a chapa plana em caixa — uma caixa
  // pode já sair vincada da Onduladeira. Até 5, todos opcionais, sem
  // ordem fixa de importância entre eles.
  final double? vinco1Mm;
  final double? vinco2Mm;
  final double? vinco3Mm;
  final double? vinco4Mm;
  final double? vinco5Mm;

  // Paletização da Conversão — só usada por OPs 802 (ver plano técnico,
  // seção 1). Ex: pacote de 30 caixas, 2 pacotes por camada, palete com
  // 14 camadas de altura.
  final int? pacotesPorCamada;
  final int? pecasPorPacote;

  // Quantas caixas saem de 1 chapa no arranjo de impressão da Conversão
  // (ex: 3 caixas menores por chapa). Nulo = trata como 1 (comportamento
  // anterior a esse campo).
  final int? arranjo;

  const FichaTecnica({
    required this.id,
    required this.codigoFt,
    required this.clienteId,
    required this.composicaoId,
    required this.comprimentoMm,
    required this.larguraMm,
    required this.qpPadrao,
    this.referencia,
    required this.ativo,
    this.gramatura,
    this.coluna,
    this.cobbInterno,
    this.cobbExterno,
    this.mullen,
    this.compressao,
    this.resinaInterna,
    this.resinaExterna,
    this.vinco1Mm,
    this.vinco2Mm,
    this.vinco3Mm,
    this.vinco4Mm,
    this.vinco5Mm,
    this.pacotesPorCamada,
    this.pecasPorPacote,
    this.arranjo,
  });

  /// "Comprimento x Largura mm" pronto pra exibir.
  String get medidaExibicao =>
      '${comprimentoMm.toStringAsFixed(0)} x ${larguraMm.toStringAsFixed(0)} mm';

  factory FichaTecnica.fromMap(Map<String, dynamic> map) => FichaTecnica(
    id: map['id'] as String,
    codigoFt: map['codigo_ft'] as String,
    clienteId: map['cliente_id'] as String,
    composicaoId: map['composicao_id'] as String,
    comprimentoMm: (map['comprimento_mm'] as num).toDouble(),
    larguraMm: (map['largura_mm'] as num).toDouble(),
    qpPadrao: map['qp_padrao'] as int,
    referencia: map['referencia'] as String?,
    ativo: map['ativo'] as bool? ?? true,
    gramatura: (map['gramatura'] as num?)?.toDouble(),
    coluna: (map['coluna'] as num?)?.toDouble(),
    cobbInterno: (map['cobb_interno'] as num?)?.toDouble(),
    cobbExterno: (map['cobb_externo'] as num?)?.toDouble(),
    mullen: (map['mullen'] as num?)?.toDouble(),
    compressao: (map['compressao'] as num?)?.toDouble(),
    resinaInterna: map['resina_interna'] as String?,
    resinaExterna: map['resina_externa'] as String?,
    vinco1Mm: (map['vinco_1_mm'] as num?)?.toDouble(),
    vinco2Mm: (map['vinco_2_mm'] as num?)?.toDouble(),
    vinco3Mm: (map['vinco_3_mm'] as num?)?.toDouble(),
    vinco4Mm: (map['vinco_4_mm'] as num?)?.toDouble(),
    vinco5Mm: (map['vinco_5_mm'] as num?)?.toDouble(),
    pacotesPorCamada: map['pacotes_por_camada'] as int?,
    pecasPorPacote: map['pecas_por_pacote'] as int?,
    arranjo: map['arranjo'] as int?,
  );

  Map<String, dynamic> toInsertMap() => {
    'codigo_ft': codigoFt,
    'cliente_id': clienteId,
    'composicao_id': composicaoId,
    'comprimento_mm': comprimentoMm,
    'largura_mm': larguraMm,
    'qp_padrao': qpPadrao,
    'referencia': referencia,
    'gramatura': gramatura,
    'coluna': coluna,
    'cobb_interno': cobbInterno,
    'cobb_externo': cobbExterno,
    'mullen': mullen,
    'compressao': compressao,
    'resina_interna': resinaInterna,
    'resina_externa': resinaExterna,
    'vinco_1_mm': vinco1Mm,
    'vinco_2_mm': vinco2Mm,
    'vinco_3_mm': vinco3Mm,
    'vinco_4_mm': vinco4Mm,
    'vinco_5_mm': vinco5Mm,
    'pacotes_por_camada': pacotesPorCamada,
    'pecas_por_pacote': pecasPorPacote,
    'arranjo': arranjo,
  };
}
