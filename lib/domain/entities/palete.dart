/// Espelha a tabela `paletes`. `quantidade_calculada` nunca é digitada pelo
/// usuário — é sempre derivada na hora do apontamento: de `altura_medida_mm`
/// pra Onduladeira, de `camadas` pra Conversão (ver plano técnico, 9.1).
class Palete {
  final String id;
  final String ordemProducaoId;
  final int? numeroSequencial;
  final double? alturaMedidaMm;
  final int? camadas;
  final int quantidadeCalculada;
  final String tipoChapa;
  final String setorOrigem;
  final String? codigoBarras;
  final String responsavelId;
  final DateTime dataHora;
  final int quantidadeReprovada;
  final int saldoDisponivel;
  final String? revisorNome;
  // false só pra apontamentos feitos offline, ainda na fila local
  // aguardando envio — todo palete vindo do servidor já é sincronizado por
  // definição (ver plano técnico, modo offline).
  final bool sincronizado;
  final String? erroSincronizacao;

  const Palete({
    required this.id,
    required this.ordemProducaoId,
    this.numeroSequencial,
    this.alturaMedidaMm,
    this.camadas,
    required this.quantidadeCalculada,
    required this.tipoChapa,
    required this.setorOrigem,
    this.codigoBarras,
    required this.responsavelId,
    required this.dataHora,
    required this.quantidadeReprovada,
    required this.saldoDisponivel,
    this.revisorNome,
    this.sincronizado = true,
    this.erroSincronizacao,
  });

  /// Rótulo de segregação pra exibir na lista — null se nunca foi
  /// reprovado/segregado nada. Distingue total (saldo zerado) de parcial
  /// (ainda sobrou saldo), porque as duas coisas são visualmente diferentes
  /// pra quem está lendo a lista (ver plano técnico, 9.4).
  String? get rotuloSegregacao {
    if (quantidadeReprovada == 0) return null;
    return saldoDisponivel > 0 ? 'SEGREGADO PARCIALMENTE' : 'SEGREGADO';
  }

  bool get segregado => quantidadeReprovada > 0;

  /// Texto pro número do palete — "pendente" enquanto não sincronizou,
  /// porque o número definitivo só é atribuído pelo servidor.
  String get numeroExibicao => numeroSequencial?.toString() ?? 'pendente';

  factory Palete.fromMap(Map<String, dynamic> map) => Palete(
    id: map['id'] as String,
    ordemProducaoId: map['ordem_producao_id'] as String,
    numeroSequencial: map['numero_sequencial'] as int?,
    alturaMedidaMm: (map['altura_medida_mm'] as num?)?.toDouble(),
    camadas: map['camadas'] as int?,
    quantidadeCalculada: map['quantidade_calculada'] as int,
    tipoChapa: map['tipo_chapa'] as String,
    setorOrigem: map['setor_origem'] as String,
    codigoBarras: map['codigo_barras'] as String?,
    responsavelId: map['responsavel_id'] as String,
    dataHora: DateTime.parse(map['data_hora'] as String),
    quantidadeReprovada: map['quantidade_reprovada'] as int? ?? 0,
    saldoDisponivel:
        map['saldo_disponivel'] as int? ?? map['quantidade_calculada'] as int,
    revisorNome: (map['revisor'] as Map<String, dynamic>?)?['nome'] as String?,
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
  final String composicaoCodigo;
  final double comprimentoMm;
  final double larguraMm;

  // Paletização da Conversão — só preenchido em FTs de OP 802 (ver 1).
  final int? pacotesPorCamada;
  final int? pecasPorPacote;

  // Quantas caixas saem de 1 chapa no arranjo de impressão da Conversão —
  // null trata como 1 (1 chapa = 1 caixa, comportamento anterior a esse
  // campo). Usado pra converter caixas apontadas de volta em chapas
  // consumidas no cálculo de "chapas disponíveis" (ver 9.1).
  final int? arranjo;
  int get arranjoEfetivo => arranjo ?? 1;

  // Prévia de progresso pra tela de lista (ver `listarOrdensAbertas` e
  // `listarOrdensDisponiveisConversao`), sem precisar abrir o detalhe —
  // numerador genérico (produzido pela Onduladeira, ou já consumido pela
  // Conversão) sobre um alvo que também muda por tela (`quantidadePedida`
  // na Onduladeira, chapas disponíveis na Conversão). Ambos null quando
  // não foi calculado (ex.: cache offline de uma OP nunca visitada).
  final int? progressoAtual;
  final int? progressoAlvo;

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
    required this.composicaoCodigo,
    required this.comprimentoMm,
    required this.larguraMm,
    this.pacotesPorCamada,
    this.pecasPorPacote,
    this.arranjo,
    this.progressoAtual,
    this.progressoAlvo,
  });

  OrdemProducaoInfo comProgresso({required int atual, required int alvo}) =>
      OrdemProducaoInfo(
        id: id,
        numeroOp: numeroOp,
        quantidadePedida: quantidadePedida,
        dataPedido: dataPedido,
        status: status,
        codigoFt: codigoFt,
        qpPadrao: qpPadrao,
        clienteNome: clienteNome,
        composicaoEspessuraMm: composicaoEspessuraMm,
        composicaoCodigo: composicaoCodigo,
        comprimentoMm: comprimentoMm,
        larguraMm: larguraMm,
        pacotesPorCamada: pacotesPorCamada,
        pecasPorPacote: pecasPorPacote,
        arranjo: arranjo,
        progressoAtual: atual,
        progressoAlvo: alvo,
      );

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
      composicaoCodigo: composicao['codigo'] as String,
      comprimentoMm: (ft['comprimento_mm'] as num).toDouble(),
      larguraMm: (ft['largura_mm'] as num).toDouble(),
      pacotesPorCamada: ft['pacotes_por_camada'] as int?,
      pecasPorPacote: ft['pecas_por_pacote'] as int?,
      arranjo: ft['arranjo'] as int?,
    );
  }

  /// Tipo de chapa quando é a Onduladeira quem aponta: 803 já é produto
  /// final ('elaborado', vai direto pra Expedição sem Conversão); 802
  /// ainda é intermediário ('semi_elaborado', precisa da Conversão depois).
  /// Não usar pra apontamento da Conversão — lá é sempre 'elaborado'.
  String get tipoChapaOnduladeira =>
      numeroOp.startsWith('803') ? 'elaborado' : 'semi_elaborado';

  /// "Comprimento x Largura mm" pronto pra exibir — evita repetir a
  /// formatação em cada tela que mostra a medida da chapa.
  String get medidaExibicao =>
      '${comprimentoMm.toStringAsFixed(0)} x ${larguraMm.toStringAsFixed(0)} mm';
}
