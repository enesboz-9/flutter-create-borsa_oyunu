import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/category_style.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../services/price_service.dart';
import '../state/game_controller.dart';
import '../widgets/common.dart';
import 'alert_sheet.dart';
import 'trade_sheet.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key, required this.asset});

  final Asset asset;

  void _openSheet(BuildContext context, Side side) =>
      showTradeSheet(context, asset, side);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final price = game.priceOf(asset.symbol);
    final change = game.changePercent(asset.symbol);
    final color = change >= 0 ? kGreen : kRed;
    final open = game.canTrade(asset);
    final myPositions =
        game.positions.where((p) => p.symbol == asset.symbol).toList();
    final alertCount = game.activeAlertCountFor(asset.symbol);


    return Scaffold(
      appBar: AppBar(
        title: Text(asset.symbol, style: const TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            tooltip: 'Fiyat alarmı ve otomatik emir',
            onPressed: () => showAlertSheet(context, asset),
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              child: Icon(alertCount > 0
                  ? Icons.notifications_active
                  : Icons.notifications_none),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              AssetAvatar(asset: asset, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(asset.category.icon,
                            size: 14, color: asset.category.color),
                        const SizedBox(width: 4),
                        Text(asset.category.label,
                            style: TextStyle(
                                color: asset.category.color, fontSize: 12)),
                        const SizedBox(width: 10),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: open ? kGreen : kMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(game.marketStatus(asset),
                            style:
                                const TextStyle(color: kMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceText(
                value: price,
                text: fmtPriceIn(price, asset.currency),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              if (asset.unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 6),
                  child: Text('/ ${asset.unit}',
                      style: const TextStyle(color: kMuted)),
                ),
              const Spacer(),
              PnlPill(value: change, text: fmtPct(change)),
            ],
          ),
          if (!game.hasLiveData(asset.symbol))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Canlı veri alınamadı • örnek fiyat gösteriliyor (internet bağlantısını kontrol et).',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          _ChartSection(asset: asset, color: color),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                KeyValueRow(
                  'Komisyon',
                  '%${(asset.category.commissionRate * 100).toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                const Divider(color: Colors.white10, height: 12),
                KeyValueRow('Maks. kaldıraç', '${asset.category.maxLeverage}x'),
                const Divider(color: Colors.white10, height: 12),
                KeyValueRow('Para birimi', asset.currency.code),
                if (asset.currency == Currency.usd) ...[
                  const Divider(color: Colors.white10, height: 12),
                  KeyValueRow('Dolar bakiyen', fmtUsd(game.usdCash)),
                ],
              ],
            ),
          ),
          if (myPositions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Açık pozisyonların',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final p in myPositions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        p.side == Side.long
                            ? Icons.arrow_circle_up
                            : Icons.arrow_circle_down,
                        color: p.side == Side.long ? kGreen : kRed,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${p.side == Side.long ? 'LONG' : 'SHORT'} ${p.leverage}x  •  ${fmtQty(p.quantity)} adet  •  Ort. ${fmtPriceIn(p.avgCost, asset.currency)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      PnlPill(
                        value: p.pnlAt(price),
                        text: fmtSignedIn(p.pnlAt(price), asset.currency),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'AL (Long)',
                  icon: Icons.trending_up,
                  gradient: kBuyGradient,
                  onPressed: () => _openSheet(context, Side.long),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: 'SAT (Short)',
                  icon: Icons.trending_down,
                  gradient: kSellGradient,
                  onPressed: () => _openSheet(context, Side.short),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartSection extends StatefulWidget {
  const _ChartSection({required this.asset, required this.color});

  final Asset asset;
  final Color color;

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  ChartRange _range = ChartRange.day;
  Future<List<ChartPoint>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context
        .read<GameController>()
        .chartOf(widget.asset.symbol, _range);
  }

  void _select(ChartRange r) {
    setState(() {
      _range = r;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    final cur = asset.currency;
    final game = context.read<GameController>();

    return FutureBuilder<List<ChartPoint>>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        var points = snap.data ?? const <ChartPoint>[];
        var fallback = false;
        if (!loading && points.length < 2) {
          // Geçmiş veri yoksa (ör. bağlantı yok) canlı oturum verisine dön.
          final now = DateTime.now();
          final h = game.historyOf(asset.symbol);
          points = [
            for (var i = 0; i < h.length; i++)
              ChartPoint(now.subtract(Duration(minutes: h.length - 1 - i)), h[i]),
          ];
          fallback = true;
        }
        final values = points.map((p) => p.price).toList();
        final low = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
        final high = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
        final first = values.isEmpty ? 0.0 : values.first;
        final last = values.isEmpty ? 0.0 : values.last;
        final periodChange = first == 0 ? 0.0 : (last - first) / first * 100;
        final lineColor = periodChange >= 0 ? kGreen : kRed;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final r in ChartRange.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(r.label, textAlign: TextAlign.center),
                        ),
                        labelPadding: EdgeInsets.zero,
                        selected: _range == r,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => _select(r),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
              child: SizedBox(
                height: 230,
                child: loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : (points.length < 2
                        ? const Center(
                            child: Text('Grafik verisi yok',
                                style: TextStyle(color: kMuted)))
                        : _PriceChart(
                            points: points,
                            color: lineColor,
                            range: _range,
                            currency: cur,
                          )),
              ),
            ),
            if (!loading && fallback)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Geçmiş veri alınamadı, oturum verisi gösteriliyor.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MiniStat('Düşük', fmtPriceIn(low, cur))),
                const SizedBox(width: 10),
                Expanded(child: _MiniStat('Yüksek', fmtPriceIn(high, cur))),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    '${_range.label} değişim',
                    fmtPct(periodChange),
                    color: pnlColor(periodChange),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({
    required this.points,
    required this.color,
    required this.range,
    required this.currency,
  });

  final List<ChartPoint> points;
  final Color color;
  final ChartRange range;
  final Currency currency;

  String _fmtTime(DateTime t, {bool full = false}) {
    final l = t.toLocal();
    switch (range) {
      case ChartRange.day:
        return DateFormat('HH:mm').format(l);
      case ChartRange.week:
      case ChartRange.month:
        return full
            ? DateFormat('dd.MM HH:mm').format(l)
            : DateFormat('dd.MM').format(l);
      case ChartRange.threeMonths:
      case ChartRange.year:
      case ChartRange.fiveYears:
        return full
            ? DateFormat('dd.MM.yyyy').format(l)
            : DateFormat('MM.yy').format(l);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.price).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxV - minV) * 0.08 + 1e-9;
    final n = points.length;
    final step = (n / 4).floorToDouble().clamp(1, double.infinity);

    return LineChart(
      LineChartData(
        minY: minV - pad,
        maxY: maxV + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: step.toDouble(),
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= n || i == n - 1 && n > 4) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_fmtTime(points[i].time),
                      style: const TextStyle(color: kMuted, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kCard,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${fmtPriceIn(s.y, currency)}\n${_fmtTime(points[s.x.toInt().clamp(0, n - 1)].time, full: true)}',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < n; i++) FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: n < 200,
            curveSmoothness: 0.15,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.30), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
