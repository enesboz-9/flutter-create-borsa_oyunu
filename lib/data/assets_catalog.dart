import '../models/asset.dart';

/// Oyundaki işlem görebilir varlıklar. Fiyatlar ÖRNEK değerlerdir;
/// gerçek veri bağlandığında basePrice yalnızca mock servis için kullanılır.
/// ABD hisseleri USD, diğer tüm varlıklar TL cinsindendir.
///
/// Her satır: (sembol, ad, örnek fiyat, alt grup).

// ---- Borsa İstanbul (TL) ----
const List<(String, String, double, String)> _bist = [
  // Bankacılık
  ('GARAN', 'Garanti BBVA', 130, 'Bankacılık'),
  ('AKBNK', 'Akbank', 65, 'Bankacılık'),
  ('ISCTR', 'İş Bankası (C)', 14, 'Bankacılık'),
  ('YKBNK', 'Yapı Kredi', 33, 'Bankacılık'),
  ('HALKB', 'Halkbank', 30, 'Bankacılık'),
  ('VAKBN', 'Vakıfbank', 27, 'Bankacılık'),
  ('TSKB', 'TSKB', 14, 'Bankacılık'),
  ('ALBRK', 'Albaraka Türk', 8, 'Bankacılık'),
  ('SKBNK', 'Şekerbank', 7, 'Bankacılık'),
  // Sigorta ve aracı kurum
  ('ANHYT', 'Anadolu Hayat Emeklilik', 110, 'Sigorta ve Finans'),
  ('ANSGR', 'Anadolu Sigorta', 90, 'Sigorta ve Finans'),
  ('AGESA', 'Agesa Hayat Emeklilik', 190, 'Sigorta ve Finans'),
  ('TURSG', 'Türkiye Sigorta', 14, 'Sigorta ve Finans'),
  ('ISMEN', 'İş Yatırım', 55, 'Sigorta ve Finans'),
  // Holding
  ('KCHOL', 'Koç Holding', 180, 'Holding'),
  ('SAHOL', 'Sabancı Holding', 90, 'Holding'),
  ('DOHOL', 'Doğan Holding', 20, 'Holding'),
  ('ALARK', 'Alarko Holding', 105, 'Holding'),
  ('ENKAI', 'Enka İnşaat', 100, 'Holding'),
  ('AGHOL', 'Anadolu Grubu Holding', 25, 'Holding'),
  ('TKFEN', 'Tekfen Holding', 85, 'Holding'),
  ('BERA', 'Bera Holding', 15, 'Holding'),
  // Havacılık, ulaşım ve turizm
  ('THYAO', 'Türk Hava Yolları', 300, 'Ulaşım'),
  ('PGSUS', 'Pegasus', 250, 'Ulaşım'),
  ('TAVHL', 'TAV Havalimanları', 280, 'Ulaşım'),
  ('CLEBI', 'Çelebi Hava Servisi', 2600, 'Ulaşım'),
  ('RYSAS', 'Reysaş Lojistik', 20, 'Ulaşım'),
  // Savunma ve teknoloji
  ('ASELS', 'Aselsan', 200, 'Savunma ve Teknoloji'),
  ('KONTR', 'Kontrolmatik', 25, 'Savunma ve Teknoloji'),
  ('LOGO', 'Logo Yazılım', 130, 'Savunma ve Teknoloji'),
  ('OTKAR', 'Otokar', 450, 'Savunma ve Teknoloji'),
  ('ARDYZ', 'ARD Bilişim', 40, 'Savunma ve Teknoloji'),
  ('MIATK', 'Mia Teknoloji', 40, 'Savunma ve Teknoloji'),
  ('REEDR', 'Reeder Teknoloji', 15, 'Savunma ve Teknoloji'),
  ('KAREL', 'Karel Elektronik', 30, 'Savunma ve Teknoloji'),
  ('INDES', 'Indeks Bilgisayar', 14, 'Savunma ve Teknoloji'),
  ('SDTTR', 'SDT Uzay ve Savunma', 150, 'Savunma ve Teknoloji'),
  ('EDATA', 'Edata Teknoloji', 25, 'Savunma ve Teknoloji'),
  // Enerji
  ('ASTOR', 'Astor Enerji', 120, 'Enerji'),
  ('EUPWR', 'Europower Enerji', 10, 'Enerji'),
  ('GESAN', 'Girişim Elektrik', 40, 'Enerji'),
  ('CWENE', 'CW Enerji', 20, 'Enerji'),
  ('SMRTG', 'Smart Güneş Enerjisi', 40, 'Enerji'),
  ('TUPRS', 'Tüpraş', 190, 'Enerji'),
  ('PETKM', 'Petkim', 18, 'Enerji'),
  ('AKSEN', 'Aksa Enerji', 38, 'Enerji'),
  ('ODAS', 'Odaş Elektrik', 8, 'Enerji'),
  ('ENJSA', 'Enerjisa', 90, 'Enerji'),
  ('AYDEM', 'Aydem Yenilenebilir', 15, 'Enerji'),
  ('ZOREN', 'Zorlu Enerji', 4, 'Enerji'),
  ('GWIND', 'Galata Wind', 25, 'Enerji'),
  ('BIOEN', 'Biotrend Enerji', 12, 'Enerji'),
  ('YEOTK', 'YEO Teknoloji', 30, 'Enerji'),
  ('AKFYE', 'Akfen Yenilenebilir', 15, 'Enerji'),
  ('AHGAZ', 'Ahlatcı Doğalgaz', 20, 'Enerji'),
  // Otomotiv
  ('FROTO', 'Ford Otosan', 100, 'Otomotiv'),
  ('TOASO', 'Tofaş', 270, 'Otomotiv'),
  ('DOAS', 'Doğuş Otomotiv', 230, 'Otomotiv'),
  ('TTRAK', 'Türk Traktör', 600, 'Otomotiv'),
  ('ASUZU', 'Anadolu Isuzu', 190, 'Otomotiv'),
  ('BRISA', 'Brisa', 105, 'Otomotiv'),
  ('KORDS', 'Kordsa', 150, 'Otomotiv'),
  ('KARSN', 'Karsan', 5, 'Otomotiv'),
  // Sanayi ve madencilik
  ('EREGL', 'Ereğli Demir Çelik', 28, 'Sanayi ve Madencilik'),
  ('KRDMD', 'Kardemir (D)', 28, 'Sanayi ve Madencilik'),
  ('ISDMR', 'İskenderun Demir Çelik', 40, 'Sanayi ve Madencilik'),
  ('KOZAL', 'Koza Altın', 28, 'Sanayi ve Madencilik'),
  ('KOZAA', 'Koza Anadolu Metal', 70, 'Sanayi ve Madencilik'),
  ('SISE', 'Şişecam', 40, 'Sanayi ve Madencilik'),
  ('ARCLK', 'Arçelik', 150, 'Sanayi ve Madencilik'),
  ('VESTL', 'Vestel', 40, 'Sanayi ve Madencilik'),
  ('BRSAN', 'Borusan Mannesmann', 480, 'Sanayi ve Madencilik'),
  ('OYAKC', 'Oyak Çimento', 70, 'Sanayi ve Madencilik'),
  ('CIMSA', 'Çimsa', 55, 'Sanayi ve Madencilik'),
  ('AKCNS', 'Akçansa', 150, 'Sanayi ve Madencilik'),
  ('GUBRF', 'Gübre Fabrikaları', 380, 'Sanayi ve Madencilik'),
  ('HEKTS', 'Hektaş', 2, 'Sanayi ve Madencilik'),
  ('SASA', 'Sasa Polyester', 4, 'Sanayi ve Madencilik'),
  ('KCAER', 'Kocaer Çelik', 10, 'Sanayi ve Madencilik'),
  // Perakende ve gıda
  ('BIMAS', 'BİM Mağazalar', 550, 'Perakende ve Gıda'),
  ('MGROS', 'Migros', 530, 'Perakende ve Gıda'),
  ('SOKM', 'Şok Marketler', 50, 'Perakende ve Gıda'),
  ('MAVI', 'Mavi Giyim', 40, 'Perakende ve Gıda'),
  ('ULKER', 'Ülker', 120, 'Perakende ve Gıda'),
  ('AEFES', 'Anadolu Efes', 18, 'Perakende ve Gıda'),
  ('CCOLA', 'Coca-Cola İçecek', 65, 'Perakende ve Gıda'),
  ('TATGD', 'Tat Gıda', 40, 'Perakende ve Gıda'),
  ('PNSUT', 'Pınar Süt', 130, 'Perakende ve Gıda'),
  ('CRFSA', 'CarrefourSA', 60, 'Perakende ve Gıda'),
  ('EBEBK', 'Ebebek Mağazacılık', 100, 'Perakende ve Gıda'),
  // Telekom, sağlık ve gayrimenkul
  ('TCELL', 'Turkcell', 100, 'Telekom, Sağlık, GYO'),
  ('TTKOM', 'Türk Telekom', 55, 'Telekom, Sağlık, GYO'),
  ('MPARK', 'MLP Sağlık', 330, 'Telekom, Sağlık, GYO'),
  ('SELEC', 'Selçuk Ecza Deposu', 70, 'Telekom, Sağlık, GYO'),
  ('EKGYO', 'Emlak Konut GYO', 22, 'Telekom, Sağlık, GYO'),
  ('ISGYO', 'İş GYO', 18, 'Telekom, Sağlık, GYO'),
  ('TRGYO', 'Torunlar GYO', 70, 'Telekom, Sağlık, GYO'),
  ('OZKGY', 'Özak GYO', 15, 'Telekom, Sağlık, GYO'),
  // Spor kulüpleri
  ('GSRAY', 'Galatasaray', 3, 'Spor Kulüpleri'),
  ('FENER', 'Fenerbahçe', 4, 'Spor Kulüpleri'),
  ('BJKAS', 'Beşiktaş', 2, 'Spor Kulüpleri'),
  ('TSPOR', 'Trabzonspor', 1.5, 'Spor Kulüpleri'),
];

