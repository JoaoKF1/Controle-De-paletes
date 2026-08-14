/// Espelha a tabela `paletes`. `quantidade_calculada` nunca é digitada pelo
/// usuário — é sempre derivada de `altura_medida_mm` na hora do apontamento.
class Palete {
  final String id;
  final String ordemProducaoId;
  final int numeroSequencial;
  final double alturaMedidaMm;
  final int quantidadeCalculada;
  final String tipoChapa;
  final String setorOrigem;
  final String? codigoBarras;
  final String responsavelId;
  final DateTime dataHora;

  const Palete({
    required this.id,
    required this.ordemProducaoId,
    required this.numeroSequencial,
    required this.alturaMedidaMm,
    required this.quantidadeCalculada,
    required this.tipoChapa,
    required this.setorOrigem,
    this.codigoBarras,
    required this.responsavelId,
    required this.dataHora,
  });

  factory Palete.fromMap(Map<String, dynamic> map) => Palete(
        id: map['id'] as String,
        ordemProducaoId: map['ordem_producao_id'] as String,
        numeroSequencial: map['numero_sequencial'] as int,
        alturaMedidaMm: (map['altura_medida_mm'] as num).toDouble(),
        quantidadeCalculada: map['quantidade_calculada'] as int,
        tipoChapa: map['tipo_chapa'] as String,
        setorOrigem: map['setor_origem'] as String,
        codigoBarras: map['codigo_barras'] as String?,
        responsavelId: map['responsavel_id'] as String,
        dataHora: DateTime.parse(map['data_hora'] as String),
      );
}

/// Ordem de produção com os dados de Cliente, Ficha Técnica e Composição
/// já embutidos (join único via PostgREST) — evita N+1 pra montar as telas
/// de apontamento, que sempre precisam desses dados juntos.
class OrdemProducaoInfo {
  final String id;
  final String numeroOp;
  final int quantidadePedida;
  final DateTime dataPedido;
  final String status;
  final String codigoFt;
  final int qpPadrao;
  final String clienteNome;
  final double composicaoEspessuraMm;

  const OrdemProducaoInfo({
    required this.id,
    required this.numeroOp,
    required this.quantidadePedida,
    required this.dataPedido,
    required this.status,
    required this.codigoFt,
    required this.qpPadrao,
    required this.clienteNome,
    required this.composicaoEspessuraMm,
  });

  /// Regra de negócio: OP que começa com 803 é chapa elaborada, com 802 é
  /// semi-elaborada. Não existe seleção manual — o tipo vem sempre do
  /// prefixo do número da OP.
  String get tipoChapa => numeroOp.startsWith('803') ? 'elaborado' : 'semi_elaborado';

  factory OrdemProducaoInfo.fromMap(Map<String, dynamic> map) {
    final ft = map['fichas_tecnicas'] as Map<String, dynamic>;
    final cliente = ft['clientes'] as Map<String, dynamic>;
    final composicao = ft['composicoes'] as Map<String, dynamic>;
    return OrdemProducaoInfo(
      id: map['id'] as String,
      numeroOp: map['numero_op'] as String,
      quantidadePedida: map['quantidade_pedida'] as int,
      dataPedido: DateTime.parse(map['data_pedido'] as String),
      status: map['status'] as String,
      codigoFt: ft['codigo_ft'] as String,
      qpPadrao: ft['qp_padrao'] as int,
      clienteNome: cliente['razao_social'] as String,
      composicaoEspessuraMm: (composicao['espessura_mm'] as num).toDouble(),
    );
  }
}
