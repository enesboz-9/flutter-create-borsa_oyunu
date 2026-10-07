import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../state/game_controller.dart';
import '../widgets/common.dart';

void showExchangeSheet(BuildContext context, {bool sell = false}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ExchangeSheet(initialSell: sell),
    ),
  );
}

/// TL ile dolar alma / doları TL'ye çevirme sayfası.
/// ABD hisseleri yalnızca dolar bakiyesiyle alınabilir.
class ExchangeSheet extends StatefulWidget {
  const ExchangeSheet({super.key, this.initialSell = false});

  final bool initialSell;

  @override
  State<ExchangeSheet> createState() => _ExchangeSheetState();
}

class _ExchangeSheetState extends State<ExchangeSheet> {
  final _ctrl = TextEditingController();
  late bool _sell = widget.initialSell;
  String? _error;

  /// Ekranda en son gösterilen kur. Onaya basınca işlem bu kurdan yapılır.
  double _shownRate = 0;

  double get _usd => double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _max(GameController g) {
    if (_sell) return (g.usdCash * 100).floorToDouble() / 100;
    return g.maxBuyableUsd;
  }

  void _setPercent(GameController g, int pct) {
    final v = (_max(g) * pct / 100 * 100).floorToDouble() / 100;
    setState(() {
      _ctrl.text = v.toStringAsFixed(2);
      _error = null;
    });
  }

  void _submit() {
    final g = context.read<GameController>();
    final rate = _shownRate > 0 ? _shownRate : null;
    final err = _sell
        ? g.sellUsd(_usd, atRate: rate)
        : g.buyUsd(_usd, atRate: rate);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final rate = g.usdTry;
    _shownRate = rate;
    final usd = _usd;
    final tl = usd * rate;
    final commission = tl * GameConfig.exchangeCommission;
    final color = _sell ? kRed : kGreen;

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
                    gradient: _sell ? kSellGradient : kBuyGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      const Icon(Icons.currency_exchange, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dolar Al / Sat',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Güncel kur: ₺${fmtPrice(rate)}',
                          style:
                              const TextStyle(color: kMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Dolar al (TL → USD)'),
                  selected: !_sell,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _sell = false;
                    _ctrl.clear();
                    _error = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Dolar sat (USD → TL)'),
                  selected: _sell,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _sell = true;
                    _ctrl.clear();
                    _error = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  KeyValueRow('TL nakit', fmtTl(g.cash)),
                  KeyValueRow('Dolar bakiyesi', fmtUsd(g.usdCash),
                      bold: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: _sell ? 'Satılacak dolar' : 'Alınacak dolar',
                prefixText: r'$ ',
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
                for (final pct in const [25, 50, 75, 100]) ...[
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
            const SizedBox(height: 16),
            AppCard(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  KeyValueRow('Kur', '₺${fmtPrice(rate)}'),
                  KeyValueRow('TL karşılığı', fmtTl(tl)),
                  KeyValueRow('Komisyon', fmtTl(commission)),
                  const Divider(color: Colors.white10, height: 14),
                  KeyValueRow(
                    _sell ? 'Hesabına geçecek TL' : 'Ödenecek TL',
                    fmtTl(_sell ? tl - commission : tl + commission),
                    bold: true,
                    valueColor: color,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Dolar bakiyen ABD hisseleri alırken kullanılır ve toplam varlığında TL karşılığıyla görünür.',
                style: TextStyle(color: kMuted, fontSize: 12),
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
              label: _sell ? 'Dolar sat' : 'Dolar al',
              icon: Icons.currency_exchange,
              gradient: _sell ? kSellGradient : kBuyGradient,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
