import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/category_style.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../core/market_hours.dart';
import '../models/asset.dart';
import '../models/position.dart';
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
    final hist = game.historyOf(asset.symbol);
    final color = change >= 0 ? kGreen : kRed;
    final open = isMarketOpen(asset);
    final myPositions =
        game.positions.where((p) => p.symbol == asset.symbol).toList();
    final alertCount = game.activeAlertCountFor(asset.symbol);

    final low = hist.isEmpty ? price : hist.reduce((a, b) => a < b ? a : b);
    final high = hist.isEmpty ? price : hist.reduce((a, b) => a > b ? a : b);
    final first = hist.isEmpty ? price : hist.first;

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
                        Text(open ? 'Piyasa açık' : 'Piyasa kapalı',
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
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
            child: SizedBox(
              height: 220,
              child: _PriceChart(values: hist, color: color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStat('Düşük', fmtPriceIn(low, asset.currency))),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat('Yüksek', fmtPriceIn(high, asset.currency))),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat('Başlangıç', fmtPriceIn(first, asset.currency))),
            ],
          ),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);

  final String label;
  final String value;

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
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxV - minV) * 0.08 + 1e-9;

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
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.15,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
