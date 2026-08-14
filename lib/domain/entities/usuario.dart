/// Espelha a tabela `profiles` do Supabase.
/// perfil assume um dos valores: onduladeira | conversao | qualidade | admin
class Usuario {
  final String id;
  final String login;
  final String nome;
  final String perfil;
  final bool ativo;

  const Usuario({
    required this.id,
    required this.login,
    required this.nome,
    required this.perfil,
    required this.ativo,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      login: map['login'] as String,
      nome: map['nome'] as String,
      perfil: map['perfil'] as String,
      ativo: map['ativo'] as bool? ?? true,
    );
  }
}
