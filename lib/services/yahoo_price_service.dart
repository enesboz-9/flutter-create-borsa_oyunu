import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/market_hours.dart';
import '../data/assets_catalog.dart';
import '../models/asset.dart';
import 'price_service.dart';

/// Gerçek piyasa verisi (Yahoo Finance grafik uç noktası, anahtar gerekmez).
///
/// - BIST: ~15 dk gecikmeli, ABD hisseleri/kripto/vadeli (altın, gümüş...) neredeyse anlık.
/// - Piyasa kapalıyken fiyat sabit kalır (son kapanış), hareket etmez.
/// - Açık piyasalar [_openRefresh], kapalı olanlar [_closedRefresh] aralığıyla yenilenir.
/// - Veri kaynağı olmayan varlıklar (ör. Rodyum) başlangıç fiyatında sabit kalır.
///
/// Not: Yahoo resmi bir API değildir; yayın aşamasında lisanslı bir veri
/// sağlayıcıya (veya kendi sunucundaki proxy'ye) geçmen önerilir.
class YahooPriceService implements PriceService {
  YahooPriceService({http.Client? client}) : _client = client ?? http.Client() {
    for (final a in kAssets) {
      _prices[a.symbol] = a.basePrice;
      _prev[a.symbol] = a.basePrice;
      _history[a.symbol] = [a.basePrice, a.basePrice];
      final spec = _specFor(a);
      if (spec != null) {
        _specs[a.symbol] = spec;
        _deps.putIfAbsent(spec.yahoo, () => []).add(a);
        if (spec.fx) _deps.putIfAbsent(_fxSymbol, () => []);
      }
    }
  }

  static const _fxSymbol = 'USDTRY=X';
  static const _openRefresh = Duration(seconds: 30);
  static const _closedRefresh = Duration(minutes: 15);
  static const _parallel = 6;
  static const _ozGram = 31.1035;

  final http.Client _client;
  final Map<String, double> _prices = {};
  final Map<String, double> _prev = {};
  final Map<String, List<double>> _history = {};
  final Map<String, _Spec> _specs = {};
  final Map<String, List<Asset>> _deps = {}; // yahoo sembolü -> bağlı varlıklar
  final Map<String, _Quote> _quotes = {};
  final Map<String, DateTime> _lastFetch = {};

  Timer? _timer;
  bool _busy = false;
  void Function()? _onUpdate;

  // ---------------------------------------------------------------- eşleme

  /// Kripto için Yahoo'daki özel kodlar (bazıları sayı ekli; bulunamazsa
  /// fiyat başlangıç değerinde kalır).
  static const _cryptoOverride = {
    'SUI': 'SUI20947-USD',
    'APT': 'APT21794-USD',
    'TON': 'TON11419-USD',
    'ARB': 'ARB11841-USD',
    'PEPE': 'PEPE24478-USD',
    'POL': 'POL28321-USD',
  };

  _Spec? _specFor(Asset a) {
    final s = a.symbol;
    switch (a.category) {
      case AssetCategory.bist:
        return _Spec('$s.IS');
      case AssetCategory.us:
        return _Spec(s == 'BRKB' ? 'BRK-B' : s);
      case AssetCategory.crypto:
        return _Spec(_cryptoOverride[s] ?? '$s-USD', fx: true);
      case AssetCategory.forex:
        final code = s.substring(0, 3);
        return _Spec('${code}TRY=X', mult: s == 'JPYTRY' ? 100 : 1);
      case AssetCategory.metal:
        switch (s) {
          case 'XAUONS':
            return _Spec('GC=F', fx: true);
          case 'XAU':
            return _Spec('GC=F', fx: true, mult: 1 / _ozGram);
          case 'CEYREK':
            return _Spec('GC=F', fx: true, mult: 1.6065 / _ozGram);
          case 'YARIM':
            return _Spec('GC=F', fx: true, mult: 3.213 / _ozGram);
          case 'TAM':
            return _Spec('GC=F', fx: true, mult: 6.426 / _ozGram);
          case 'ATA':
            return _Spec('GC=F', fx: true, mult: 6.610 / _ozGram);
          case 'GA22':
            return _Spec('GC=F', fx: true, mult: 0.916 / _ozGram);
          case 'GA14':
            return _Spec('GC=F', fx: true, mult: 0.585 / _ozGram);
          case 'XAGONS':
            return _Spec('SI=F', fx: true);
          case 'XAG':
            return _Spec('SI=F', fx: true, mult: 1 / _ozGram);
          case 'XPT':
            return _Spec('PL=F', fx: true, mult: 1 / _ozGram);
          case 'XPD':
            return _Spec('PA=F', fx: true, mult: 1 / _ozGram);
          default:
            return null; // Rodyum vb.: canlı kaynak yok
        }
    }
  }

