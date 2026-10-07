import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/category_style.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../data/assets_catalog.dart';
import '../models/asset.dart';
import '../state/game_controller.dart';
import '../widgets/common.dart';
import 'asset_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  AssetCategory? _filter;
  String _query = '';

  void _open(Asset a) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: a)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final q = _query.trim().toLowerCase();

    final assets = kAssets.where((a) {
      final okCat = _filter == null || a.category == _filter;
      final okQuery = q.isEmpty ||
          a.symbol.toLowerCase().contains(q) ||
          a.name.toLowerCase().contains(q);
      return okCat && okQuery;
    }).toList();

    final movers = [...kAssets]..sort((a, b) => game
        .changePercent(b.symbol)
        .abs()
        .compareTo(game.changePercent(a.symbol).abs()));

    final ret = game.totalReturnPercent;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (q.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: AppCard(
                    gradient: kHeroGradient,
                    borderColor: Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Toplam varlık',
                                  style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 2),
                              Text(
                                fmtTl(game.equity),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('Nakit: ${fmtTl(game.cash)}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ret >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                fmtPct(ret),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Hisse, coin, döviz ara...',
                    prefixIcon: const Icon(Icons.search, color: kMuted),
                    filled: true,
                    fillColor: kCard,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (q.isEmpty) ...[
                const SectionTitle('Öne çıkanlar', trailing: 'oturum değişimi'),
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 8,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) =>
                        _MoverCard(asset: movers[i], onTap: () => _open(movers[i])),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip(null, 'Tümü', Icons.apps, kAccent),
                    for (final c in AssetCategory.values)
                      _chip(c, c.label, c.icon, c.color),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (assets.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Text('Sonuç bulunamadı.',
                    style: TextStyle(color: kMuted)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final a = assets[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AssetRow(asset: a, onTap: () => _open(a)),
                  );
                },
                childCount: assets.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(AssetCategory? c, String label, IconData icon, Color color) {
    final selected = _filter == c;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
        label: Text(label),
        selected: selected,
        selectedColor: color.withOpacity(0.35),
        backgroundColor: kCard,
        side: BorderSide(color: selected ? color : Colors.white10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _filter = c),
      ),
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.asset, required this.onTap});

  final Asset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final price = game.priceOf(asset.symbol);
    final change = game.changePercent(asset.symbol);
    final hist = game.historyOf(asset.symbol);
    final c = change >= 0 ? kGreen : kRed;

    return SizedBox(
      width: 156,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withOpacity(0.20), kCard],
        ),
        borderColor: c.withOpacity(0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(asset.category.icon, size: 14, color: asset.category.color),
                const SizedBox(width: 6),
                Text(asset.symbol,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            PriceText(
              value: price,
              text: '₺${fmtPrice(price)}',
              style: const TextStyle(fontSize: 13, color: kMuted),
            ),
            const Spacer(),
            SizedBox(
              height: 28,
              child: Sparkline(values: hist.length > 40 ? hist.sublist(hist.length - 40) : hist),
            ),
            const SizedBox(height: 6),
            PnlPill(value: change, text: fmtPct(change), small: true),
          ],
        ),
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset, required this.onTap});

  final Asset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final price = game.priceOf(asset.symbol);
    final change = game.changePercent(asset.symbol);
    final hist = game.historyOf(asset.symbol);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AssetAvatar(asset: asset),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.symbol,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: 62,
            height: 30,
            child: Sparkline(
              values: hist.length > 40 ? hist.sublist(hist.length - 40) : hist,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceText(
                value: price,
                text: '₺${fmtPrice(price)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              PnlPill(value: change, text: fmtPct(change), small: true),
            ],
          ),
        ],
      ),
    );
  }
}
