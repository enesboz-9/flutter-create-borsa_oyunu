import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../state/game_controller.dart';
import 'history_screen.dart';
import 'market_screen.dart';
import 'portfolio_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription<String>? _sub;

  static const _titles = ['Piyasa', 'Portföy', 'Geçmiş'];
  static const _pages = <Widget>[
    MarketScreen(),
    PortfolioScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _sub = context.read<GameController>().events.listen((message) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    });
  }

  @override
  void dispose() {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
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
