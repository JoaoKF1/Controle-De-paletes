class FichaTecnica {
  final String id;
  final String codigoFt;
  final String clienteId;
  final String composicaoId;
  final String medidaChapa;
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

  const FichaTecnica({
    required this.id,
    required this.codigoFt,
    required this.clienteId,
    required this.composicaoId,
    required this.medidaChapa,
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
  });

  factory FichaTecnica.fromMap(Map<String, dynamic> map) => FichaTecnica(
        id: map['id'] as String,
        codigoFt: map['codigo_ft'] as String,
        clienteId: map['cliente_id'] as String,
        composicaoId: map['composicao_id'] as String,
        medidaChapa: map['medida_chapa'] as String,
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
      );

  Map<String, dynamic> toInsertMap() => {
        'codigo_ft': codigoFt,
        'cliente_id': clienteId,
        'composicao_id': composicaoId,
        'medida_chapa': medidaChapa,
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
      };
}