// ---- ABD hisseleri ve ETF'ler (USD) ----
const List<(String, String, double, String)> _us = [
  // Teknoloji
  ('AAPL', 'Apple', 230, 'Teknoloji'),
  ('MSFT', 'Microsoft', 510, 'Teknoloji'),
  ('NVDA', 'NVIDIA', 180, 'Teknoloji'),
  ('GOOGL', 'Alphabet (A)', 240, 'Teknoloji'),
  ('AMZN', 'Amazon', 230, 'Teknoloji'),
  ('META', 'Meta Platforms', 700, 'Teknoloji'),
  ('TSLA', 'Tesla', 430, 'Teknoloji'),
  ('AVGO', 'Broadcom', 340, 'Teknoloji'),
  ('NFLX', 'Netflix', 1200, 'Teknoloji'),
  ('AMD', 'AMD', 160, 'Teknoloji'),
  ('INTC', 'Intel', 25, 'Teknoloji'),
  ('ORCL', 'Oracle', 280, 'Teknoloji'),
  ('CRM', 'Salesforce', 250, 'Teknoloji'),
  ('ADBE', 'Adobe', 350, 'Teknoloji'),
  ('CSCO', 'Cisco', 70, 'Teknoloji'),
  ('QCOM', 'Qualcomm', 160, 'Teknoloji'),
  ('IBM', 'IBM', 280, 'Teknoloji'),
  ('UBER', 'Uber', 95, 'Teknoloji'),
  ('PLTR', 'Palantir', 180, 'Teknoloji'),
  // Finans
  ('JPM', 'JPMorgan Chase', 300, 'Finans'),
  ('BAC', 'Bank of America', 50, 'Finans'),
  ('V', 'Visa', 340, 'Finans'),
  ('MA', 'Mastercard', 570, 'Finans'),
  ('GS', 'Goldman Sachs', 750, 'Finans'),
  ('WFC', 'Wells Fargo', 80, 'Finans'),
  ('BRKB', 'Berkshire Hathaway (B)', 480, 'Finans'),
  ('AXP', 'American Express', 330, 'Finans'),
  ('PYPL', 'PayPal', 70, 'Finans'),
  ('COIN', 'Coinbase', 350, 'Finans'),
  // Sağlık
  ('JNJ', 'Johnson & Johnson', 175, 'Sağlık'),
  ('PFE', 'Pfizer', 25, 'Sağlık'),
  ('LLY', 'Eli Lilly', 800, 'Sağlık'),
  ('UNH', 'UnitedHealth', 330, 'Sağlık'),
  ('MRK', 'Merck', 90, 'Sağlık'),
  ('ABBV', 'AbbVie', 210, 'Sağlık'),
  ('NVO', 'Novo Nordisk', 50, 'Sağlık'),
  // Tüketici
  ('WMT', 'Walmart', 100, 'Tüketici'),
  ('KO', 'Coca-Cola', 70, 'Tüketici'),
  ('PEP', 'PepsiCo', 145, 'Tüketici'),
  ('MCD', "McDonald's", 300, 'Tüketici'),
  ('NKE', 'Nike', 70, 'Tüketici'),
  ('SBUX', 'Starbucks', 85, 'Tüketici'),
  ('DIS', 'Walt Disney', 110, 'Tüketici'),
  ('COST', 'Costco', 950, 'Tüketici'),
  ('HD', 'Home Depot', 380, 'Tüketici'),
  ('PG', 'Procter & Gamble', 150, 'Tüketici'),
  // Enerji ve sanayi
  ('XOM', 'Exxon Mobil', 110, 'Enerji ve Sanayi'),
  ('CVX', 'Chevron', 155, 'Enerji ve Sanayi'),
  ('BA', 'Boeing', 215, 'Enerji ve Sanayi'),
  ('CAT', 'Caterpillar', 450, 'Enerji ve Sanayi'),
  ('GE', 'GE Aerospace', 290, 'Enerji ve Sanayi'),
  ('LMT', 'Lockheed Martin', 480, 'Enerji ve Sanayi'),
  // ETF
  ('SPY', 'SPDR S&P 500 ETF', 650, 'ETF'),
  ('QQQ', 'Invesco QQQ (Nasdaq 100)', 590, 'ETF'),
  ('DIA', 'SPDR Dow Jones ETF', 460, 'ETF'),
  ('IWM', 'iShares Russell 2000', 240, 'ETF'),
  ('VOO', 'Vanguard S&P 500', 600, 'ETF'),
  ('GLD', 'SPDR Gold Shares', 350, 'ETF'),
  ('TLT', 'iShares 20+ Yıl Tahvil', 90, 'ETF'),
  ('ARKK', 'ARK Innovation ETF', 70, 'ETF'),
];

