import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../models/price_alert.dart';
import '../state/game_controller.dart';
import '../widgets/alert_tile.dart';
import '../widgets/common.dart';

const LinearGradient _kAlertGradient = LinearGradient(
  colors: [Color(0xFF8E7DFF), kAccent],
);

void showAlertSheet(
  BuildContext context,
  Asset asset, {
  AlertSheetMode initialMode = AlertSheetMode.notify,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: AlertSheet(asset: asset, initialMode: initialMode),
    ),
  );
}

/// Alarm sayfasının açılışta seçili olan modu.
enum AlertSheetMode { notify, buy, sell }

/// Bir varlık için fiyat alarmı / otomatik emir kurma ve yönetme.
class AlertSheet extends StatefulWidget {
  const AlertSheet({
    super.key,
    required this.asset,
    this.initialMode = AlertSheetMode.notify,
  });

  final Asset asset;
  final AlertSheetMode initialMode;

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> {
  final _targetCtrl = TextEditingController();
  final _marginCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  late AlertSheetMode _mode = widget.initialMode;
  int _leverage = 1;
  bool _sellByPercent = true;
  int _sellPercent = 100;
  String? _error;

  static double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  double get _target => _num(_targetCtrl);

  @override
  void dispose() {
    _targetCtrl.dispose();
    _marginCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _setPct(double price, double pct) {
    final v = price * (1 + pct / 100);
    setState(() {
      _targetCtrl.text = v.toStringAsFixed(v >= 10 ? 2 : 4);
      _error = null;
    });
  }

  void _setMarginPct(GameController g, int pct) {
    final rate = widget.asset.category.commissionRate;
    final maxMargin =
        g.cashOf(widget.asset.currency) / (1 + _leverage * rate);
    final v = (maxMargin * pct / 100 * 100).floorToDouble() / 100;
    setState(() {
      _marginCtrl.text = v.toStringAsFixed(2);
      _error = null;
    });
  }

  void _submit() {
    final g = context.read<GameController>();
    final String? err;
    switch (_mode) {
      case AlertSheetMode.notify:
        err = g.addAlert(asset: widget.asset, targetPrice: _target);
      case AlertSheetMode.buy:
        err = g.addAlert(
          asset: widget.asset,
          targetPrice: _target,
          intent: AlertIntent.buy,
          auto: true,
          orderMargin: _num(_marginCtrl),
          orderLeverage: _leverage,
        );
      case AlertSheetMode.sell:
        err = g.addAlert(
          asset: widget.asset,
          targetPrice: _target,
          intent: AlertIntent.sell,
          auto: true,
          orderPercent: _sellByPercent ? _sellPercent.toDouble() : null,
          orderQuantity: _sellByPercent ? null : _num(_qtyCtrl),
        );
    }
    setState(() {
      _error = err;
      if (err == null) {
        _targetCtrl.clear();
        _marginCtrl.clear();
        _qtyCtrl.clear();
        _mode = AlertSheetMode.notify;
        _leverage = 1;
      }
    });
  }

  String _hint(double price) {
    final t = _target;
    if (t <= 0 || price <= 0) {
      return 'Hedef fiyatı yaz ya da aşağıdan hızlı seç.';
    }
    final pct = (t - price) / price * 100;
    final dir = t > price ? 'yukarı çıkınca' : 'aşağı inince';
    return 'Fiyat ${fmtPriceIn(t, widget.asset.currency)} seviyesine $dir tetiklenir (${fmtPct(pct)}).';
  }

  InputDecoration _dec(String label, {String? prefix}) => InputDecoration(
        labelText: label,
        prefixText: prefix,
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  static final _numFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  Widget _buyConfig(GameController g) {
    final asset = widget.asset;
    final maxLev = asset.category.maxLeverage;
    final quick =
        const [1, 2, 5, 10, 25, 50, 100].where((l) => l <= maxLev).toList();
    final margin = _num(_marginCtrl);
    final t = _target;
    final qty = t > 0 ? margin * _leverage / t : 0.0;
    final comm = g.commissionFor(asset, margin, _leverage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _marginCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_numFormatter],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: _dec('Alınacak teminat',
              prefix: '${asset.currency.symbol} '),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 8),
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
                  onPressed: () => _setMarginPct(g, pct),
                  child: Text('%$pct'),
                ),
              ),
              if (pct != 100) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 4),
        const Text('Yüzdeler şu anki nakdine göre hesaplanır.',
            style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Kaldıraç',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  for (final l in quick)
                    ChoiceChip(
                      label: Text('${l}x'),
                      selected: _leverage == l,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _leverage = l),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (margin > 0 && t > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tetiklenince ≈ ${fmtQty(qty)} adet alınır • komisyon ${fmtMoney(comm, asset.currency)}',
              style: const TextStyle(color: kMuted, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            asset.currency == Currency.usd
                ? 'Tetiklenme anında dolar bakiyen yetersizse emir gerçekleşmez. ABD hisseleri için önce dolar almış olmalısın.'
                : 'Tetiklenme anında nakdin yetersizse emir gerçekleşmez.',
            style: const TextStyle(color: kMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _sellConfig(GameController g) {
    final held = g.positions
        .where((p) => p.symbol == widget.asset.symbol && p.side == Side.long)
        .fold<double>(0, (s, p) => s + p.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Yüzde'),
              selected: _sellByPercent,
              showCheckmark: false,
              onSelected: (_) => setState(() => _sellByPercent = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Adet'),
              selected: !_sellByPercent,
              showCheckmark: false,
              onSelected: (_) => setState(() => _sellByPercent = false),
            ),
            const Spacer(),
            Text('Elindeki: ${fmtQty(held)} adet',
                style: const TextStyle(color: kMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        if (_sellByPercent)
          Row(
            children: [
              for (final pct in const [25, 50, 75, 100]) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: _sellPercent == pct ? kRed : Colors.white24),
                      backgroundColor: _sellPercent == pct
                          ? kRed.withOpacity(0.15)
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _sellPercent = pct),
                    child: Text('%$pct'),
                  ),
                ),
                if (pct != 100) const SizedBox(width: 8),
              ],
            ],
          )
        else
          TextField(
            controller: _qtyCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_numFormatter],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: _dec('Satılacak adet'),
            onChanged: (_) => setState(() => _error = null),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Tetiklenince eldeki long pozisyonlardan satılır. Satılacak pozisyon yoksa emir gerçekleşmez.',
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final asset = widget.asset;
    final price = g.priceOf(asset.symbol);
    final mine = g.alertsFor(asset.symbol);
    final label = switch (_mode) {
      AlertSheetMode.notify => 'Alarm kur',
      AlertSheetMode.buy => 'Otomatik AL emri kur',
      AlertSheetMode.sell => 'Otomatik SAT emri kur',
    };

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
                    gradient: _kAlertGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alarm ve emir • ${asset.symbol}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Güncel fiyat: ${fmtPriceIn(price, asset.currency)}',
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
                  label: const Text('Sadece haber ver'),
                  selected: _mode == AlertSheetMode.notify,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _mode = AlertSheetMode.notify),
                ),
                ChoiceChip(
                  label: const Text('Otomatik AL'),
                  selected: _mode == AlertSheetMode.buy,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _mode = AlertSheetMode.buy),
                ),
                ChoiceChip(
                  label: const Text('Otomatik SAT'),
                  selected: _mode == AlertSheetMode.sell,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _mode = AlertSheetMode.sell),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_numFormatter],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: _dec('Hedef fiyat', prefix: '${asset.currency.symbol} '),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 6),
            Text(_hint(price),
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final pct in const [-10.0, -5.0, -1.0, 1.0, 5.0, 10.0])
                  ActionChip(
                    label: Text(
                        '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(0)}%'),
                    onPressed: () => _setPct(price, pct),
                  ),
              ],
            ),
            if (_mode == AlertSheetMode.buy) _buyConfig(g),
            if (_mode == AlertSheetMode.sell) _sellConfig(g),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    style: const TextStyle(
                        color: kRed, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            GradientButton(
              label: label,
              icon: _mode == AlertSheetMode.notify
                  ? Icons.add_alert_outlined
                  : Icons.bolt,
              gradient: switch (_mode) {
                AlertSheetMode.notify => _kAlertGradient,
                AlertSheetMode.buy => kBuyGradient,
                AlertSheetMode.sell => kSellGradient,
              },
              onPressed: _submit,
            ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('${asset.symbol} alarm ve emirlerin (${mine.length})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final a in mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AlertTile(
                    alert: a,
                    currentPrice: price,
                    onDelete: () =>
                        context.read<GameController>().removeAlert(a.id),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
