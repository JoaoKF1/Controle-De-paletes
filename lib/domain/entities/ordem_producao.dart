class OrdemProducao {
  final String id;
  final String numeroOp;
  final String fichaTecnicaId;
  final int quantidadePedida;
  final DateTime dataPedido;
  final String status;

  /// Espessura real da chapa, medida pela Onduladeira no cadastro da OP —
  /// é ela que entra no cálculo de quantidade do palete (ver plano técnico,
  /// 9.1). Travada no banco depois do primeiro palete apontado.
  final double espessuraMedidaMm;

  const OrdemProducao({
    required this.id,
    required this.numeroOp,
    required this.fichaTecnicaId,
    required this.quantidadePedida,
    required this.dataPedido,
    required this.status,
    required this.espessuraMedidaMm,
  });

  factory OrdemProducao.fromMap(Map<String, dynamic> map) => OrdemProducao(
    id: map['id'] as String,
    numeroOp: map['numero_op'] as String,
    fichaTecnicaId: map['ficha_tecnica_id'] as String,
    quantidadePedida: map['quantidade_pedida'] as int,
    dataPedido: DateTime.parse(map['data_pedido'] as String).toLocal(),
    status: map['status'] as String? ?? 'aberta',
    espessuraMedidaMm: (map['espessura_medida_mm'] as num).toDouble(),
  );

  Map<String, dynamic> toInsertMap() => {
    'numero_op': numeroOp,
    'ficha_tecnica_id': fichaTecnicaId,
    'quantidade_pedida': quantidadePedida,
    'data_pedido': dataPedido.toIso8601String().split('T').first,
    'espessura_medida_mm': espessuraMedidaMm,
  };

  /// `quantidade_pedida` é sempre o total do produto final: numa OP 803
  /// isso já é chapa (não passa pela Conversão); numa 802 é caixa (ver
  /// plano técnico, 9.1).
  String get unidadePedido => numeroOp.startsWith('803') ? 'chapas' : 'caixas';
}
