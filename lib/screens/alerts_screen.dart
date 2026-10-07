import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/price_alert.dart';
import '../state/game_controller.dart';
import '../widgets/alert_tile.dart';
import 'asset_detail_screen.dart';

/// Tüm fiyat alarmlarının listesi.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final active = g.alerts.where((a) => a.isActive).toList();
    final done = g.alerts.where((a) => !a.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmlar', style: TextStyle(fontSize: 22)),
        actions: [
          if (done.isNotEmpty)
            TextButton(
              onPressed: () =>
                  context.read<GameController>().clearTriggeredAlerts(),
              child: const Text('Tetiklenenleri temizle'),
            ),
        ],
      ),
      body: g.alerts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 44, color: kMuted),
                    SizedBox(height: 10),
                    Text('Henüz alarm yok.',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(
                      'Bir varlığın detay sayfasındaki zil simgesinden fiyat alarmı kurabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kMuted),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (active.isNotEmpty) ...[
                  Text('Aktif (${active.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  for (final a in active) _row(context, g, a),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Tetiklenenler (${done.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  for (final a in done) _row(context, g, a),
                ],
              ],
            ),
    );
  }

  Widget _row(BuildContext context, GameController g, PriceAlert a) {
    final asset = g.findAsset(a.symbol);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AlertTile(
        alert: a,
        showSymbol: true,
        currentPrice: g.priceOf(a.symbol),
        onDelete: () => context.read<GameController>().removeAlert(a.id),
        onTap: asset == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AssetDetailScreen(asset: asset),
                )),
      ),
    );
  }
}