// ---- Kripto (TL) ----
const List<(String, String, double, String)> _crypto = [
  // Majör
  ('BTC', 'Bitcoin', 4300000, 'Majör'),
  ('ETH', 'Ethereum', 150000, 'Majör'),
  ('BNB', 'BNB', 38700, 'Majör'),
  ('SOL', 'Solana', 6450, 'Majör'),
  ('XRP', 'XRP', 99, 'Majör'),
  ('ADA', 'Cardano', 27, 'Majör'),
  ('DOGE', 'Dogecoin', 8.6, 'Majör'),
  ('TRX', 'TRON', 12, 'Majör'),
  ('LTC', 'Litecoin', 3800, 'Majör'),
  ('BCH', 'Bitcoin Cash', 19350, 'Majör'),
  // Altcoin
  ('AVAX', 'Avalanche', 1000, 'Altcoin'),
  ('LINK', 'Chainlink', 650, 'Altcoin'),
  ('DOT', 'Polkadot', 172, 'Altcoin'),
  ('ATOM', 'Cosmos', 215, 'Altcoin'),
  ('NEAR', 'NEAR Protocol', 130, 'Altcoin'),
  ('APT', 'Aptos', 215, 'Altcoin'),
  ('SUI', 'Sui', 129, 'Altcoin'),
  ('TON', 'Toncoin', 130, 'Altcoin'),
  ('XLM', 'Stellar', 13, 'Altcoin'),
  ('ETC', 'Ethereum Classic', 860, 'Altcoin'),
  ('HBAR', 'Hedera', 8.6, 'Altcoin'),
  ('ICP', 'Internet Computer', 258, 'Altcoin'),
  ('FIL', 'Filecoin', 107, 'Altcoin'),
  ('POL', 'Polygon (POL)', 10.7, 'Altcoin'),
  ('ARB', 'Arbitrum', 17, 'Altcoin'),
  ('OP', 'Optimism', 34, 'Altcoin'),
  ('RENDER', 'Render', 172, 'Altcoin'),
  ('FET', 'Fetch.ai', 30, 'Altcoin'),
  // DeFi
  ('UNI', 'Uniswap', 345, 'DeFi'),
  ('AAVE', 'Aave', 8600, 'DeFi'),
  ('INJ', 'Injective', 600, 'DeFi'),
  // Meme
  ('SHIB', 'Shiba Inu', 0.00065, 'Meme'),
  ('PEPE', 'Pepe', 0.00043, 'Meme'),
];

