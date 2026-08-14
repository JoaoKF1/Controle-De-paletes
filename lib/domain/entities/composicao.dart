class Composicao {
  final String id;
  final String codigo;
  final double espessuraMm;

  const Composicao({
    required this.id,
    required this.codigo,
    required this.espessuraMm,
  });

  factory Composicao.fromMap(Map<String, dynamic> map) => Composicao(
        id: map['id'] as String,
        codigo: map['codigo'] as String,
        espessuraMm: (map['espessura_mm'] as num).toDouble(),
      );

  Map<String, dynamic> toInsertMap() => {
        'codigo': codigo,
        'espessura_mm': espessuraMm,
      };
}
