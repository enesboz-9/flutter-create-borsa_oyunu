/// Varlığın işlem gördüğü para birimi. TL hesabı ve USD hesabı ayrı tutulur.
enum Currency { tl, usd }

extension CurrencyX on Currency {
  String get symbol => this == Currency.usd ? r'$' : '₺';
  String get code => this == Currency.usd ? 'USD' : 'TL';
}

enum AssetCategory { bist, us, crypto, forex, metal }

extension AssetCategoryX on AssetCategory {
  String get label => switch (this) {
        AssetCategory.bist => 'Borsa İstanbul',
        AssetCategory.us => 'ABD Hisseleri',
        AssetCategory.crypto => 'Kripto',
        AssetCategory.forex => 'Döviz',
        AssetCategory.metal => 'Değerli Metaller',
      };

  /// Bu kategorideki varlıkların alınıp satıldığı para birimi.
  /// ABD hisseleri için hesapta dolar bulunması gerekir.
  Currency get currency =>
      this == AssetCategory.us ? Currency.usd : Currency.tl;

  /// İşlem komisyon oranı (açılışta ve kapanışta pozisyon büyüklüğü üzerinden).
  double get commissionRate => switch (this) {
        AssetCategory.bist => 0.002,
        AssetCategory.us => 0.001,
        AssetCategory.crypto => 0.001,
        AssetCategory.forex => 0.0005,
        AssetCategory.metal => 0.001,
      };

  int get maxLeverage => switch (this) {
        AssetCategory.bist => 5,
        AssetCategory.us => 5,
        AssetCategory.crypto => 50,
        AssetCategory.forex => 100,
        AssetCategory.metal => 20,
      };

  /// Mock fiyat servisi için tik başına oynaklık.
  double get volatility => switch (this) {
        AssetCategory.bist => 0.0008,
        AssetCategory.us => 0.0007,
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
    this.group = '',
  });

  final String symbol;
  final String name;
  final AssetCategory category;

  /// Mock servis için örnek başlangıç fiyatı.
  /// ABD hisselerinde USD, diğerlerinde TL cinsindendir.
  final double basePrice;

  /// Birim açıklaması (örn. gram).
  final String unit;

  /// Kategori içi alt grup (örn. Bankacılık, Teknoloji, Majör). Piyasa
  /// ekranındaki alt filtre çipleri bundan üretilir.
  final String group;

  Currency get currency => category.currency;
}
