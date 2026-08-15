import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/dashboard_repository.dart';
import '../../../domain/entities/dashboard_dados.dart';

// Paleta categórica validada (ver skill de dataviz): slot 1 azul, slot 2
// laranja — ordem fixa, nunca ciclada. Sequencial reusa o mesmo azul.
const _corOnduladeira = Color(0xFF2A78D6);
const _corConversao = Color(0xFFEB6834);
const _corSequencial = Color(0xFF2A78D6);
const _corTextoSecundario = Color(0xFF52514E);
const _corGrid = Color(0xFFE1E0D9);

final _resumoProvider = FutureProvider.autoDispose<ResumoDashboard>((ref) {
  return ref.watch(dashboardRepositoryProvider).buscarResumo();
});
final _producaoPorDiaProvider = FutureProvider.autoDispose<List<ProducaoDia>>((ref) {
  return ref.watch(dashboardRepositoryProvider).buscarProducaoPorDia();
});
final _refugoPorMotivoProvider = FutureProvider.autoDispose<List<RefugoPorMotivo>>((ref) {
  return ref.watch(dashboardRepositoryProvider).buscarRefugoPorMotivo();
});

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaKpis(context, ref),
            const SizedBox(height: 24),
            Text('Produção por dia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _cartaoGrafico(context, height: 260, child: _graficoProducao(context, ref)),
            const SizedBox(height: 24),
            Text('Refugo por motivo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _cartaoGrafico(context, height: 260, child: _graficoRefugo(context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _cartaoGrafico(BuildContext context, {required double height, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(height: height, child: child),
      ),
    );
  }

  Widget _linhaKpis(BuildContext context, WidgetRef ref) {
    final resumoAsync = ref.watch(_resumoProvider);
    return resumoAsync.when(
      loading: () => const SizedBox(height: 88, child: Center(child: CircularProgressIndicator())),
      error: (erro, _) => Text('Erro ao carregar resumo: $erro'),
      data: (resumo) => Row(
        children: [
          Expanded(child: _statTile(context, 'OPs em aberto', resumo.opsAbertas)),
          const SizedBox(width: 12),
          Expanded(child: _statTile(context, 'OPs concluídas', resumo.opsConcluidas)),
          const SizedBox(width: 12),
          Expanded(child: _statTile(context, 'Ocorrências em análise', resumo.ocorrenciasEmAnalise)),
        ],
      ),
    );
  }

  Widget _statTile(BuildContext context, String rotulo, int valor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$valor',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(rotulo, style: const TextStyle(color: _corTextoSecundario, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _graficoProducao(BuildContext context, WidgetRef ref) {
    final producaoAsync = ref.watch(_producaoPorDiaProvider);
    return producaoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
      data: (dias) {
        if (dias.isEmpty) {
          return const Center(child: Text('Sem apontamentos nos últimos 14 dias.'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legenda(const [
              _ItemLegenda('Onduladeira', _corOnduladeira),
              _ItemLegenda('Conversão', _corConversao),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: _linhaGrid,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: _rotuloEixoY),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (dias.length / 6).ceilToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (valor, meta) => _rotuloEixoXData(valor, meta, dias),
                      ),
                    ),
                  ),
                  lineTouchData: const LineTouchData(handleBuiltInTouches: true),
                  lineBarsData: [
                    _linha(dias, (d) => d.onduladeira.toDouble(), _corOnduladeira),
                    _linha(dias, (d) => d.conversao.toDouble(), _corConversao),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  LineChartBarData _linha(List<ProducaoDia> dias, double Function(ProducaoDia) valor, Color cor) {
    return LineChartBarData(
      spots: [for (var i = 0; i < dias.length; i++) FlSpot(i.toDouble(), valor(dias[i]))],
      isCurved: false,
      color: cor,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _graficoRefugo(BuildContext context, WidgetRef ref) {
    final refugoAsync = ref.watch(_refugoPorMotivoProvider);
    return refugoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
      data: (motivos) {
        if (motivos.isEmpty) {
          return const Center(child: Text('Nenhum refugo lançado ainda.'));
        }
        final maiorValor = motivos.map((m) => m.quantidade).reduce((a, b) => a > b ? a : b);
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maiorValor * 1.2,
            gridData: const FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: _linhaGrid,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: _rotuloEixoY),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (valor, meta) => _rotuloEixoXMotivo(valor, meta, motivos),
                ),
              ),
            ),
            barTouchData: BarTouchData(enabled: true),
            barGroups: [
              for (var i = 0; i < motivos.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: motivos[i].quantidade.toDouble(),
                      color: _corSequencial,
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _legenda(List<_ItemLegenda> itens) {
    return Wrap(
      spacing: 16,
      children: [
        for (final item in itens)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: item.cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(item.rotulo, style: const TextStyle(color: _corTextoSecundario, fontSize: 12)),
            ],
          ),
      ],
    );
  }
}

class _ItemLegenda {
  final String rotulo;
  final Color cor;
  const _ItemLegenda(this.rotulo, this.cor);
}

FlLine _linhaGrid(double valor) => const FlLine(color: _corGrid, strokeWidth: 1);

Widget _rotuloEixoY(double valor, TitleMeta meta) {
  if (valor != valor.roundToDouble()) return const SizedBox.shrink();
  return Text(
    valor.toInt().toString(),
    style: const TextStyle(color: _corTextoSecundario, fontSize: 11),
  );
}

Widget _rotuloEixoXData(double valor, TitleMeta meta, List<ProducaoDia> dias) {
  final i = valor.round();
  if (i < 0 || i >= dias.length) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      DateFormat('dd/MM').format(dias[i].dia),
      style: const TextStyle(color: _corTextoSecundario, fontSize: 11),
    ),
  );
}

Widget _rotuloEixoXMotivo(double valor, TitleMeta meta, List<RefugoPorMotivo> motivos) {
  final i = valor.round();
  if (i < 0 || i >= motivos.length) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: 64,
      child: Text(
        motivos[i].motivo,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _corTextoSecundario, fontSize: 10),
      ),
    ),
  );
}
