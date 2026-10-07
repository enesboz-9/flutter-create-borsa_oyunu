import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/position.dart';
import '../models/price_alert.dart';
import '../state/game_controller.dart';
import 'alerts_screen.dart';
import 'history_screen.dart';
import 'market_screen.dart';
import 'portfolio_screen.dart';
import 'trade_sheet.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription<String>? _sub;
  StreamSubscription<PriceAlert>? _alertSub;

  static const _titles = ['Piyasa', 'Portföy', 'Geçmiş'];
  static const _pages = <Widget>[
    MarketScreen(),
    PortfolioScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _alertSub = context.read<GameController>().alertHits.listen((a) {
      if (!mounted) return;
      _showAlertHit(a);
    });
    _sub = context.read<GameController>().events.listen((message) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    });
  }

  void _showAlertHit(PriceAlert a) {
    final g = context.read<GameController>();
    final asset = g.findAsset(a.symbol);
    final side = a.intent.side;
    final reached = a.triggeredPrice ?? a.targetPrice;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(a.auto
            ? 'Otomatik emir • ${a.symbol} ₺${fmtPrice(a.targetPrice)}: ${a.note ?? ''}'
            : 'Alarm: ${a.symbol} ₺${fmtPrice(a.targetPrice)} hedefine ulaştı (şu an ₺${fmtPrice(reached)}).'),
        action: (a.auto || asset == null || side == null)
            ? null
            : SnackBarAction(
                label: side == Side.long ? 'AL' : 'SAT',
                onPressed: () => showTradeSheet(context, asset, side),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oyunu sıfırla'),
        content: const Text(
            'Tüm pozisyonlar ve geçmiş silinir, bakiyen 1.000.000 ₺ olur.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<GameController>().resetGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount =
        context.select<GameController, int>((g) => g.positions.length);
    final alertCount =
        context.select<GameController, int>((g) => g.activeAlertCount);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Alarmlar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
            ),
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              child: Icon(
                alertCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: kMuted,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kMuted),
            onSelected: (v) {
              if (v == 'reset') _confirmReset();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reset', child: Text('Oyunu sıfırla')),
            ],
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Piyasa',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: openCount > 0,
              label: Text('$openCount'),
              child: const Icon(Icons.account_balance_wallet_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: openCount > 0,
              label: Text('$openCount'),
              child: const Icon(Icons.account_balance_wallet),
            ),
            label: 'Portföy',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: 'Geçmiş',
          ),
        ],
      ),
    );
  }
}
