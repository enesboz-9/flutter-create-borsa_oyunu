import '../models/asset.dart';

/// ABD yaz saati uygulaması (Mart'ın 2. pazarı – Kasım'ın 1. pazarı).
bool _isUsDst(DateTime utc) {
  DateTime nthSunday(int year, int month, int n) {
    var d = DateTime.utc(year, month, 1);
    while (d.weekday != DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return d.add(Duration(days: 7 * (n - 1)));
  }

  final start = nthSunday(utc.year, 3, 2);
  final end = nthSunday(utc.year, 11, 1);
  final day = DateTime.utc(utc.year, utc.month, utc.day);
  return !day.isBefore(start) && day.isBefore(end);
}

/// Piyasa açık mı? (Türkiye saati, UTC+3 baz alınır.)
bool isMarketOpen(Asset asset, {DateTime? now}) {
  final utc = (now ?? DateTime.now()).toUtc();
  final t = utc.add(const Duration(hours: 3));
  final weekday = t.weekday < 6;
  switch (asset.category) {
    case AssetCategory.crypto:
      return true;
    case AssetCategory.forex:
    case AssetCategory.metal:
      return weekday;
    case AssetCategory.bist:
      {
        final mins = t.hour * 60 + t.minute;
        return weekday && mins >= 10 * 60 && mins < 18 * 60;
      }
    case AssetCategory.us:
      {
        // New York saati: 09:30 – 16:00 (yaz saatinde UTC-4, kışın UTC-5).
        final ny = utc.add(Duration(hours: _isUsDst(utc) ? -4 : -5));
        final mins = ny.hour * 60 + ny.minute;
        return ny.weekday < 6 && mins >= 9 * 60 + 30 && mins < 16 * 60;
      }
  }
}

/// Bugünkü seansın açılış anı (UTC). Yalnızca BIST ve ABD için anlamlıdır.
DateTime? sessionOpenUtc(Asset asset, {DateTime? now}) {
  final utc = (now ?? DateTime.now()).toUtc();
  switch (asset.category) {
    case AssetCategory.bist:
      final t = utc.add(const Duration(hours: 3));
      return DateTime.utc(t.year, t.month, t.day, 10).subtract(const Duration(hours: 3));
    case AssetCategory.us:
      final off = _isUsDst(utc) ? -4 : -5;
      final ny = utc.add(Duration(hours: off));
      return DateTime.utc(ny.year, ny.month, ny.day, 9, 30)
          .subtract(Duration(hours: off));
    default:
      return null;
  }
}
