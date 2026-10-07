import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../data/assets_catalog.dart';
import '../models/asset.dart';
import '../state/game_controller.dart';
import 'asset_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  AssetCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final assets =
        kAssets.where((a) => _filter == null || a.category == _filter).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Text('Toplam varlık: '),
              Text(fmtTl(game.equity),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('Nakit: ${fmtTl(game.cash)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chip('Tümü', _filter == null, () => setState(() => _filter = null)),
              for (final c in AssetCategory.values)
                _chip(c.label, _filter == c, () => setState(() => _filter = c)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: assets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = assets[i];
              final price = game.priceOf(a.symbol);
              final change = game.changePercent(a.symbol);
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    a.symbol.substring(0, min(3, a.symbol.length)),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                title: Text(a.symbol,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(a.name),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₺${fmtPrice(price)}'),
                    Text(
                      fmtPct(change),
                      style: TextStyle(
                        color: change >= 0 ? kGreen : kRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssetDetailScreen(asset: a),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
