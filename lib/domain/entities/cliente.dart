class Cliente {
  final String id;
  final String razaoSocial;
  final String cidade;
  final String uf;
  final bool ativo;

  const Cliente({
    required this.id,
    required this.razaoSocial,
    required this.cidade,
    required this.uf,
    required this.ativo,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        id: map['id'] as String,
        razaoSocial: map['razao_social'] as String,
        cidade: map['cidade'] as String,
        uf: map['uf'] as String,
        ativo: map['ativo'] as bool? ?? true,
      );

  Map<String, dynamic> toInsertMap() => {
        'razao_social': razaoSocial,
        'cidade': cidade,
        'uf': uf,
      };
}
