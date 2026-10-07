import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
final NumberFormat _price4 = NumberFormat('#,##0.0000', 'tr_TR');
final DateFormat _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

String fmtTl(double v) => '₺${_money.format(v)}';

String fmtPrice(double v) => v >= 10 ? _money.format(v) : _price4.format(v);

String fmtSigned(double v) {
  final sign = v < 0 ? '-' : (v > 0 ? '+' : '');
  return '$sign₺${_money.format(v.abs())}';
}

String fmtPct(double v) {
  final s = v.abs().toStringAsFixed(2).replaceAll('.', ',');
  final sign = v < 0 ? '-' : (v > 0 ? '+' : '');
  return '$sign$s%';
}

String fmtDate(DateTime d) => _dateFmt.format(d);
