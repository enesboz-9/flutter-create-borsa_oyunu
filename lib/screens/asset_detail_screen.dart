import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/market_hours.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../state/game_controller.dart';
import 'trade_sheet.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key, required this.asset});

  final Asset asset;

  void _openSheet(BuildContext context, Side side) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: TradeSheet(asset: asset, side: side),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final price = game.priceOf(asset.symbol);
    final change = game.changePercent(asset.symbol);
    final color = change >= 0 ? kGreen : kRed;
    final open = isMarketOpen(asset);
    final myPositions =
        game.positions.where((p) => p.symbol == asset.symbol).toList();

    return Scaffold(
      appBar: AppBar(title: Text('${asset.name} (${asset.symbol})')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '₺${fmtPrice(price)}${asset.unit.isEmpty ? '' : ' / ${asset.unit}'}',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(fmtPct(change), style: TextStyle(color: color, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: _PriceChart(values: game.historyOf(asset.symbol), color: color),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _info('Kategori', asset.category.label),
                  _info('Komisyon',
                      '%${(asset.category.commissionRate * 100).toStringAsFixed(2).replaceAll('.', ',')} (açılış ve kapanış)'),
                  _info('Maks. kaldıraç', '${asset.category.maxLeverage}x'),
                  _info('Piyasa', open ? 'Açık' : 'Kapalı'),
                ],
              ),
            ),
          ),
          if (myPositions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Bu varlıktaki açık pozisyonların',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final p in myPositions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                    '${p.side == Side.long ? 'LONG' : 'SHORT'} ${p.leverage}x • ₺${fmtPrice(p.entryPrice)}'),
                trailing: Text(
                  fmtSigned(p.pnlAt(price)),
                  style: TextStyle(color: pnlColor(p.pnlAt(price))),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _openSheet(context, Side.long),
                  child: const Text('AL (Long)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _openSheet(context, Side.short),
                  child: const Text('SAT (Short)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v)],
        ),
      );
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
    final pad = (maxV - minV) * 0.05 + 1e-9;

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minY: minV - pad,
        maxY: maxV + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: false,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}
