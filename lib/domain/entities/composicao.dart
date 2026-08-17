/// Exemplo inicial de papéis disponíveis pro cadastro de Composição —
/// lista fixa por enquanto, sem tela própria de cadastro.
const papeisDisponiveis = ['T090', 'T110', 'T140', 'T170', 'T190', 'T210'];

/// Onda simples (B ou C) usa 3 papéis (capa/miolo/capa); onda dupla (DB ou
/// DC) usa 5 (capa/miolo/capa/miolo/capa).
const tiposOnda = ['B', 'C', 'DB', 'DC'];

class Composicao {
  final String id;
  final String codigo;
  final double espessuraMm;
  final String? tipoOnda;
  final List<String> papeis;

  const Composicao({
    required this.id,
    required this.codigo,
    required this.espessuraMm,
    this.tipoOnda,
    this.papeis = const [],
  });

  /// Quantos campos de papel mostrar no formulário pra cada tipo de onda —
  /// DB/DC (dupla) usa 5, B/C (simples) usa 3.
  static int quantidadePapeis(String tipoOnda) =>
      (tipoOnda == 'DB' || tipoOnda == 'DC') ? 5 : 3;

  /// Ex.: "T140M130T140/B" — os papéis concatenados na ordem + o tipo de
  /// onda. O app gera isso sozinho a partir dos papéis escolhidos, nunca é
  /// digitado direto (mesmo padrão de "o app calcula, o usuário não
  /// digita" já usado em `quantidade_calculada` — ver plano técnico, 9.1).
  static String gerarCodigo({
    required String tipoOnda,
    required List<String> papeis,
  }) {
    return '${papeis.join()}/$tipoOnda';
  }

  factory Composicao.fromMap(Map<String, dynamic> map) => Composicao(
    id: map['id'] as String,
    codigo: map['codigo'] as String,
    espessuraMm: (map['espessura_mm'] as num).toDouble(),
    tipoOnda: map['tipo_onda'] as String?,
    papeis: [
      map['papel_1'] as String?,
      map['papel_2'] as String?,
      map['papel_3'] as String?,
      map['papel_4'] as String?,
      map['papel_5'] as String?,
    ].whereType<String>().toList(),
  );

  Map<String, dynamic> toInsertMap() => {
    'codigo': codigo,
    'espessura_mm': espessuraMm,
    'tipo_onda': tipoOnda,
    'papel_1': _papel(0),
    'papel_2': _papel(1),
    'papel_3': _papel(2),
    'papel_4': _papel(3),
    'papel_5': _papel(4),
  };

  String? _papel(int indice) => indice < papeis.length ? papeis[indice] : null;
}
