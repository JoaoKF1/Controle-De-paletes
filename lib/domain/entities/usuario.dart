/// Espelha a tabela `profiles` do Supabase.
/// perfil assume um dos valores: onduladeira | conversao | qualidade | admin
/// turno assume um dos valores: primeiro | segundo | comercial — decide quem
/// recebe notificação push de teste de qualidade e quando (ver plano
/// técnico, 9.6/12; só perfil onduladeira recebe, mas todo usuário tem
/// turno cadastrado).
class Usuario {
  final String id;
  final String login;
  final String nome;
  final String perfil;
  final String turno;
  final bool ativo;

  const Usuario({
    required this.id,
    required this.login,
    required this.nome,
    required this.perfil,
    required this.turno,
    required this.ativo,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      login: map['login'] as String,
      nome: map['nome'] as String,
      perfil: map['perfil'] as String,
      turno: map['turno'] as String? ?? 'comercial',
      ativo: map['ativo'] as bool? ?? true,
    );
  }
}
