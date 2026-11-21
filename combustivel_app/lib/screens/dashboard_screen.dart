import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/calculos.dart';
import '../utils/formatadores.dart';

final _diaMes = DateFormat('dd/MM');

/// Dashboard: valor de cada abastecimento, evolução do km/L e do R$/km.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final indicadores = context.watch<AppProvider>().indicadores;
    final gastoTotal = context.watch<AppProvider>().gastoTotal;
    final cores = Theme.of(context).colorScheme;

    if (indicadores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Registre abastecimentos para ver os gráficos.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Só entram nos gráficos de km/L e R$/km os abastecimentos com indicador
    // (do 2º em diante).
    final comIndicador = indicadores
        .where((i) => i.kmPorLitro != null && i.custoPorKm != null)
        .toList();

    // Médias ponderadas pelo total rodado: distância/litros e custo/distância.
    double? mediaKmL;
    double? mediaCusto;
    if (comIndicador.isNotEmpty) {
      final distancia = comIndicador.fold(0.0, (s, i) => s + i.distancia!);
      final litros =
          comIndicador.fold(0.0, (s, i) => s + i.abastecimento.litros);
      final custo = comIndicador.fold(0.0, (s, i) => s + i.valorTotal);
      mediaKmL = distancia / litros;
      mediaCusto = custo / distancia;
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            _ResumoCard(titulo: 'Gasto total', valor: formatarMoeda(gastoTotal)),
            _ResumoCard(
              titulo: 'Média km/L',
              valor: mediaKmL == null ? '—' : formatarDecimal(mediaKmL),
            ),
            _ResumoCard(
              titulo: 'Média R\$/km',
              valor: mediaCusto == null ? '—' : formatarMoeda(mediaCusto),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ---------- Valor de cada abastecimento ----------
        _CartaoGrafico(
          titulo: 'Valor de cada abastecimento',
          subtitulo: 'Em reais (R\$)',
          child: _Rolavel(
            quantidade: indicadores.length,
            builder: (_) => _GraficoValores(
              indicadores: indicadores,
              cor: cores.primary,
            ),
          ),
        ),

        // ---------- Consumo km/L ----------
        _CartaoGrafico(
          titulo: 'Consumo (km/L)',
          subtitulo: 'Distância percorrida ÷ litros do abastecimento',
          aviso: _avisoLinha(comIndicador.length),
          child: comIndicador.isEmpty
              ? null
              : _Rolavel(
                  quantidade: indicadores.length,
                  builder: (_) => _GraficoLinha(
                    todos: indicadores,
                    valor: (i) => i.kmPorLitro,
                    formatarEixo: (v) => v.toStringAsFixed(1),
                    formatarTooltip: (v) => '${formatarDecimal(v)} km/L',
                    cor: cores.tertiary,
                  ),
                ),
        ),

        // ---------- Custo R$/km ----------
        _CartaoGrafico(
          titulo: 'Custo por quilômetro (R\$/km)',
          subtitulo: 'Valor do abastecimento ÷ distância percorrida',
          aviso: _avisoLinha(comIndicador.length),
          child: comIndicador.isEmpty
              ? null
              : _Rolavel(
                  quantidade: indicadores.length,
                  builder: (_) => _GraficoLinha(
                    todos: indicadores,
                    valor: (i) => i.custoPorKm,
                    formatarEixo: (v) => v.toStringAsFixed(2),
                    formatarTooltip: (v) => '${formatarMoeda(v)}/km',
                    cor: cores.secondary,
                  ),
                ),
        ),
      ],
    );
  }

  static String? _avisoLinha(int pontos) {
    if (pontos == 0) {
      return 'Registre pelo menos 2 abastecimentos para calcular este indicador.';
    }
    if (pontos == 1) {
      return 'Registre mais um abastecimento para ver a evolução.';
    }
    return null;
  }
}