// ---- Döviz (TL karşılığı) ----
const List<(String, String, double, String)> _forex = [
  ('USDTRY', 'Amerikan Doları', 43, 'Majör'),
  ('EURTRY', 'Euro', 50, 'Majör'),
  ('GBPTRY', 'İngiliz Sterlini', 57.5, 'Majör'),
  ('CHFTRY', 'İsviçre Frangı', 53, 'Majör'),
  ('JPYTRY', 'Japon Yeni (100)', 29, 'Majör'),
  ('AUDTRY', 'Avustralya Doları', 28, 'Diğer'),
  ('CADTRY', 'Kanada Doları', 31, 'Diğer'),
  ('SEKTRY', 'İsveç Kronu', 4.5, 'Diğer'),
  ('NOKTRY', 'Norveç Kronu', 4.2, 'Diğer'),
  ('DKKTRY', 'Danimarka Kronu', 6.7, 'Diğer'),
  ('PLNTRY', 'Polonya Zlotisi', 11.8, 'Diğer'),
  ('CNYTRY', 'Çin Yuanı', 6, 'Diğer'),
  ('SARTRY', 'Suudi Riyali', 11.5, 'Diğer'),
  ('AEDTRY', 'BAE Dirhemi', 11.7, 'Diğer'),
  ('KWDTRY', 'Kuveyt Dinarı', 140, 'Diğer'),
  ('RUBTRY', 'Rus Rublesi', 0.5, 'Diğer'),
];

