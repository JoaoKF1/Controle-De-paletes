/// Onda simples (B ou C) usa 3 papéis (capa/miolo/capa); onda dupla (DB ou
/// DC) usa 5 (capa/miolo/capa/miolo/capa).
const tiposOnda = ['B', 'C', 'DB', 'DC'];

class FichaTecnica {
  final String id;
  final String codigoFt;

  // Cliente e composição ficam direto na FT — não existe mais cadastro
  // próprio de Cliente/Composição (o ERP da empresa já é a fonte disso,
  // ver plano técnico, 5).
  final String clienteNome;
  final String tipoOnda;
  final List<String> papeis;

  // Espessura esperada da chapa — só referência. O cálculo do palete usa a
  // espessura **medida** na OP (ver OrdemProducao.espessuraMedidaMm).
  final double espessuraEsperadaMm;
  final double comprimentoMm;
  final double larguraMm;
  final int qpPadrao;
  final String? referencia;
  final bool ativo;

  // Especificações de qualidade do produto — próprias de cada FT, não da
  // Composição (que é compartilhada entre várias FTs). Todas opcionais.
  // Gramatura/Coluna/Mullen/Compressão são valor único (o teste de
  // qualidade compara com tolerância de ±5% — ver
  // domain/services/avaliacao_qualidade.dart). Cobb e Resina são cadastrados
  // como faixa (mín/máx), porque na fábrica os dois sempre trabalham em
  // faixa, nunca em valor único (ver plano técnico, 9.6).
  final double? gramatura;
  final double? coluna;
  final double? cobbInternoMin;
  final double? cobbInternoMax;
  final double? cobbExternoMin;
  final double? cobbExternoMax;
  final double? mullen;
  final double? compressao;
  final double? resinaInternaMin;
  final double? resinaInternaMax;
  final double? resinaExternaMin;
  final double? resinaExternaMax;

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
    required this.clienteNome,
    required this.tipoOnda,
    required this.papeis,
    required this.espessuraEsperadaMm,
    required this.comprimentoMm,
    required this.larguraMm,
    required this.qpPadrao,
    this.referencia,
    required this.ativo,
    this.gramatura,
    this.coluna,
    this.cobbInternoMin,
    this.cobbInternoMax,
    this.cobbExternoMin,
    this.cobbExternoMax,
    this.mullen,
    this.compressao,
    this.resinaInternaMin,
    this.resinaInternaMax,
    this.resinaExternaMin,
    this.resinaExternaMax,
    this.vinco1Mm,
    this.vinco2Mm,
    this.vinco3Mm,
    this.vinco4Mm,
    this.vinco5Mm,
    this.pacotesPorCamada,
    this.pecasPorPacote,
    this.arranjo,
  });

  /// Quantos campos de papel o formulário mostra pra cada tipo de onda —
  /// DB/DC (dupla) usa 5, B/C (simples) usa 3. O banco garante a mesma
  /// regra (`fichas_tecnicas_papeis_por_onda_check`).
  static int quantidadePapeis(String tipoOnda) =>
      (tipoOnda == 'DB' || tipoOnda == 'DC') ? 5 : 3;

  /// Ex.: "T140M130T140/B" — os papéis concatenados na ordem + o tipo de
  /// onda. Gerado pelo app, nunca digitado (mesmo padrão de "o app calcula"
  /// de `quantidade_calculada`, ver plano técnico, 9.1).
  static String gerarComposicao({
    required String tipoOnda,
    required List<String> papeis,
  }) => '${papeis.join()}/$tipoOnda';

  String get composicao => gerarComposicao(tipoOnda: tipoOnda, papeis: papeis);

  String? _papel(int indice) => indice < papeis.length ? papeis[indice] : null;

  /// "Comprimento x Largura mm" pronto pra exibir.
  String get medidaExibicao =>
      '${comprimentoMm.toStringAsFixed(0)} x ${larguraMm.toStringAsFixed(0)} mm';

  factory FichaTecnica.fromMap(Map<String, dynamic> map) => FichaTecnica(
    id: map['id'] as String,
    codigoFt: map['codigo_ft'] as String,
    clienteNome: map['cliente_nome'] as String,
    tipoOnda: map['tipo_onda'] as String,
    papeis: [
      map['papel_1'] as String?,
      map['papel_2'] as String?,
      map['papel_3'] as String?,
      map['papel_4'] as String?,
      map['papel_5'] as String?,
    ].whereType<String>().toList(),
    espessuraEsperadaMm: (map['espessura_esperada_mm'] as num).toDouble(),
    comprimentoMm: (map['comprimento_mm'] as num).toDouble(),
    larguraMm: (map['largura_mm'] as num).toDouble(),
    qpPadrao: map['qp_padrao'] as int,
    referencia: map['referencia'] as String?,
    ativo: map['ativo'] as bool? ?? true,
    gramatura: (map['gramatura'] as num?)?.toDouble(),
    coluna: (map['coluna'] as num?)?.toDouble(),
    cobbInternoMin: (map['cobb_interno_min'] as num?)?.toDouble(),
    cobbInternoMax: (map['cobb_interno_max'] as num?)?.toDouble(),
    cobbExternoMin: (map['cobb_externo_min'] as num?)?.toDouble(),
    cobbExternoMax: (map['cobb_externo_max'] as num?)?.toDouble(),
    mullen: (map['mullen'] as num?)?.toDouble(),
    compressao: (map['compressao'] as num?)?.toDouble(),
    resinaInternaMin: (map['resina_interna_min'] as num?)?.toDouble(),
    resinaInternaMax: (map['resina_interna_max'] as num?)?.toDouble(),
    resinaExternaMin: (map['resina_externa_min'] as num?)?.toDouble(),
    resinaExternaMax: (map['resina_externa_max'] as num?)?.toDouble(),
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
    'cliente_nome': clienteNome,
    'tipo_onda': tipoOnda,
    'papel_1': _papel(0),
    'papel_2': _papel(1),
    'papel_3': _papel(2),
    'papel_4': _papel(3),
    'papel_5': _papel(4),
    'espessura_esperada_mm': espessuraEsperadaMm,
    'comprimento_mm': comprimentoMm,
    'largura_mm': larguraMm,
    'qp_padrao': qpPadrao,
    'referencia': referencia,
    'gramatura': gramatura,
    'coluna': coluna,
    'cobb_interno_min': cobbInternoMin,
    'cobb_interno_max': cobbInternoMax,
    'cobb_externo_min': cobbExternoMin,
    'cobb_externo_max': cobbExternoMax,
    'mullen': mullen,
    'compressao': compressao,
    'resina_interna_min': resinaInternaMin,
    'resina_interna_max': resinaInternaMax,
    'resina_externa_min': resinaExternaMin,
    'resina_externa_max': resinaExternaMax,
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
