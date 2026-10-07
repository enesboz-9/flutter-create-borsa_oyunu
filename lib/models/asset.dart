enum AssetCategory { bist, crypto, forex, metal }

extension AssetCategoryX on AssetCategory {
  String get label => switch (this) {
        AssetCategory.bist => 'Borsa İstanbul',
        AssetCategory.crypto => 'Kripto',
        AssetCategory.forex => 'Döviz',
        AssetCategory.metal => 'Değerli Metaller',
      };

  /// İşlem komisyon oranı (açılışta ve kapanışta pozisyon büyüklüğü üzerinden).
  double get commissionRate => switch (this) {
        AssetCategory.bist => 0.002,
        AssetCategory.crypto => 0.001,
        AssetCategory.forex => 0.0005,
        AssetCategory.metal => 0.001,
      };

  int get maxLeverage => switch (this) {
        AssetCategory.bist => 5,
        AssetCategory.crypto => 50,
        AssetCategory.forex => 100,
        AssetCategory.metal => 20,
      };

  /// Mock fiyat servisi için tik başına oynaklık.
  double get volatility => switch (this) {
        AssetCategory.bist => 0.0008,
        AssetCategory.crypto => 0.0015,
        AssetCategory.forex => 0.0002,
        AssetCategory.metal => 0.0005,
      };
}

class Asset {
  const Asset({
    required this.symbol,
    required this.name,
    required this.category,
    required this.basePrice,
    this.unit = '',
  });

  final String symbol;
  final String name;
  final AssetCategory category;

  /// Mock servis için örnek başlangıç fiyatı (TL).
  final double basePrice;

  /// Birim açıklaması (örn. gram).
  final String unit;
}
