import '../models/asset.dart';

/// Piyasa açık mı? (Türkiye saati, UTC+3 baz alınır.)
bool isMarketOpen(Asset asset, {DateTime? now}) {
  final t = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 3));
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
  }
}
