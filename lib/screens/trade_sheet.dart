import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../state/game_controller.dart';

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
    final maxLev = asset.category.maxLeverage;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isLong ? 'AL (Long)' : 'SAT (Short)'} • ${asset.symbol}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Güncel fiyat: ₺${fmtPrice(price)}  •  Nakit: ${fmtTl(g.cash)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _marginCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Teminat (₺)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final pct in const [10, 25, 50, 100])
                  ActionChip(
                    label: Text('%$pct'),
                    onPressed: () => _setPercent(g, pct),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Kaldıraç: ${_leverage}x'),
            Slider(
              value: _leverage.toDouble(),
              min: 1,
              max: maxLev.toDouble(),
              divisions: maxLev > 1 ? maxLev - 1 : null,
              label: '${_leverage}x',
              onChanged: (v) => setState(() {
                _leverage = v.round();
                _error = null;
              }),
            ),
            const Divider(),
            _row('Pozisyon büyüklüğü', fmtTl(notional)),
            _row('Komisyon', fmtTl(commission)),
            _row('Toplam gereken', fmtTl(_margin + commission)),
            _row('Likidasyon fiyatı', '₺${fmtPrice(liq)}'),
            if (_leverage > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Fiyat likidasyon seviyesine ulaşırsa teminatın tamamını kaybedersin.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: kRed)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: isLong ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                child: const Text('Onayla'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v)],
        ),
      );
}
