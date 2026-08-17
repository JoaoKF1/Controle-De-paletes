class OrdemProducao {
  final String id;
  final String numeroOp;
  final String fichaTecnicaId;
  final int quantidadePedida;
  final DateTime dataPedido;
  final String status;

  const OrdemProducao({
    required this.id,
    required this.numeroOp,
    required this.fichaTecnicaId,
    required this.quantidadePedida,
    required this.dataPedido,
    required this.status,
  });

  factory OrdemProducao.fromMap(Map<String, dynamic> map) => OrdemProducao(
    id: map['id'] as String,
    numeroOp: map['numero_op'] as String,
    fichaTecnicaId: map['ficha_tecnica_id'] as String,
    quantidadePedida: map['quantidade_pedida'] as int,
    dataPedido: DateTime.parse(map['data_pedido'] as String).toLocal(),
    status: map['status'] as String? ?? 'aberta',
  );

  Map<String, dynamic> toInsertMap() => {
    'numero_op': numeroOp,
    'ficha_tecnica_id': fichaTecnicaId,
    'quantidade_pedida': quantidadePedida,
    'data_pedido': dataPedido.toIso8601String().split('T').first,
  };

  /// `quantidade_pedida` é sempre o total do produto final: numa OP 803
  /// isso já é chapa (não passa pela Conversão); numa 802 é caixa (ver
  /// plano técnico, 9.1).
  String get unidadePedido => numeroOp.startsWith('803') ? 'chapas' : 'caixas';
}
