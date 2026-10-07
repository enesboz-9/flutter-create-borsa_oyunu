import 'package:borsa_oyunu/data/assets_catalog.dart';
import 'package:borsa_oyunu/models/position.dart';
import 'package:borsa_oyunu/models/price_alert.dart';
import 'package:borsa_oyunu/services/game_repository.dart';
import 'package:borsa_oyunu/services/price_service.dart';
import 'package:borsa_oyunu/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePrices implements PriceService {
  double price = 100;
  void Function()? _onUpdate;

  /// Fiyatı değiştirip controller'a tik gönderir.
  void tick(double p) {
    price = p;
    _onUpdate?.call();
  }

  @override
  double priceOf(String symbol) => price;
  @override
  double changePercent(String symbol) => 0;
  @override
  List<double> history(String symbol) => const [];
  @override
  void start(void Function() onUpdate) => _onUpdate = onUpdate;
  @override
  void stop() {}
}

class MemRepo implements GameRepository {
  @override
  Future<GameSnapshot?> load() async => null;
  @override
  Future<void> save(GameSnapshot snapshot) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  test('10x long likidasyon fiyatı girişin altındadır', () {
    final liq = Position.liquidationPriceFor(
        side: Side.long, entryPrice: 100, leverage: 10);
    expect(liq, closeTo(90.5, 1e-9));
  });

  test('10x short likidasyon fiyatı girişin üstündedir', () {
    final liq = Position.liquidationPriceFor(
        side: Side.short, entryPrice: 100, leverage: 10);
    expect(liq, closeTo(109.5, 1e-9));
  });

