import '../models/asset.dart';

/// Oyundaki işlem görebilir varlıklar. Fiyatlar ÖRNEK değerlerdir;
/// gerçek veri bağlandığında basePrice yalnızca mock servis için kullanılır.
/// Tüm fiyatlar TL cinsindendir.
const List<Asset> kAssets = [
  // Borsa İstanbul
  Asset(symbol: 'THYAO', name: 'Türk Hava Yolları', category: AssetCategory.bist, basePrice: 300),
  Asset(symbol: 'GARAN', name: 'Garanti BBVA', category: AssetCategory.bist, basePrice: 130),
  Asset(symbol: 'AKBNK', name: 'Akbank', category: AssetCategory.bist, basePrice: 65),
  Asset(symbol: 'ASELS', name: 'Aselsan', category: AssetCategory.bist, basePrice: 200),
  Asset(symbol: 'EREGL', name: 'Ereğli Demir Çelik', category: AssetCategory.bist, basePrice: 28),
  Asset(symbol: 'BIMAS', name: 'BİM Mağazalar', category: AssetCategory.bist, basePrice: 550),
  Asset(symbol: 'KCHOL', name: 'Koç Holding', category: AssetCategory.bist, basePrice: 180),
  Asset(symbol: 'SASA', name: 'Sasa Polyester', category: AssetCategory.bist, basePrice: 4),
  Asset(symbol: 'TUPRS', name: 'Tüpraş', category: AssetCategory.bist, basePrice: 190),
  Asset(symbol: 'SISE', name: 'Şişecam', category: AssetCategory.bist, basePrice: 40),

  // Kripto
  Asset(symbol: 'BTC', name: 'Bitcoin', category: AssetCategory.crypto, basePrice: 4300000),
  Asset(symbol: 'ETH', name: 'Ethereum', category: AssetCategory.crypto, basePrice: 150000),
  Asset(symbol: 'BNB', name: 'BNB', category: AssetCategory.crypto, basePrice: 38700),
  Asset(symbol: 'SOL', name: 'Solana', category: AssetCategory.crypto, basePrice: 6450),
  Asset(symbol: 'XRP', name: 'XRP', category: AssetCategory.crypto, basePrice: 99),
  Asset(symbol: 'DOGE', name: 'Dogecoin', category: AssetCategory.crypto, basePrice: 8.6),

  // Döviz
  Asset(symbol: 'USDTRY', name: 'Amerikan Doları', category: AssetCategory.forex, basePrice: 43),
  Asset(symbol: 'EURTRY', name: 'Euro', category: AssetCategory.forex, basePrice: 50),
  Asset(symbol: 'GBPTRY', name: 'İngiliz Sterlini', category: AssetCategory.forex, basePrice: 57.5),

  // Değerli metaller (gram fiyatı)
  Asset(symbol: 'XAU', name: 'Altın', category: AssetCategory.metal, basePrice: 5600, unit: 'gram'),
  Asset(symbol: 'XAG', name: 'Gümüş', category: AssetCategory.metal, basePrice: 69, unit: 'gram'),
  Asset(symbol: 'XPT', name: 'Platin', category: AssetCategory.metal, basePrice: 2200, unit: 'gram'),
];
