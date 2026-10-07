import '../models/asset.dart';

/// Oyundaki işlem görebilir varlıklar. Fiyatlar ÖRNEK değerlerdir;
/// gerçek veri bağlandığında basePrice yalnızca mock servis için kullanılır.
/// Tüm fiyatlar TL cinsindendir.
const List<Asset> kAssets = [
  // ---- Borsa İstanbul ----
  // Bankalar
  Asset(symbol: 'GARAN', name: 'Garanti BBVA', category: AssetCategory.bist, basePrice: 130),
  Asset(symbol: 'AKBNK', name: 'Akbank', category: AssetCategory.bist, basePrice: 65),
  Asset(symbol: 'ISCTR', name: 'İş Bankası (C)', category: AssetCategory.bist, basePrice: 14),
  Asset(symbol: 'YKBNK', name: 'Yapı Kredi', category: AssetCategory.bist, basePrice: 33),
  Asset(symbol: 'HALKB', name: 'Halkbank', category: AssetCategory.bist, basePrice: 30),
  Asset(symbol: 'VAKBN', name: 'Vakıfbank', category: AssetCategory.bist, basePrice: 27),
  Asset(symbol: 'TSKB', name: 'TSKB', category: AssetCategory.bist, basePrice: 14),
  Asset(symbol: 'ALBRK', name: 'Albaraka Türk', category: AssetCategory.bist, basePrice: 8),
  // Holdingler
  Asset(symbol: 'KCHOL', name: 'Koç Holding', category: AssetCategory.bist, basePrice: 180),
  Asset(symbol: 'SAHOL', name: 'Sabancı Holding', category: AssetCategory.bist, basePrice: 90),
  Asset(symbol: 'DOHOL', name: 'Doğan Holding', category: AssetCategory.bist, basePrice: 20),
  Asset(symbol: 'ALARK', name: 'Alarko Holding', category: AssetCategory.bist, basePrice: 105),
  Asset(symbol: 'ENKAI', name: 'Enka İnşaat', category: AssetCategory.bist, basePrice: 100),
  // Havacılık ve ulaşım
  Asset(symbol: 'THYAO', name: 'Türk Hava Yolları', category: AssetCategory.bist, basePrice: 300),
  Asset(symbol: 'PGSUS', name: 'Pegasus', category: AssetCategory.bist, basePrice: 250),
  Asset(symbol: 'TAVHL', name: 'TAV Havalimanları', category: AssetCategory.bist, basePrice: 280),
  // Savunma ve teknoloji
  Asset(symbol: 'ASELS', name: 'Aselsan', category: AssetCategory.bist, basePrice: 200),
  Asset(symbol: 'KONTR', name: 'Kontrolmatik', category: AssetCategory.bist, basePrice: 25),
  Asset(symbol: 'ASTOR', name: 'Astor Enerji', category: AssetCategory.bist, basePrice: 120),
  Asset(symbol: 'EUPWR', name: 'Europower Enerji', category: AssetCategory.bist, basePrice: 10),
  Asset(symbol: 'GESAN', name: 'Girişim Elektrik', category: AssetCategory.bist, basePrice: 40),
  Asset(symbol: 'CWENE', name: 'CW Enerji', category: AssetCategory.bist, basePrice: 20),
  Asset(symbol: 'LOGO', name: 'Logo Yazılım', category: AssetCategory.bist, basePrice: 130),
  Asset(symbol: 'SMRTG', name: 'Smart Güneş Enerjisi', category: AssetCategory.bist, basePrice: 40),
  // Otomotiv
  Asset(symbol: 'FROTO', name: 'Ford Otosan', category: AssetCategory.bist, basePrice: 100),
  Asset(symbol: 'TOASO', name: 'Tofaş', category: AssetCategory.bist, basePrice: 270),
  Asset(symbol: 'DOAS', name: 'Doğuş Otomotiv', category: AssetCategory.bist, basePrice: 230),
  Asset(symbol: 'TTRAK', name: 'Türk Traktör', category: AssetCategory.bist, basePrice: 600),
  // Enerji ve petrokimya
  Asset(symbol: 'TUPRS', name: 'Tüpraş', category: AssetCategory.bist, basePrice: 190),
  Asset(symbol: 'PETKM', name: 'Petkim', category: AssetCategory.bist, basePrice: 18),
  Asset(symbol: 'AKSEN', name: 'Aksa Enerji', category: AssetCategory.bist, basePrice: 38),
  Asset(symbol: 'ODAS', name: 'Odaş Elektrik', category: AssetCategory.bist, basePrice: 8),
  Asset(symbol: 'ENJSA', name: 'Enerjisa', category: AssetCategory.bist, basePrice: 90),
  Asset(symbol: 'SASA', name: 'Sasa Polyester', category: AssetCategory.bist, basePrice: 4),
  // Sanayi ve madencilik
  Asset(symbol: 'EREGL', name: 'Ereğli Demir Çelik', category: AssetCategory.bist, basePrice: 28),
  Asset(symbol: 'KRDMD', name: 'Kardemir (D)', category: AssetCategory.bist, basePrice: 28),
  Asset(symbol: 'KOZAL', name: 'Koza Altın', category: AssetCategory.bist, basePrice: 28),
  Asset(symbol: 'SISE', name: 'Şişecam', category: AssetCategory.bist, basePrice: 40),
  Asset(symbol: 'ARCLK', name: 'Arçelik', category: AssetCategory.bist, basePrice: 150),
  Asset(symbol: 'VESTL', name: 'Vestel', category: AssetCategory.bist, basePrice: 40),
  Asset(symbol: 'BRSAN', name: 'Borusan Mannesmann', category: AssetCategory.bist, basePrice: 480),
  Asset(symbol: 'OYAKC', name: 'Oyak Çimento', category: AssetCategory.bist, basePrice: 70),
  Asset(symbol: 'CIMSA', name: 'Çimsa', category: AssetCategory.bist, basePrice: 55),
  Asset(symbol: 'GUBRF', name: 'Gübre Fabrikaları', category: AssetCategory.bist, basePrice: 380),
  Asset(symbol: 'HEKTS', name: 'Hektaş', category: AssetCategory.bist, basePrice: 2),
  // Perakende ve gıda
  Asset(symbol: 'BIMAS', name: 'BİM Mağazalar', category: AssetCategory.bist, basePrice: 550),
  Asset(symbol: 'MGROS', name: 'Migros', category: AssetCategory.bist, basePrice: 530),
  Asset(symbol: 'SOKM', name: 'Şok Marketler', category: AssetCategory.bist, basePrice: 50),
  Asset(symbol: 'MAVI', name: 'Mavi Giyim', category: AssetCategory.bist, basePrice: 40),
  Asset(symbol: 'ULKER', name: 'Ülker', category: AssetCategory.bist, basePrice: 120),
  Asset(symbol: 'AEFES', name: 'Anadolu Efes', category: AssetCategory.bist, basePrice: 18),
  Asset(symbol: 'CCOLA', name: 'Coca-Cola İçecek', category: AssetCategory.bist, basePrice: 65),
  // Telekom ve gayrimenkul
  Asset(symbol: 'TCELL', name: 'Turkcell', category: AssetCategory.bist, basePrice: 100),
  Asset(symbol: 'TTKOM', name: 'Türk Telekom', category: AssetCategory.bist, basePrice: 55),
  Asset(symbol: 'EKGYO', name: 'Emlak Konut GYO', category: AssetCategory.bist, basePrice: 22),

  // ---- Kripto ----
  Asset(symbol: 'BTC', name: 'Bitcoin', category: AssetCategory.crypto, basePrice: 4300000),
  Asset(symbol: 'ETH', name: 'Ethereum', category: AssetCategory.crypto, basePrice: 150000),
  Asset(symbol: 'BNB', name: 'BNB', category: AssetCategory.crypto, basePrice: 38700),
  Asset(symbol: 'SOL', name: 'Solana', category: AssetCategory.crypto, basePrice: 6450),
  Asset(symbol: 'XRP', name: 'XRP', category: AssetCategory.crypto, basePrice: 99),
  Asset(symbol: 'ADA', name: 'Cardano', category: AssetCategory.crypto, basePrice: 27),
  Asset(symbol: 'AVAX', name: 'Avalanche', category: AssetCategory.crypto, basePrice: 1000),
  Asset(symbol: 'LINK', name: 'Chainlink', category: AssetCategory.crypto, basePrice: 650),
  Asset(symbol: 'TRX', name: 'TRON', category: AssetCategory.crypto, basePrice: 12),
  Asset(symbol: 'LTC', name: 'Litecoin', category: AssetCategory.crypto, basePrice: 3800),
  Asset(symbol: 'DOGE', name: 'Dogecoin', category: AssetCategory.crypto, basePrice: 8.6),

  // ---- Döviz ----
  Asset(symbol: 'USDTRY', name: 'Amerikan Doları', category: AssetCategory.forex, basePrice: 43),
  Asset(symbol: 'EURTRY', name: 'Euro', category: AssetCategory.forex, basePrice: 50),
  Asset(symbol: 'GBPTRY', name: 'İngiliz Sterlini', category: AssetCategory.forex, basePrice: 57.5),
  Asset(symbol: 'CHFTRY', name: 'İsviçre Frangı', category: AssetCategory.forex, basePrice: 53),
  Asset(symbol: 'JPYTRY', name: 'Japon Yeni (100)', category: AssetCategory.forex, basePrice: 29),

  // ---- Değerli metaller (gram fiyatı) ----
  Asset(symbol: 'XAU', name: 'Altın', category: AssetCategory.metal, basePrice: 5600, unit: 'gram'),
  Asset(symbol: 'XAG', name: 'Gümüş', category: AssetCategory.metal, basePrice: 69, unit: 'gram'),
  Asset(symbol: 'XPT', name: 'Platin', category: AssetCategory.metal, basePrice: 2200, unit: 'gram'),
  Asset(symbol: 'XPD', name: 'Paladyum', category: AssetCategory.metal, basePrice: 1800, unit: 'gram'),
];