  test('aynı fiyattan aç-kapa sadece komisyon kaybettirir', () async {
    final g = GameController(FakePrices(), MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');

    final err = g.openPosition(
        asset: btc, side: Side.long, margin: 100000, leverage: 10);
    expect(err, isNull);
    expect(g.positions.length, 1);

    g.closePosition(g.positions.first.id);
    // Pozisyon 1.000.000 TL, komisyon %0,1 => açılış 1.000 + kapanış 1.000
    expect(g.cash, closeTo(1000000 - 2000, 0.01));
    expect(g.history.length, 1);
  });

  test('yetersiz bakiyede işlem açılmaz', () async {
    final g = GameController(FakePrices(), MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');
    final err = g.openPosition(
        asset: btc, side: Side.long, margin: 2000000, leverage: 1);
    expect(err, isNotNull);
    expect(g.positions, isEmpty);
  });

  test('short pozisyon fiyat düşünce kâr eder', () async {
    final prices = FakePrices();
    final g = GameController(prices, MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');

    g.openPosition(asset: btc, side: Side.short, margin: 100000, leverage: 5);
    prices.price = 90;
    final p = g.positions.first;
    expect(p.pnlAt(90), closeTo(50000, 1e-6));
  });
  test('kapatırken fiyat değişse de ekrandaki fiyattan kapanır', () async {
    final prices = FakePrices();
    final g = GameController(prices, MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');

    g.openPosition(asset: btc, side: Side.long, margin: 100000, leverage: 10);
    // Kullanıcı 100 TL'yi görürken basıyor, o sırada fiyat 120'ye çıkıyor.
    prices.price = 120;
    g.closePosition(g.positions.first.id, atPrice: 100);

    expect(g.history.first.exitPrice, 100);
    expect(g.history.first.grossPnl, closeTo(0, 1e-9));
    expect(g.cash, closeTo(1000000 - 2000, 0.01));
  });

  test('atPrice verilmezse güncel fiyattan kapanır', () async {
    final prices = FakePrices();
    final g = GameController(prices, MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');

    g.openPosition(asset: btc, side: Side.long, margin: 100000, leverage: 10);
    prices.price = 110;
    g.closePosition(g.positions.first.id);
    expect(g.history.first.exitPrice, 110);
  });

  test('yukarı yönlü alarm hedefe ulaşınca bir kez tetiklenir', () async {
    final prices = FakePrices();
    final g = GameController(prices, MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');
    final hits = <PriceAlert>[];
    g.alertHits.listen(hits.add);

    expect(g.addAlert(asset: btc, targetPrice: 110, intent: AlertIntent.buy),
        isNull);
    expect(g.alerts.single.direction, AlertDirection.above);
    expect(g.activeAlertCount, 1);

    prices.tick(105);
    await Future<void>.delayed(Duration.zero);
    expect(hits, isEmpty);

    prices.tick(111);
    await Future<void>.delayed(Duration.zero);
    expect(hits.length, 1);
    expect(hits.first.triggeredPrice, 111);
    expect(g.activeAlertCount, 0);

    prices.tick(115);
    await Future<void>.delayed(Duration.zero);
    expect(hits.length, 1);
  });

  test('aşağı yönlü alarm fiyat düşünce tetiklenir', () async {
    final prices = FakePrices();
    final g = GameController(prices, MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');
    final hits = <PriceAlert>[];
    g.alertHits.listen(hits.add);

    g.addAlert(asset: btc, targetPrice: 90);
    expect(g.alerts.single.direction, AlertDirection.below);

    prices.tick(89);
    await Future<void>.delayed(Duration.zero);
    expect(hits.length, 1);
  });

  test('geçersiz alarm hedefleri reddedilir', () async {
    final g = GameController(FakePrices(), MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');
    expect(g.addAlert(asset: btc, targetPrice: 0), isNotNull);
    expect(g.addAlert(asset: btc, targetPrice: 100), isNotNull); // güncel fiyat
    expect(g.alerts, isEmpty);
  });
  test('aynı varlığa ikinci alım ortalama maliyeti günceller', () async {
    final prices = FakePrices();
    final g = GameController(prices, MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');

    // 100 TL'den 1000 adet, sonra 200 TL'den 500 adet (kaldıraç 1x).
    g.openPosition(asset: btc, side: Side.long, margin: 100000, leverage: 1);
    prices.price = 200;
    g.openPosition(asset: btc, side: Side.long, margin: 100000, leverage: 1);

    expect(g.positions.length, 1);
    final p = g.positions.first;
    expect(p.quantity, closeTo(1500, 1e-9));
    expect(p.entryPrice, closeTo(200000 / 1500, 1e-9));
    // Komisyon (%0,1): 100 + 100 = 200 TL, birim başına 200/1500 eklenir.
    expect(p.openCommission, closeTo(200, 1e-9));
    expect(p.avgCost, closeTo(200000 / 1500 + 200 / 1500, 1e-9));
  });

  test('farklı kaldıraç ayrı pozisyon olur', () async {
    final g = GameController(FakePrices(), MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');
    g.openPosition(asset: btc, side: Side.long, margin: 10000, leverage: 2);
    g.openPosition(asset: btc, side: Side.long, margin: 10000, leverage: 5);
    expect(g.positions.length, 2);
  });

  test('kısmi satış orantılı kapatır, kalanın maliyeti değişmez', () async {
    final prices = FakePrices();
    final g = GameController(prices, MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');

    g.openPosition(asset: btc, side: Side.long, margin: 100000, leverage: 1);
    final before = g.positions.first; // 1000 adet @100, komisyon 100
    prices.price = 110;
    final err = g.closePosition(before.id, quantity: 400);
    expect(err, isNull);

    final p = g.positions.single;
    expect(p.quantity, closeTo(600, 1e-9));
    expect(p.margin, closeTo(60000, 1e-6));
    expect(p.openCommission, closeTo(60, 1e-9));
    expect(p.entryPrice, closeTo(100, 1e-9));

    final r = g.history.first;
    expect(r.quantity, closeTo(400, 1e-9));
    expect(r.grossPnl, closeTo(4000, 1e-6));
    // Komisyon: açılıştan 40 + satıştan 110*400*0,001 = 44
    expect(r.commission, closeTo(84, 1e-6));
    // Nakit: 1.000.000 - 100.100 + (40.000 + 4.000 - 44)
    expect(g.cash, closeTo(1000000 - 100100 + 43956, 1e-6));
  });

  test('fazla adet satılamaz, tamamı girilirse pozisyon kapanır', () async {
    final g = GameController(FakePrices(), MemRepo());
    await g.init();
    final btc = kAssets.firstWhere((a) => a.symbol == 'BTC');
    g.openPosition(asset: btc, side: Side.long, margin: 100000, leverage: 1);
    final id = g.positions.first.id;

    expect(g.closePosition(id, quantity: 1001), isNotNull);
    expect(g.closePosition(id, quantity: 0), isNotNull);
    expect(g.positions.length, 1);

    expect(g.closePosition(id, quantity: 1000), isNull);
    expect(g.positions, isEmpty);
  });
}
