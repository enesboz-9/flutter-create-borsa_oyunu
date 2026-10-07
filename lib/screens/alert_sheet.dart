import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/asset.dart';
import '../models/price_alert.dart';
import '../state/game_controller.dart';
import '../widgets/alert_tile.dart';
import '../widgets/common.dart';

const LinearGradient _kAlertGradient = LinearGradient(
  colors: [Color(0xFF8E7DFF), kAccent],
);

void showAlertSheet(BuildContext context, Asset asset) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: AlertSheet(asset: asset),
    ),
  );
}

/// Bir varlık için fiyat alarmı kurma ve o varlığın alarmlarını yönetme.
class AlertSheet extends StatefulWidget {
  const AlertSheet({super.key, required this.asset});

  final Asset asset;

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> {
  final _ctrl = TextEditingController();
  AlertIntent _intent = AlertIntent.none;
  String? _error;

  double get _target => double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setPct(double price, double pct) {
    final v = price * (1 + pct / 100);
    setState(() {
      _ctrl.text = v.toStringAsFixed(v >= 10 ? 2 : 4);
      _error = null;
    });
  }

  void _submit() {
    final err = context.read<GameController>().addAlert(
          asset: widget.asset,
          targetPrice: _target,
          intent: _intent,
        );
    setState(() {
      _error = err;
      if (err == null) {
        _ctrl.clear();
        _intent = AlertIntent.none;
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
    return 'Fiyat ₺${fmtPrice(t)} seviyesine $dir haber verilir (${fmtPct(pct)}).';
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final asset = widget.asset;
    final price = g.priceOf(asset.symbol);
    final mine = g.alertsFor(asset.symbol);

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
                      Text('Fiyat alarmı • ${asset.symbol}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Güncel fiyat: ₺${fmtPrice(price)}',
                          style:
                              const TextStyle(color: kMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Hedef fiyat',
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
            const SizedBox(height: 14),
            const Text('Tetiklenince ne yapmak istiyorsun?',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final i in AlertIntent.values)
                  ChoiceChip(
                    label: Text(i.label),
                    selected: _intent == i,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _intent = i),
                  ),
              ],
            ),
            if (_intent != AlertIntent.none)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Alarm çalınca tek dokunuşla ${_intent == AlertIntent.buy ? 'AL' : 'SAT'} ekranı açılır. İşlem otomatik açılmaz.',
                  style: const TextStyle(color: kMuted, fontSize: 12),
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
              label: 'Alarm kur',
              icon: Icons.add_alert_outlined,
              gradient: _kAlertGradient,
              onPressed: _submit,
            ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('${asset.symbol} alarmların (${mine.length})',
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
