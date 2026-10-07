import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/position.dart';
import '../models/trade_record.dart';
import '../state/game_controller.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<GameController>().history;
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 44, color: kMuted),
            SizedBox(height: 10),
            Text('Henüz kapanmış işlem yok.',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final wins = history.where((r) => r.netPnl > 0).length;
    final liquidations =
        history.where((r) => r.reason == CloseReason.liquidation).length;
    final totalNet = history.fold<double>(0, (s, r) => s + r.netPnl);
    final winRate = wins / history.length * 100;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  _stat('Toplam işlem', '${history.length}'),
                  _stat('Kazanma oranı',
                      '%${winRate.toStringAsFixed(0)}'),
                  _stat('Likidasyon', '$liquidations',
                      color: liquidations > 0 ? kRed : null),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam net K/Z',
                      style: TextStyle(color: kMuted)),
                  Text(
                    fmtSigned(totalNet),
                    style: TextStyle(
                      color: pnlColor(totalNet),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final r in history)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecordCard(record: r),
          ),
      ],
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          ],
        ),
      );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final TradeRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final isLong = r.side == Side.long;
    final liquidated = r.reason == CloseReason.liquidation;
    final sideColor = isLong ? kGreen : kRed;

    return AppCard(
      borderColor: liquidated ? kRed.withOpacity(0.5) : null,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sideColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLong ? Icons.arrow_upward : Icons.arrow_downward,
                  color: sideColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.symbol,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '${isLong ? 'LONG' : 'SHORT'} ${r.leverage}x',
                          style: TextStyle(
                              color: sideColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                        if (liquidated) ...[
                          const SizedBox(width: 6),
                          const PnlPill(
                              value: -1, text: 'LİKİDE', small: true),
                        ],
                      ],
                    ),
                    Text(fmtDate(r.closedAt),
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                fmtSigned(r.netPnl),
                style: TextStyle(
                  color: pnlColor(r.netPnl),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 6),
          KeyValueRow('Giriş → Çıkış',
              '₺${fmtPrice(r.entryPrice)} → ₺${fmtPrice(r.exitPrice)}'),
          KeyValueRow('Teminat', fmtTl(r.margin)),
          KeyValueRow('Brüt K/Z', fmtSigned(r.grossPnl),
              valueColor: pnlColor(r.grossPnl)),
          KeyValueRow('Komisyon', fmtTl(r.commission)),
        ],
      ),
    );
  }
}
