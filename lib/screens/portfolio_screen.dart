import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/position.dart';
import '../state/game_controller.dart';
import '../widgets/common.dart';

const List<Color> _palette = [
  Color(0xFF7C6CFF),
  Color(0xFF2ED3B7),
  Color(0xFFF7931A),
  Color(0xFF4DA3FF),
  Color(0xFFFF6B9A),
  Color(0xFFFFC857),
  Color(0xFF9BE15D),
  Color(0xFFB388FF),
];

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final positions = g.positions;
    final ret = g.totalReturnPercent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        AppCard(
          gradient: kHeroGradient,
          borderColor: Colors.transparent,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Toplam varlık',
                      style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fmtPct(ret),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                fmtTl(g.equity),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _heroStat('Nakit', fmtTl(g.cash)),
                  _heroStat('Teminat', fmtTl(g.usedMargin)),
                  _heroStat('Açık K/Z', fmtSigned(g.unrealizedPnl)),
                ],
              ),
            ],
          ),
        ),
        if (positions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _AllocationCard(cash: g.cash, positions: positions),
        ],
        const SizedBox(height: 20),
        Text('Açık pozisyonlar (${positions.length})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (positions.isEmpty)
          const AppCard(
            padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: kMuted),
                  SizedBox(height: 10),
                  Text('Açık pozisyonun yok.',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Piyasa sekmesinden bir işlem aç.',
                      style: TextStyle(color: kMuted)),
                ],
              ),
            ),
          ),
        for (final p in positions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PositionCard(position: p),
          ),
      ],
    );
  }

  Widget _heroStat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.cash, required this.positions});

  final double cash;
  final List<Position> positions;

  @override
  Widget build(BuildContext context) {
    final entries = <({String label, double value, Color color})>[
      (label: 'Nakit', value: cash, color: const Color(0xFF5B6478)),
      for (var i = 0; i < positions.length; i++)
        (
          label: positions[i].symbol,
          value: positions[i].margin,
          color: _palette[i % _palette.length],
        ),
    ];
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return const SizedBox.shrink();

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 34,
                sectionsSpace: 2,
                sections: [
                  for (final e in entries)
                    if (e.value > 0)
                      PieChartSectionData(
                        value: e.value,
                        color: e.color,
                        radius: 22,
                        showTitle: false,
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Varlık dağılımı',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: e.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.label)),
                        Text(
                          '%${(e.value / total * 100).toStringAsFixed(0)}',
                          style: const TextStyle(color: kMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.position});

  final Position position;

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final p = position;
    final price = g.priceOf(p.symbol);
    final pnl = p.pnlAt(price);
    final pnlPct = p.margin == 0 ? 0.0 : pnl / p.margin * 100;
    final isLong = p.side == Side.long;
    final sideColor = isLong ? kGreen : kRed;

    // Likidasyona ne kadar yaklaşıldığı (0 = güvenli, 1 = likidasyon).
    final adverse = isLong ? p.entryPrice - price : price - p.entryPrice;
    final span = (p.entryPrice - p.liquidationPrice).abs();
    final risk = span == 0 ? 0.0 : (adverse / span).clamp(0.0, 1.0);
    final riskColor = Color.lerp(kGreen, kRed, risk)!;

    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: sideColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(p.symbol,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sideColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${isLong ? 'LONG' : 'SHORT'} ${p.leverage}x',
                            style: TextStyle(
                                color: sideColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmtSigned(pnl),
                                style: TextStyle(
                                    color: pnlColor(pnl),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            Text(fmtPct(pnlPct),
                                style: TextStyle(
                                    color: pnlColor(pnl), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    KeyValueRow('Giriş', '₺${fmtPrice(p.entryPrice)}'),
                    KeyValueRow('Güncel', '₺${fmtPrice(price)}'),
                    KeyValueRow('Teminat', fmtTl(p.margin)),
                    KeyValueRow(
                        'Likidasyon', '₺${fmtPrice(p.liquidationPrice)}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Likidasyon riski',
                            style: TextStyle(color: kMuted, fontSize: 12)),
                        const Spacer(),
                        Text('%${(risk * 100).toStringAsFixed(0)}',
                            style: TextStyle(
                                color: riskColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: max(risk, 0.02),
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Pozisyonu kapat'),
                        onPressed: () {
                          // Ekranda gördüğün fiyattan kapat; basış anından
                          // sonra gelen tik fiyatı sonucu değiştirmez.
                          final err = context
                              .read<GameController>()
                              .closePosition(p.id, atPrice: price);
                          if (err != null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(err)));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
