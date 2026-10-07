import 'package:intl/intl.dart';

import '../models/asset.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
final NumberFormat _price4 = NumberFormat('#,##0.0000', 'tr_TR');
final DateFormat _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

String fmtTl(double v) => '₺${_money.format(v)}';

final NumberFormat _price6 = NumberFormat('#,##0.000000', 'tr_TR');

String fmtPrice(double v) => v >= 10
    ? _money.format(v)
    : (v >= 0.1 ? _price4.format(v) : _price6.format(v));

/// Dolar tutarı: $1.234,56
String fmtUsd(double v) => '\$${_money.format(v)}';

/// Varlığın para birimine göre tutar: ₺1.234,56 ya da $1.234,56
String fmtMoney(double v, Currency c) =>
    c == Currency.usd ? fmtUsd(v) : fmtTl(v);

/// Fiyat (varlığın para birimi sembolüyle).
String fmtPriceIn(double v, Currency c) => '${c.symbol}${fmtPrice(v)}';

/// İşaretli tutar (+₺1,00 / -$1,00).
String fmtSignedIn(double v, Currency c) {
  final sign = v < 0 ? '-' : (v > 0 ? '+' : '');
  return '$sign${c.symbol}${_money.format(v.abs())}';
}

String fmtSigned(double v) {
  final sign = v < 0 ? '-' : (v > 0 ? '+' : '');
  return '$sign₺${_money.format(v.abs())}';
}

String fmtPct(double v) {
  final s = v.abs().toStringAsFixed(2).replaceAll('.', ',');
  final sign = v < 0 ? '-' : (v > 0 ? '+' : '');
  return '$sign$s%';
}

final NumberFormat _qty = NumberFormat('#,##0.######', 'tr_TR');

/// Adet gösterimi (en fazla 6 ondalık).
String fmtQty(double v) => _qty.format(v);

/// Metin kutusuna yazılacak adet ('.' ondalık, sondaki sıfırlar atılır).
String qtyInput(double v) {
  var s = v.toStringAsFixed(6);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'[.]$'), '');
  }
  return s;
}

String fmtDate(DateTime d) => _dateFmt.format(d);
