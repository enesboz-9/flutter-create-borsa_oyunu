import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/position.dart';
import '../models/trade_record.dart';
import '../state/game_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<GameController>().history;
    if (history.isEmpty) {
      return const Center(child: Text('Henüz kapanmış işlem yok.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, i) => _RecordCard(record: history[i]),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final TradeRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final isLong = r.side == Side.long;
    final liquidated = r.reason == CloseReason.liquidation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(r.symbol,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '${isLong ? 'LONG' : 'SHORT'} ${r.leverage}x',
                  style: TextStyle(color: isLong ? kGreen : kRed, fontSize: 12),
                ),
                if (liquidated) ...[
                  const SizedBox(width: 8),
                  const Text('LİKİDE',
                      style: TextStyle(
                          color: kRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
                const Spacer(),
                Text(
                  fmtSigned(r.netPnl),
                  style: TextStyle(
                      color: pnlColor(r.netPnl), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row('Giriş → Çıkış',
                '₺${fmtPrice(r.entryPrice)} → ₺${fmtPrice(r.exitPrice)}'),
            _row('Teminat', fmtTl(r.margin)),
            _row('Brüt K/Z', fmtSigned(r.grossPnl)),
            _row('Komisyon', fmtTl(r.commission)),
            _row('Kapanış', fmtDate(r.closedAt)),
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
