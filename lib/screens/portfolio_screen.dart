import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/position.dart';
import '../state/game_controller.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final positions = g.positions;
    final ret = g.totalReturnPercent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Toplam varlık'),
                Text(
                  fmtTl(g.equity),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${fmtPct(ret)} (başlangıca göre)',
                  style: TextStyle(color: pnlColor(ret)),
                ),
                const SizedBox(height: 12),
                _stat('Nakit', fmtTl(g.cash)),
                _stat('Kullanılan teminat', fmtTl(g.usedMargin)),
                _stat('Açık pozisyon K/Z', fmtSigned(g.unrealizedPnl),
                    color: pnlColor(g.unrealizedPnl)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Açık pozisyonlar (${positions.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (positions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Açık pozisyonun yok. Piyasa sekmesinden işlem aç.'),
            ),
          ),
        for (final p in positions) _PositionCard(position: p),
      ],
    );
  }

  Widget _stat(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v, style: TextStyle(color: color))],
        ),
      );
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(p.symbol,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sideColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isLong ? 'LONG' : 'SHORT'} ${p.leverage}x',
                    style: TextStyle(color: sideColor, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fmtSigned(pnl),
                        style: TextStyle(
                            color: pnlColor(pnl), fontWeight: FontWeight.bold)),
                    Text(fmtPct(pnlPct),
                        style: TextStyle(color: pnlColor(pnl), fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row('Giriş fiyatı', '₺${fmtPrice(p.entryPrice)}'),
            _row('Güncel fiyat', '₺${fmtPrice(price)}'),
            _row('Teminat', fmtTl(p.margin)),
            _row('Likidasyon fiyatı', '₺${fmtPrice(p.liquidationPrice)}'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final err =
                      context.read<GameController>().closePosition(p.id);
                  if (err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
                child: const Text('Pozisyonu kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v)],
        ),
      );
}
