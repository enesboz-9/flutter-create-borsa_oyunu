import 'package:borsa_oyunu/data/assets_catalog.dart';
import 'package:borsa_oyunu/models/position.dart';
import 'package:borsa_oyunu/services/game_repository.dart';
import 'package:borsa_oyunu/services/price_service.dart';
import 'package:borsa_oyunu/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePrices implements PriceService {
  double price = 100;
  @override
  double priceOf(String symbol) => price;
  @override
  double changePercent(String symbol) => 0;
  @override
  List<double> history(String symbol) => const [];
  @override
  void start(void Function() onUpdate) {}
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
}
