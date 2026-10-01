import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/rede.dart';

const mensagemSemConexao =
    'Sem conexão com o servidor. Verifique a internet e tente novamente.';

/// Traduz qualquer erro vindo do Supabase/rede numa frase que o operador
/// entende — nunca mostra a exceção crua (`PostgrestException(...)`,
/// `ClientException with SocketException...`) numa tela do chão de fábrica.
String mensagemErro(Object erro) {
  if (falhaDeRede(erro)) return mensagemSemConexao;

  if (erro is AuthException) {
    final texto = erro.message.toLowerCase();
    if (texto.contains('invalid login credentials')) {
      return 'Usuário ou senha incorretos.';
    }
    if (texto.contains('jwt') || texto.contains('session')) {
      return 'Sua sessão expirou. Entre de novo.';
    }
    return erro.message;
  }

  if (erro is PostgrestException) {
    switch (erro.code) {
      case '42501': // insufficient_privilege (RLS)
        return 'Você não tem permissão para fazer isso.';
      case '23505': // unique_violation
        return 'Já existe um registro com esses dados.';
      case '23503': // foreign_key_violation
        return 'Registro vinculado a outro cadastro que não existe mais.';
      case 'PGRST116': // .single() sem nenhuma linha
        return 'Registro não encontrado.';
    }
    return erro.message;
  }

  // Edge Function respondeu com status de erro — o corpo segue o padrão
  // `{ "erro": "..." }` das nossas functions (ver supabase/functions).
  if (erro is FunctionException) {
    final detalhes = erro.details;
    if (detalhes is Map && detalhes['erro'] != null) {
      return detalhes['erro'].toString();
    }
    return 'Falha no servidor (código ${erro.status}).';
  }

  final texto = erro.toString();
  return texto.startsWith('Exception: ') ? texto.substring(11) : texto;
}

/// Mostra o erro por cima do que estiver aberto (inclusive outro diálogo),
/// pra ação que falhou não ficar sem resposta nenhuma na tela.
Future<void> mostrarErro(BuildContext context, Object erro) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Não foi possível concluir'),
      content: Text(mensagemErro(erro)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
