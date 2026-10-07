import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../state/game_controller.dart';
import '../widgets/common.dart';

void showCloseSheet(BuildContext context, String positionId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: CloseSheet(positionId: positionId),
    ),
  );
}

/// Pozisyonun tamamını ya da bir kısmını (adet veya yüzde) satma sayfası.
class CloseSheet extends StatefulWidget {
  const CloseSheet({super.key, required this.positionId});

  final String positionId;

  @override
  State<CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<CloseSheet> {
  final _qtyCtrl = TextEditingController();
  int? _pct = 100; // Seçili yüzde; elle adet yazılınca null olur.
  bool _initialized = false;
  String? _error;

  /// Ekranda en son gösterilen fiyat. Onaya basınca satış bu fiyattan yapılır.
  double _shownPrice = 0;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  double _qtyFor(Position p) {
    if (_pct != null) return p.quantity * _pct! / 100;
    return double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
  }

  void _selectPct(Position p, int pct) {
    setState(() {
      _pct = pct;
      _qtyCtrl.text = qtyInput(p.quantity * pct / 100);
      _error = null;
    });
  }

  void _submit(Position p) {
    final qty = _qtyFor(p);
    final err = context.read<GameController>().closePosition(
          p.id,
          atPrice: _shownPrice > 0 ? _shownPrice : null,
          // %100 seçiliyse tamamını kapat (yuvarlama artığı kalmasın).
          quantity: _pct == 100 ? null : qty,
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
    final p = g.positionById(widget.positionId);
    if (p == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Text('Bu pozisyon artık açık değil.',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }
    if (!_initialized) {
      _initialized = true;
      _qtyCtrl.text = qtyInput(p.quantity);
    }

    final asset = g.assetOf(p.symbol);
    final price = g.priceOf(p.symbol);
    _shownPrice = price;
    final isLong = p.side == Side.long;
    final color = isLong ? kGreen : kRed;

    final qty = _qtyFor(p);
    final valid = qty > 0 && qty <= p.quantity * (1 + 1e-9);
    final full = valid && qty >= p.quantity * (1 - 1e-9);
    final shown = full ? p.quantity : qty;
    final f = valid ? shown / p.quantity : 0.0;
    final gross = isLong
        ? (price - p.entryPrice) * shown
        : (p.entryPrice - price) * shown;
    final closeComm = price * shown * asset.category.commissionRate;
    final openCommPart = p.openCommission * f;
    final net = gross - openCommPart - closeComm;
    final proceeds = valid ? (p.margin * f + gross - closeComm) : 0.0;
    final remaining = valid ? (full ? 0.0 : p.quantity - shown) : p.quantity;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AssetAvatar(asset: asset, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isLong ? 'SAT' : 'KAPAT'} • ${p.symbol}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                      Text('Güncel fiyat: ₺${fmtPrice(price)}',
                          style:
                              const TextStyle(color: kMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  KeyValueRow('Eldeki adet', fmtQty(p.quantity)),
                  KeyValueRow(
                      'Ort. maliyet (komisyon dahil)', '₺${fmtPrice(p.avgCost)}'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Satılacak adet',
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {
                _pct = null;
                _error = null;
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final pct in const [25, 50, 75, 100]) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _pct == pct ? color : Colors.white24,
                        ),
                        backgroundColor:
                            _pct == pct ? color.withOpacity(0.15) : null,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _selectPct(p, pct),
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
                  KeyValueRow('Satış fiyatı', '₺${fmtPrice(price)}'),
                  KeyValueRow('Satış tutarı', fmtTl(price * shown)),
                  KeyValueRow('Satış komisyonu', fmtTl(closeComm)),
                  KeyValueRow('Net K/Z (açılış komisyonu dahil)',
                      fmtSigned(net),
                      valueColor: pnlColor(net)),
                  const Divider(color: Colors.white10, height: 14),
                  KeyValueRow('Hesabına geçecek', fmtTl(proceeds), bold: true),
                  KeyValueRow('Kalan adet', fmtQty(remaining)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    style: const TextStyle(
                        color: kRed, fontWeight: FontWeight.w600)),
              )
            else if (qty > 0 && !valid)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                    'Elindeki adetten fazlasını satamazsın (${fmtQty(p.quantity)}).',
                    style: const TextStyle(
                        color: kRed, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            GradientButton(
              label: full ? 'Tamamını ${isLong ? 'sat' : 'kapat'}' : 'Onayla',
              icon: Icons.sell_outlined,
              gradient: kSellGradient,
              onPressed: valid ? () => _submit(p) : () {},
            ),
          ],
        ),
      ),
    );
  }
}
