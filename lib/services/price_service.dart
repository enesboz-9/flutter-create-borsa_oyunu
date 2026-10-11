import 'dart:async';
import 'dart:math';

import '../core/constants.dart';
import '../data/assets_catalog.dart';
import '../models/asset.dart';

/// Grafik dönemi.
enum ChartRange { day, week, month, threeMonths, year, fiveYears }

extension ChartRangeX on ChartRange {
  String get label => switch (this) {
        ChartRange.day => '1G',
        ChartRange.week => '1H',
        ChartRange.month => '1A',
        ChartRange.threeMonths => '3A',
        ChartRange.year => '1Y',
        ChartRange.fiveYears => '5Y',
      };
}

class ChartPoint {
  const ChartPoint(this.time, this.price);
  final DateTime time;
  final double price;
}

/// Fiyat kaynağı arayüzü.
///
/// Gerçek (15 dk gecikmeli) veriye geçerken bu arayüzü uygulayan yeni bir
/// sınıf yazman (ör. SupabasePriceService) ve main.dart'ta onu vermen yeterli.
abstract class PriceService {
  double priceOf(String symbol);

  /// Oturum başlangıcına göre yüzde değişim.
  double changePercent(String symbol);

  List<double> history(String symbol);

  /// Seçilen dönem için geçmiş fiyat serisi (boşsa veri alınamadı).
  Future<List<ChartPoint>> chart(String symbol, ChartRange range);

  /// Son fiyatın borsada oluştuğu an (gecikmeli veride gecikmiş zaman).
  /// Hiç veri gelmediyse çok eski bir tarih döner.
  DateTime quoteTime(String symbol);

  void start(void Function() onUpdate);
  void stop();
}

/// Geliştirme için rastgele yürüyüşle sahte fiyat üretir.
class MockPriceService implements PriceService {
  MockPriceService({Random? random}) : _rnd = random ?? Random() {
    _seed();
  }

  final Random _rnd;
  final Map<String, double> _prices = {};
  final Map<String, List<double>> _history = {};
  final Map<String, double> _open = {};
  Timer? _timer;

  double _gauss() {
    final u1 = 1 - _rnd.nextDouble();
    final u2 = _rnd.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  void _seed() {
    for (final a in kAssets) {
      var p = a.basePrice;
      final list = <double>[];
      for (var i = 0; i < GameConfig.historyLength; i++) {
        p *= 1 + _gauss() * a.category.volatility;
        list.add(p);
      }
      _history[a.symbol] = list;
      _prices[a.symbol] = p;
      _open[a.symbol] = list.first;
    }
  }

  void _tick() {
    for (final a in kAssets) {
      final p = _prices[a.symbol]! * (1 + _gauss() * a.category.volatility);
      _prices[a.symbol] = p;
      final h = _history[a.symbol]!..add(p);
      if (h.length > GameConfig.historyLength) h.removeAt(0);
    }
  }

  @override
  Future<List<ChartPoint>> chart(String symbol, ChartRange range) async {
    final h = history(symbol);
    final step = switch (range) {
      ChartRange.day => const Duration(minutes: 5),
      ChartRange.week => const Duration(minutes: 30),
      ChartRange.month => const Duration(hours: 4),
      ChartRange.threeMonths => const Duration(days: 1),
      ChartRange.year => const Duration(days: 3),
      ChartRange.fiveYears => const Duration(days: 15),
    };
    final now = DateTime.now();
    return [
      for (var i = 0; i < h.length; i++)
        ChartPoint(now.subtract(step * (h.length - 1 - i)), h[i]),
    ];
  }

  @override
  DateTime quoteTime(String symbol) => DateTime.now();

  @override
  double priceOf(String symbol) => _prices[symbol] ?? 0;

  @override
  double changePercent(String symbol) {
    final open = _open[symbol] ?? 0;
    if (open == 0) return 0;
    return (priceOf(symbol) - open) / open * 100;
  }

  @override
  List<double> history(String symbol) => List.of(_history[symbol] ?? const []);

  @override
  void start(void Function() onUpdate) {
    _timer?.cancel();
    _timer = Timer.periodic(GameConfig.tickInterval, (_) {
      _tick();
      onUpdate();
    });
  }

  @override
  void stop() => _timer?.cancel();
}