// ======================================================================
// Componentes de layout
// ======================================================================

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  const _ResumoCard({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(titulo, style: tema.textTheme.labelSmall),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(valor, style: tema.textTheme.titleMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoGrafico extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget? child;
  final String? aviso;

  const _CartaoGrafico({
    required this.titulo,
    required this.subtitulo,
    this.child,
    this.aviso,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: tema.textTheme.titleMedium),
            Text(subtitulo, style: tema.textTheme.bodySmall),
            const SizedBox(height: 16),
            ?child,
            if (aviso != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(aviso!,
                    style: tema.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dá altura fixa ao gráfico e permite rolar na horizontal quando há
/// muitos abastecimentos (evita rótulos amontoados).
class _Rolavel extends StatelessWidget {
  final int quantidade;
  final WidgetBuilder builder;
  const _Rolavel({required this.quantidade, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, restricoes) {
      final largura = math.max(restricoes.maxWidth, quantidade * 44.0 + 48);
      final grafico = Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(width: largura - 16, height: 220, child: builder(context)),
      );
      if (largura <= restricoes.maxWidth) return grafico;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: grafico,
      );
    });
  }
}

// ======================================================================
// Eixos
// ======================================================================

FlTitlesData _titulos(
  List<Indicador> todos,
  String Function(double) formatarEixo,
) {
  const estilo = TextStyle(fontSize: 10);
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: 1,
        getTitlesWidget: (valor, meta) {
          final i = valor.round();
          if ((valor - i).abs() > 0.01 || i < 0 || i >= todos.length) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 6,
            child: Text(_diaMes.format(todos[i].abastecimento.dataHora),
                style: estilo),
          );
        },
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (valor, meta) => SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4,
          child: Text(formatarEixo(valor), style: estilo),
        ),
      ),
    ),
  );
}

const _estiloTooltip =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);

// ======================================================================
// Gráfico de barras: valor de cada abastecimento
// ======================================================================

class _GraficoValores extends StatelessWidget {
  final List<Indicador> indicadores;
  final Color cor;
  const _GraficoValores({required this.indicadores, required this.cor});

  @override
  Widget build(BuildContext context) {
    final n = indicadores.length;
    final larguraBarra = n <= 6 ? 22.0 : (n <= 15 ? 16.0 : 10.0);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titulos(indicadores, (v) => v.toStringAsFixed(0)),
        barGroups: [
          for (var i = 0; i < n; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: indicadores[i].valorTotal,
                  width: larguraBarra,
                  color: cor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (grupo, indiceGrupo, barra, indiceBarra) {
              final a = indicadores[grupo.x].abastecimento;
              return BarTooltipItem(
                '${formatarDataHora(a.dataHora)}\n'
                '${a.tipo.rotulo}: ${formatarMoeda(a.valorTotal)}',
                _estiloTooltip,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Gráfico de linha: km/L e R$/km ao longo dos abastecimentos
// ======================================================================

class _GraficoLinha extends StatelessWidget {
  final List<Indicador> todos;
  final double? Function(Indicador) valor;
  final String Function(double) formatarEixo;
  final String Function(double) formatarTooltip;
  final Color cor;

  const _GraficoLinha({
    required this.todos,
    required this.valor,
    required this.formatarEixo,
    required this.formatarTooltip,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    // x = posição cronológica do abastecimento (alinhado com o gráfico de
    // barras). O 1º abastecimento (x = 0) não tem ponto.
    final pontos = <FlSpot>[
      for (var i = 0; i < todos.length; i++)
        if (valor(todos[i]) != null) FlSpot(i.toDouble(), valor(todos[i])!),
    ];

    final ys = pontos.map((p) => p.y).toList();
    final minimo = ys.reduce(math.min);
    final maximo = ys.reduce(math.max);
    final folga = math.max((maximo - minimo) * 0.2, maximo * 0.1);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, todos.length - 1).toDouble(),
        minY: math.max(0.0, minimo - folga),
        maxY: maximo + folga,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titulos(todos, formatarEixo),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            isCurved: false,
            barWidth: 3,
            color: cor,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: cor.withValues(alpha: 0.15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (toques) => toques.map((t) {
              final i = t.x.round();
              return LineTooltipItem(
                '${formatarDataHora(todos[i].abastecimento.dataHora)}\n'
                '${formatarTooltip(t.y)}',
                _estiloTooltip,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
