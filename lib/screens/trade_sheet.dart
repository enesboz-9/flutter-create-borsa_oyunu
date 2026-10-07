import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../state/game_controller.dart';
import '../widgets/common.dart';

class TradeSheet extends StatefulWidget {
  const TradeSheet({super.key, required this.asset, required this.side});

  final Asset asset;
  final Side side;

  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  final _marginCtrl = TextEditingController();
  int _leverage = 1;
  String? _error;

  double get _margin =>
      double.tryParse(_marginCtrl.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _marginCtrl.dispose();
    super.dispose();
  }

  /// Komisyon dahil, eldeki nakitle açılabilecek en yüksek teminat.
  double _maxMargin(GameController g) {
    final rate = widget.asset.category.commissionRate;
    final raw = g.cash / (1 + _leverage * rate);
    return (raw * 100).floorToDouble() / 100;
  }

  void _setPercent(GameController g, int pct) {
    final v = (_maxMargin(g) * pct / 100 * 100).floorToDouble() / 100;
    setState(() {
      _marginCtrl.text = v.toStringAsFixed(2);
      _error = null;
    });
  }

  void _submit() {
    final err = context.read<GameController>().openPosition(
          asset: widget.asset,
          side: widget.side,
          margin: _margin,
          leverage: _leverage,
        );
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pop(context);
    }
  }

  Color _riskColor(int maxLev) {
    final ratio = _leverage / maxLev;
    if (ratio < 0.34) return kGreen;
    if (ratio < 0.67) return Colors.orangeAccent;
    return kRed;
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final asset = widget.asset;
    final isLong = widget.side == Side.long;
    final color = isLong ? kGreen : kRed;
    final price = g.priceOf(asset.symbol);
    final notional = _margin * _leverage;
    final commission = g.commissionFor(asset, _margin, _leverage);
    final liq = Position.liquidationPriceFor(
        side: widget.side, entryPrice: price, leverage: _leverage);
    final liqDistance =
        (1 / _leverage - GameConfig.maintenanceMargin) * 100;
    final maxLev = asset.category.maxLeverage;
    final risk = _riskColor(maxLev);
    final quickLeverages =
        const [1, 2, 5, 10, 25, 50, 100].where((l) => l <= maxLev).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isLong ? kBuyGradient : kSellGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isLong ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isLong ? 'AL (Long)' : 'SAT (Short)'} • ${asset.symbol}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        'Güncel fiyat: ₺${fmtPrice(price)}',
                        style: const TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kullanılabilir nakit',
                    style: TextStyle(color: kMuted)),
                Text(fmtTl(g.cash),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _marginCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Teminat',
                prefixText: '₺ ',
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final pct in const [10, 25, 50, 100]) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _setPercent(g, pct),
                      child: Text('%$pct'),
                    ),
                  ),
                  if (pct != 100) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kaldıraç',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: risk.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_leverage}x',
                      style: TextStyle(
                          color: risk,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: risk,
                thumbColor: risk,
                inactiveTrackColor: Colors.white12,
              ),
              child: Slider(
                value: _leverage.toDouble(),
                min: 1,
                max: maxLev.toDouble(),
                divisions: maxLev > 1 ? maxLev - 1 : null,
                onChanged: (v) => setState(() {
                  _leverage = v.round();
                  _error = null;
                }),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final l in quickLeverages)
                  ChoiceChip(
                    label: Text('${l}x'),
                    selected: _leverage == l,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _leverage = l;
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  KeyValueRow('Pozisyon büyüklüğü', fmtTl(notional)),
                  KeyValueRow('Komisyon', fmtTl(commission)),
                  KeyValueRow('Toplam gereken', fmtTl(_margin + commission),
                      bold: true),
                  const Divider(color: Colors.white10, height: 14),
                  KeyValueRow('Likidasyon fiyatı', '₺${fmtPrice(liq)}',
                      valueColor: risk),
                  KeyValueRow('Likidasyona mesafe',
                      '%${liqDistance.toStringAsFixed(1).replaceAll('.', ',')}',
                      valueColor: risk),
                ],
              ),
            ),
            if (_leverage > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: risk),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Fiyat likidasyon seviyesine ulaşırsa teminatın tamamını kaybedersin.',
                        style: TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    style: const TextStyle(
                        color: kRed, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Onayla',
              icon: isLong ? Icons.trending_up : Icons.trending_down,
              gradient: isLong ? kBuyGradient : kSellGradient,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
