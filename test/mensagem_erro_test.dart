import 'dart:async';
import 'dart:io';

import 'package:controle_paletes/core/utils/mensagem_erro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mensagemErro', () {
    test('falha de rede vira mensagem de sem conexão', () {
      expect(
        mensagemErro(const SocketException('Failed host lookup')),
        mensagemSemConexao,
      );
      expect(mensagemErro(TimeoutException('x')), mensagemSemConexao);
      // Formato real do Supabase Auth quando o projeto está fora do ar.
      expect(
        mensagemErro(
          AuthRetryableFetchException(
            message:
                'ClientException with SocketException: Failed host lookup: '
                "'xyz.supabase.co'",
          ),
        ),
        mensagemSemConexao,
      );
    });

    test('credencial inválida é traduzida', () {
      expect(
        mensagemErro(const AuthException('Invalid login credentials')),
        'Usuário ou senha incorretos.',
      );
    });

    test('códigos conhecidos do Postgres viram frase', () {
      expect(
        mensagemErro(const PostgrestException(message: 'x', code: '42501')),
        'Você não tem permissão para fazer isso.',
      );
      expect(
        mensagemErro(const PostgrestException(message: 'x', code: '23505')),
        'Já existe um registro com esses dados.',
      );
    });

    test('erro da Edge Function usa o campo "erro" do corpo', () {
      expect(
        mensagemErro(
          const FunctionException(
            status: 400,
            details: {'erro': 'Login já existe'},
          ),
        ),
        'Login já existe',
      );
    });

    test('Exception genérica perde o prefixo', () {
      expect(mensagemErro(Exception('Falha ao criar')), 'Falha ao criar');
    });
  });
}
