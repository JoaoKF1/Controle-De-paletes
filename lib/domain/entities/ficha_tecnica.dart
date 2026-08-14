class FichaTecnica {
  final String id;
  final String codigoFt;
  final String clienteId;
  final String composicaoId;
  final String medidaChapa;
  final int qpPadrao;
  final String? referencia;
  final bool ativo;

  const FichaTecnica({
    required this.id,
    required this.codigoFt,
    required this.clienteId,
    required this.composicaoId,
    required this.medidaChapa,
    required this.qpPadrao,
    this.referencia,
    required this.ativo,
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
      );

  Map<String, dynamic> toInsertMap() => {
        'codigo_ft': codigoFt,
        'cliente_id': clienteId,
        'composicao_id': composicaoId,
        'medida_chapa': medidaChapa,
        'qp_padrao': qpPadrao,
        'referencia': referencia,
      };
}
