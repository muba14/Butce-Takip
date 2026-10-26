import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../widgets/common.dart';

enum ChartKind { sutun, cizgi, daire }

class GrafiklerScreen extends StatefulWidget {
  final BudgetStore store;
  const GrafiklerScreen({super.key, required this.store});

  @override
  State<GrafiklerScreen> createState() => _GrafiklerScreenState();
}

class _GrafiklerScreenState extends State<GrafiklerScreen> {
  ChartKind _kind = ChartKind.sutun;

  BudgetStore get store => widget.store;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final months = store.lastMonths(6);

    final cats = [
      for (final c in store.categories[EntryType.gider]!)
        _Slice(
          c.name,
          store.total(EntryType.gider,
              where: (e) => e.category == c.name && BudgetStore.isThisMonth(e)),
          c.c,
          iconFor(c.icon),
        ),
    ].where((s) => s.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget chart;
    String title;
    switch (_kind) {
      case ChartKind.sutun:
        title = 'Son 6 ay · gelir ve gider';
        chart = _bars(months, muted);
      case ChartKind.cizgi:
        title = 'Son 6 ay · gelir ve gider';
        chart = _lines(months, muted);
      case ChartKind.daire:
        title = 'Bu ay gelir ve gider';
        chart = _Donut([
          _Slice('Gelir', store.monthTotal(EntryType.gelir), AppColors.income),
          _Slice('Gider', store.monthTotal(EntryType.gider), AppColors.expense),
        ]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
      children: [
        SegmentedButton<ChartKind>(
          segments: const [
            ButtonSegment(value: ChartKind.sutun, label: Text('Sütun')),
            ButtonSegment(value: ChartKind.cizgi, label: Text('Çizgi')),
            ButtonSegment(value: ChartKind.daire, label: Text('Daire')),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.navy,
            selectedForegroundColor: Colors.white,
          ),
          onSelectionChanged: (s) => setState(() => _kind = s.first),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                chart,
                if (_kind != ChartKind.daire) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    const Dot(AppColors.income),
                    const SizedBox(width: 6),
                    Text('Gelir', style: TextStyle(fontSize: 12, color: muted)),
                    const SizedBox(width: 14),
                    const Dot(AppColors.expense),
                    const SizedBox(width: 6),
                    Text('Gider', style: TextStyle(fontSize: 12, color: muted)),
                  ]),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionTitle('Gider dağılımı · bu ay'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: cats.isEmpty
                ? Text('Bu ay gider yok.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted))
                : _Donut(cats),
          ),
        ),
      ],
    );
  }

  /// Eksen için düzgün aralık: 1, 2, 2.5, 5 × 10ⁿ
  ({double top, double tick}) _scale(List<MonthSummary> m) {
    final mx = m.fold<double>(
        0, (s, e) => math.max(s, math.max(e.income, e.expense)));
    if (mx <= 0) return (top: 1000, tick: 250);
    final raw = mx / 4;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / mag;
    final tick = (f <= 1
            ? 1
            : f <= 2
                ? 2
                : f <= 2.5
                    ? 2.5
                    : f <= 5
                        ? 5
                        : 10) *
        mag;
    return (top: (mx / tick).ceil() * tick, tick: tick);
  }

  String _axisLabel(double v) {
    if (v < 1000) return v.round().toString();
    final k = v / 1000;
    return '${k == k.roundToDouble() ? k.round() : k.toStringAsFixed(1).replaceAll('.', ',')}b';
  }

  FlTitlesData _titles(List<MonthSummary> m, Color muted, double tick) =>
      FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: tick,
            getTitlesWidget: (v, meta) => Text(
              _axisLabel(v),
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (v, meta) {
              final i = v.round();
              if (i < 0 || i >= m.length || v != i.toDouble()) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(monthShort(m[i].month),
                    style: TextStyle(fontSize: 11, color: muted)),
              );
            },
          ),
        ),
      );

  FlGridData _grid(double tick) => FlGridData(
        drawVerticalLine: false,
        horizontalInterval: tick,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Theme.of(context).dividerColor.withAlpha(60),
          strokeWidth: 1,
        ),
      );

  Widget _bars(List<MonthSummary> m, Color muted) {
    final sc = _scale(m);
    final top = sc.top;
    return SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          maxY: top,
          minY: 0,
          gridData: _grid(sc.tick),
          borderData: FlBorderData(show: false),
          titlesData: _titles(m, muted, sc.tick),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                tl(rod.toY),
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < m.length; i++)
              BarChartGroupData(x: i, barsSpace: 4, barRods: [
                BarChartRodData(
                  toY: m[i].income,
                  color: AppColors.income,
                  width: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: m[i].expense,
                  color: AppColors.expense,
                  width: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _lines(List<MonthSummary> m, Color muted) {
    final sc = _scale(m);
    final top = sc.top;
    LineChartBarData line(List<double> v, Color c) => LineChartBarData(
          spots: [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i])],
          isCurved: true,
          preventCurveOverShooting: true,
          color: c,
          barWidth: 3,
          dotData: FlDotData(
            checkToShowDot: (s, _) => s.x == v.length - 1,
            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
              radius: 4.5,
              color: c,
              strokeWidth: 2,
              strokeColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          belowBarData: BarAreaData(show: true, color: c.withAlpha(28)),
        );
    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minX: -0.3,
          maxX: m.length - 0.7,
          minY: 0,
          maxY: top,
          gridData: _grid(sc.tick),
          borderData: FlBorderData(show: false),
          titlesData: _titles(m, muted, sc.tick),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(tl(s.y),
                      TextStyle(color: s.bar.color, fontSize: 12)),
              ],
            ),
          ),
          lineBarsData: [
            line([for (final x in m) x.income], AppColors.income),
            line([for (final x in m) x.expense], AppColors.expense),
          ],
        ),
      ),
    );
  }
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;
  _Slice(this.label, this.value, this.color, [this.icon]);
}

class _Donut extends StatelessWidget {
  final List<_Slice> slices;
  const _Donut(this.slices);

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final total = slices.fold(0.0, (s, e) => s + e.value);
    final safe = total == 0 ? 1.0 : total;
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                centerSpaceRadius: 48,
                sectionsSpace: 2,
                startDegreeOffset: -90,
                sections: total == 0
                    ? [
                        PieChartSectionData(
                            value: 1,
                            color: muted.withAlpha(50),
                            radius: 24,
                            showTitle: false)
                      ]
                    : [
                        for (final s in slices)
                          PieChartSectionData(
                            value: s.value,
                            color: s.color,
                            radius: 24,
                            showTitle: false,
                          ),
                      ],
              )),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Toplam', style: TextStyle(fontSize: 11, color: muted)),
                  Text(tl(total),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: tabular)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              for (final s in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      s.icon != null
                          ? Icon(s.icon, size: 17, color: s.color)
                          : Dot(s.color),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(s.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13))),
                      Text('%${(s.value / safe * 100).round()}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFeatures: tabular)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
