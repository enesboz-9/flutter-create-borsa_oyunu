import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/price_alert.dart';
import 'common.dart';

/// Tek bir fiyat alarmı satırı.
class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
    required this.currentPrice,
    required this.onDelete,
    this.showSymbol = false,
    this.onTap,
  });

  final PriceAlert alert;
  final double currentPrice;
  final VoidCallback onDelete;
  final bool showSymbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final up = alert.direction == AlertDirection.above;
    final active = alert.isActive;
    final color = active ? (up ? kGreen : kRed) : kMuted;

    final isBuy = alert.intent == AlertIntent.buy;
    final String subtitle;
    if (active) {
      final dist = currentPrice > 0
          ? (alert.targetPrice - currentPrice) / currentPrice * 100
          : 0.0;
      final distText = dist.abs().toStringAsFixed(2).replaceAll('.', ',');
      subtitle =
          '${alert.auto ? '${alert.orderSummary} • ' : ''}${up ? 'Yukarı' : 'Aşağı'} yönlü • şu an %$distText uzakta';
    } else {
      subtitle =
          '${alert.note != null ? '${alert.note}\n' : ''}Tetiklendi • ${fmtDate(alert.triggeredAt!)} • ₺${fmtPrice(alert.triggeredPrice ?? alert.targetPrice)}';
    }

    return AppCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              active
                  ? (up ? Icons.north_east : Icons.south_east)
                  : Icons.notifications_off_outlined,
              color: color,
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
                    Flexible(
                      child: Text(
                        showSymbol
                            ? '${alert.symbol}  ₺${fmtPrice(alert.targetPrice)}'
                            : '₺${fmtPrice(alert.targetPrice)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: active ? null : kMuted,
                        ),
                      ),
                    ),
                    if (alert.intent != AlertIntent.none) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isBuy ? kGreen : kRed)
                              .withOpacity(active ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          alert.auto
                              ? 'OTO ${alert.intent.label.toUpperCase()}'
                              : alert.intent.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: active ? (isBuy ? kGreen : kRed) : kMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: kMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Alarmı sil',
            icon: const Icon(Icons.delete_outline, color: kMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