  // ----------------------------------------------------------- çalışma döngüsü

  @override
  void start(void Function() onUpdate) {
    _onUpdate = onUpdate;
    _timer?.cancel();
    _refreshDue();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshDue());
  }

  @override
  void stop() {
    _timer?.cancel();
    _client.close();
  }

  bool _isOpenFor(String yahoo) {
    final assets = _deps[yahoo] ?? const [];
    return assets.any((a) => isMarketOpen(a));
  }

  Future<void> _refreshDue() async {
    if (_busy) return;
    _busy = true;
    try {
      final now = DateTime.now();
      final due = <String>[];
      for (final y in _deps.keys) {
        final last = _lastFetch[y];
        final every = _isOpenFor(y) ? _openRefresh : _closedRefresh;
        if (last == null || now.difference(last) >= every) due.add(y);
      }
      // USD/TL kuru her zaman önce gelsin (çarpanlı varlıklar ona bağlı).
      due.sort((a, b) => a == _fxSymbol ? -1 : (b == _fxSymbol ? 1 : 0));
      var changed = false;
      for (var i = 0; i < due.length; i += _parallel) {
        final batch = due.skip(i).take(_parallel).toList();
        final res = await Future.wait(batch.map(_fetch));
        if (res.any((r) => r)) {
          _recompute();
          changed = true;
        }
      }
      if (changed) _onUpdate?.call();
    } finally {
      _busy = false;
    }
  }

  Future<bool> _fetch(String yahoo) async {
    _lastFetch[yahoo] = DateTime.now();
    try {
      final uri = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/${Uri.encodeComponent(yahoo)}'
          '?interval=1m&range=1d');
      final r = await _client
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return false;
      final result = (jsonDecode(r.body)['chart']['result'] as List?)?.first;
      if (result == null) return false;
      final meta = result['meta'] as Map;
      final price = (meta['regularMarketPrice'] as num?)?.toDouble();
      if (price == null || price <= 0) return false;
      final prev = ((meta['chartPreviousClose'] ?? meta['previousClose']) as num?)
              ?.toDouble() ??
          price;
      final closes = <double>[];
      final q = (result['indicators']?['quote'] as List?)?.first;
      for (final c in (q?['close'] as List? ?? const [])) {
        if (c is num) closes.add(c.toDouble());
      }
      if (closes.isEmpty || closes.last != price) closes.add(price);
      final t = (meta['regularMarketTime'] as num?)?.toInt();
      final qt = t == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true);
      _quotes[yahoo] = _Quote(price, prev, closes, qt);
      return true;
    } catch (_) {
      return false; // ağ hatası: son bilinen değer korunur
    }
  }

  void _recompute() {
    final fx = _quotes[_fxSymbol];
    for (final a in kAssets) {
      final spec = _specs[a.symbol];
      final q = spec == null ? null : _quotes[spec.yahoo];
      if (spec == null || q == null) continue;
      if (spec.fx && fx == null) continue;
      final k = spec.mult * (spec.fx ? fx!.price : 1);
      _prices[a.symbol] = q.price * k;
      _prev[a.symbol] =
          q.prevClose * spec.mult * (spec.fx ? fx!.prevClose : 1);
      var h = q.closes.map((c) => c * k).toList();
      if (h.length > GameConfig.historyLength) {
        h = h.sublist(h.length - GameConfig.historyLength);
      }
      if (h.length < 2) h = [h.first, h.first];
      _history[a.symbol] = h;
    }
  }

  // ---------------------------------------------------------------- arayüz

  // ------------------------------------------------------------ geçmiş grafik

  static const _rangeParams = {
    ChartRange.day: ('1d', '5m'),
    ChartRange.week: ('5d', '15m'),
    ChartRange.month: ('1mo', '60m'),
    ChartRange.threeMonths: ('3mo', '1d'),
    ChartRange.year: ('1y', '1d'),
    ChartRange.fiveYears: ('5y', '1wk'),
  };

  final Map<String, (DateTime, List<ChartPoint>)> _seriesCache = {};

  Future<List<ChartPoint>> _series(String yahoo, ChartRange r) async {
    final key = '$yahoo|${r.name}';
    final cached = _seriesCache[key];
    final ttl = r == ChartRange.day
        ? const Duration(minutes: 1)
        : const Duration(minutes: 30);
    if (cached != null && DateTime.now().difference(cached.$1) < ttl) {
      return cached.$2;
    }
    try {
      final p = _rangeParams[r]!;
      final uri = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/${Uri.encodeComponent(yahoo)}'
          '?interval=${p.$2}&range=${p.$1}');
      final res = await _client
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return cached?.$2 ?? const [];
      final result = (jsonDecode(res.body)['chart']['result'] as List?)?.first;
      if (result == null) return cached?.$2 ?? const [];
      final ts = (result['timestamp'] as List?) ?? const [];
      final q = (result['indicators']?['quote'] as List?)?.first;
      final closes = (q?['close'] as List?) ?? const [];
      final out = <ChartPoint>[];
      for (var i = 0; i < ts.length && i < closes.length; i++) {
        final c = closes[i];
        final t = ts[i];
        if (c is num && t is num) {
          out.add(ChartPoint(
              DateTime.fromMillisecondsSinceEpoch(t.toInt() * 1000, isUtc: true)
                  .toLocal(),
              c.toDouble()));
        }
      }
      _seriesCache[key] = (DateTime.now(), out);
      return out;
    } catch (_) {
      return cached?.$2 ?? const [];
    }
  }

  @override
  Future<List<ChartPoint>> chart(String symbol, ChartRange range) async {
    final spec = _specs[symbol];
    if (spec == null) return const [];
    final base = await _series(spec.yahoo, range);
    if (base.isEmpty) return const [];
    List<ChartPoint> fx = const [];
    if (spec.fx) {
      fx = await _series(_fxSymbol, range);
      if (fx.isEmpty) return const [];
    }
    final out = <ChartPoint>[];
    var j = 0;
    for (final p in base) {
      var k = spec.mult;
      if (spec.fx) {
        // Her nokta için o ana en yakın (önceki) USD/TL kuru kullanılır.
        while (j + 1 < fx.length && !fx[j + 1].time.isAfter(p.time)) {
          j++;
        }
        k *= fx[j].price;
      }
      out.add(ChartPoint(p.time, p.price * k));
    }
    return out;
  }

  @override
  DateTime quoteTime(String symbol) {
    final spec = _specs[symbol];
    final q = spec == null ? null : _quotes[spec.yahoo];
    // Canlı kaynağı olmayan varlıklar (ör. Rodyum) için şimdiki zaman döner.
    if (spec == null) return DateTime.now();
    return q?.time ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  @override
  double priceOf(String symbol) => _prices[symbol] ?? 0;

  /// Bir önceki kapanışa göre günlük değişim.
  @override
  double changePercent(String symbol) {
    final prev = _prev[symbol] ?? 0;
    if (prev == 0) return 0;
    return (priceOf(symbol) - prev) / prev * 100;
  }

  @override
  List<double> history(String symbol) => List.of(_history[symbol] ?? const []);
}

class _Spec {
  const _Spec(this.yahoo, {this.fx = false, this.mult = 1});
  final String yahoo;
  final bool fx; // sonucu USD/TL ile çarp
  final double mult;
}

class _Quote {
  const _Quote(this.price, this.prevClose, this.closes, this.time);
  final double price;
  final double prevClose;
  final List<double> closes;
  final DateTime time;
}
