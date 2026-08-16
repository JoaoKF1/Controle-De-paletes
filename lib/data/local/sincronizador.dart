import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/supabase_provider.dart';
import '../repositories/paletes_repository.dart';
import 'app_database.dart';
import 'rede.dart';

/// Orquestra a sincronização de tudo que ficou pendente offline: os
/// apontamentos de palete (fila própria, com número sequencial resolvido
/// no servidor) e a fila genérica (refugo, pedir revisão, cadastros — ver
/// plano técnico, 9.12). Cada item só sai da fila se o servidor confirmar;
/// falha vira mensagem de erro na linha, não silêncio nem retry escondido.
class Sincronizador {
  final AppDatabase _db;
  final SupabaseClient _client;
  final PaletesRepository _paletes;
  Sincronizador(this._db, this._client, this._paletes);

  Future<void> sincronizarTudo() async {
    await _paletes.sincronizarPendentes();
    await _sincronizarFilaGenerica();
  }

  Future<void> _sincronizarFilaGenerica() async {
    final pendentes = await _db.listarOperacoesPendentes();
    for (final op in pendentes) {
      try {
        final dados = jsonDecode(op.payload) as Map<String, dynamic>;
        await _enviar(op.tipo, dados);
        await _db.removerOperacaoPendente(op.id);
      } catch (e) {
        await _db.marcarErroOperacao(op.id, e.toString());
      }
    }
  }

  Future<void> _enviar(String tipo, Map<String, dynamic> dados) async {
    if (tipo == 'refugo') {
      await _client.from('refugos').insert(dados).timeout(timeoutRede);
      return;
    }
    if (tipo == 'ocorrencia_abrir') {
      await _client
          .from('ocorrencias_qualidade')
          .insert(dados)
          .timeout(timeoutRede);
      return;
    }
    // Cadastros: tipo vem como '<tabela>_criar' ou '<tabela>_atualizar'
    // (ver CadastrosRepository._tentarOuEnfileirar).
    if (tipo.endsWith('_atualizar')) {
      final tabela = tipo.substring(0, tipo.length - '_atualizar'.length);
      final id = dados['id'] as String;
      final semId = Map<String, dynamic>.from(dados)..remove('id');
      await _client
          .from(tabela)
          .update(semId)
          .eq('id', id)
          .timeout(timeoutRede);
      return;
    }
    if (tipo.endsWith('_criar')) {
      final tabela = tipo.substring(0, tipo.length - '_criar'.length);
      await _client.from(tabela).insert(dados).timeout(timeoutRede);
      return;
    }
    throw Exception('Tipo de operação pendente desconhecido: $tipo');
  }
}

final sincronizadorProvider = Provider<Sincronizador>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);
  final paletes = ref.watch(paletesRepositoryProvider);
  return Sincronizador(db, client, paletes);
});
