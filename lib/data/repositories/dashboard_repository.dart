import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/dashboard_dados.dart';
import '../remote/supabase_provider.dart';

/// Agregações simples pro dashboard — busca as linhas cruas e soma em Dart
/// (mesmo padrão já usado no resumo de chapas da Conversão). Volume de
/// dados de um piloto não justifica RPC/view no banco ainda.
class DashboardRepository {
  final SupabaseClient _client;
  DashboardRepository(this._client);

  Future<ResumoDashboard> buscarResumo() async {
    final ops = await _client.from('ordens_producao').select('status');
    final opsList = ops as List;
    final abertas = opsList.where((o) => o['status'] == 'aberta').length;
    final concluidas = opsList.where((o) => o['status'] == 'concluida').length;

    final ocorrencias = await _client
        .from('ocorrencias_qualidade')
        .select('id')
        .eq('status', 'em_analise');

    return ResumoDashboard(
      opsAbertas: abertas,
      opsConcluidas: concluidas,
      ocorrenciasEmAnalise: (ocorrencias as List).length,
    );
  }

  Future<List<RefugoPorMotivo>> buscarRefugoPorMotivo() async {
    final dados = await _client.from('refugos').select('motivo, quantidade');
    final totais = <String, int>{};
    for (final linha in dados as List) {
      final motivo = linha['motivo'] as String;
      totais[motivo] = (totais[motivo] ?? 0) + (linha['quantidade'] as int);
    }
    final lista = totais.entries
        .map((e) => RefugoPorMotivo(motivo: e.key, quantidade: e.value))
        .toList();
    lista.sort((a, b) => b.quantidade.compareTo(a.quantidade));
    return lista;
  }

  Future<List<ProducaoDia>> buscarProducaoPorDia({int dias = 14}) async {
    final desde = DateTime.now().subtract(Duration(days: dias));
    final dados = await _client
        .from('paletes')
        .select('data_hora, setor_origem, quantidade_calculada')
        .gte('data_hora', desde.toIso8601String());

    final totais = <DateTime, Map<String, int>>{};
    for (final linha in dados as List) {
      final dataHora = DateTime.parse(linha['data_hora'] as String).toLocal();
      final dia = DateTime(dataHora.year, dataHora.month, dataHora.day);
      final setor = linha['setor_origem'] as String;
      final quantidade = linha['quantidade_calculada'] as int;
      final doDia = totais.putIfAbsent(dia, () => {'onduladeira': 0, 'conversao': 0});
      doDia[setor] = (doDia[setor] ?? 0) + quantidade;
    }

    final lista = totais.entries
        .map(
          (e) => ProducaoDia(
            dia: e.key,
            onduladeira: e.value['onduladeira']!,
            conversao: e.value['conversao']!,
          ),
        )
        .toList();
    lista.sort((a, b) => a.dia.compareTo(b.dia));
    return lista;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRepository(client);
});
