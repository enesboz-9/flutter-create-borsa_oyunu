import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../models/asset.dart';
import '../models/pending_order.dart';

/// Emir türü seçimi (Piyasa / Limit / Stop) ve gerekirse emir fiyatı alanı.
class OrderTypePicker extends StatelessWidget {
  const OrderTypePicker({
    super.key,
    required this.type,
    required this.isBuy,
    required this.marketOpen,
    required this.currency,
    required this.priceController,
    required this.onTypeChanged,
    required this.onPriceChanged,
  });

  final OrderType type;

  /// Emir alış yönlü mü? (long açmak / short kapatmak = alış)
  final bool isBuy;
  final bool marketOpen;
  final Currency currency;
  final TextEditingController priceController;
  final ValueChanged<OrderType> onTypeChanged;
  final VoidCallback onPriceChanged;

  String get _hint {
    switch (type) {
      case OrderType.market:
        return marketOpen
            ? 'Güncel fiyattan anında işleme girer.'
            : 'Piyasa kapalı: emir kuyruğa alınır, açılışta ilk fiyattan işleme girer.';
      case OrderType.limit:
        return isBuy
            ? 'Fiyat bu seviyeye ya da altına düşünce alınır. Yalnızca piyasa açıkken işleme girer.'
            : 'Fiyat bu seviyeye ya da üstüne çıkınca satılır. Yalnızca piyasa açıkken işleme girer.';
      case OrderType.stop:
        return isBuy
            ? 'Fiyat bu seviyeye ya da üstüne çıkınca piyasa emri olarak alınır.'
            : 'Fiyat bu seviyeye ya da altına inince piyasa emri olarak satılır (zarar durdur).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emir türü', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in OrderType.values)
              ChoiceChip(
                label: Text(t.label),
                selected: type == t,
                showCheckmark: false,
                onSelected: (_) => onTypeChanged(t),
              ),
          ],
        ),
        if (type != OrderType.market) ...[
          const SizedBox(height: 10),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: '${type.label} emir fiyatı',
              prefixText: '${currency.symbol} ',
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => onPriceChanged(),
          ),
        ],
        const SizedBox(height: 6),
        Text(_hint, style: const TextStyle(color: kMuted, fontSize: 12)),
      ],
    );
  }
}

/// Piyasa kapalıyken gösterilen bilgi şeridi.
class MarketClosedBanner extends StatelessWidget {
  const MarketClosedBanner({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$status. Alım-satım yapılamaz ama emir verebilirsin; '
              'emrin kuyrukta bekler ve piyasa açılınca işleme girer.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