// ---- Değerli metaller (TL) ----
// Altın ve gümüş gram fiyatıdır; ziynet altınları adet, ons fiyatları ons başınadır.
const List<(String, String, double, String, String)> _metals = [
  ('XAU', 'Gram Altın', 5600, 'Altın', 'gram'),
  ('XAUONS', 'Ons Altın', 174000, 'Altın', 'ons'),
  ('CEYREK', 'Çeyrek Altın', 9150, 'Altın', 'adet'),
  ('YARIM', 'Yarım Altın', 18300, 'Altın', 'adet'),
  ('TAM', 'Tam Altın', 36600, 'Altın', 'adet'),
  ('ATA', 'Cumhuriyet (Ata) Altını', 37500, 'Altın', 'adet'),
  ('GA22', '22 Ayar Gram Altın', 5130, 'Altın', 'gram'),
  ('GA14', '14 Ayar Gram Altın', 3270, 'Altın', 'gram'),
  ('XAG', 'Gram Gümüş', 69, 'Gümüş', 'gram'),
  ('XAGONS', 'Ons Gümüş', 2140, 'Gümüş', 'ons'),
  ('XPT', 'Platin', 2200, 'Platin ve Paladyum', 'gram'),
  ('XPD', 'Paladyum', 1800, 'Platin ve Paladyum', 'gram'),
  ('XRH', 'Rodyum', 9700, 'Platin ve Paladyum', 'gram'),
];

Asset _mk(AssetCategory c, (String, String, double, String) r) => Asset(
      symbol: r.$1,
      name: r.$2,
      category: c,
      basePrice: r.$3,
      group: r.$4,
    );

final List<Asset> kAssets = [
  for (final r in _bist) _mk(AssetCategory.bist, r),
  for (final r in _us) _mk(AssetCategory.us, r),
  for (final r in _crypto) _mk(AssetCategory.crypto, r),
  for (final r in _forex) _mk(AssetCategory.forex, r),
  for (final r in _metals)
    Asset(
      symbol: r.$1,
      name: r.$2,
      category: AssetCategory.metal,
      basePrice: r.$3,
      group: r.$4,
      unit: r.$5,
    ),
];

final Map<String, Asset> _bySymbol = {for (final a in kAssets) a.symbol: a};

/// Sembole göre varlık (yoksa null).
Asset? assetBySymbol(String symbol) => _bySymbol[symbol];

/// Bir kategorideki alt grupların sıralı listesi.
List<String> groupsOf(AssetCategory c) {
  final out = <String>[];
  for (final a in kAssets) {
    if (a.category == c && a.group.isNotEmpty && !out.contains(a.group)) {
      out.add(a.group);
    }
  }
  return out;
}
