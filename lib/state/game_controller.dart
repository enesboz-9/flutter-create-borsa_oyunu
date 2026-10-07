import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/market_hours.dart';
import '../data/assets_catalog.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../models/price_alert.dart';
import '../models/trade_record.dart';
import '../services/game_repository.dart';
import '../services/price_service.dart';

/// Oyunun tüm iş mantığı burada: pozisyon açma/kapama, komisyon, likidasyon,
/// fiyat alarmları.
///
/// Not: Veritabanına geçince bu hesapların sunucuda (Edge Function / DB
/// fonksiyonu) yapılması gerekir; aksi halde istemci bakiyeyi değiştirebilir.
class GameController extends ChangeNotifier {
  GameController(this._prices, this._repo);

  final PriceService _prices;
  final GameRepository _repo;

  double _cash = GameConfig.startingBalance;
  List<Position> _positions = [];
  List<TradeRecord> _history = [];
  List<PriceAlert> _alerts = [];
  bool _ready = false;

  final StreamController<String> _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  /// Bir alarm tetiklendiğinde yayınlanır (arayüz bildirim gösterir).
  final StreamController<PriceAlert> _alertHits =
      StreamController<PriceAlert>.broadcast();
  Stream<PriceAlert> get alertHits => _alertHits.stream;

  bool get ready => _ready;
  double get cash => _cash;
  List<Position> get positions => List.unmodifiable(_positions);
  List<TradeRecord> get history => List.unmodifiable(_history);
  List<PriceAlert> get alerts => List.unmodifiable(_alerts);
  int get activeAlertCount => _alerts.where((a) => a.isActive).length;

  Future<void> init() async {
    final s = await _repo.load();
    if (s != null) {
      _cash = s.cash;
      _positions = List.of(s.positions);
      _history = List.of(s.history);
      _alerts = List.of(s.alerts);
    }
    _prices.start(_onTick);
    _ready = true;
    notifyListeners();
  }

  // ---- Fiyat erişimi ----
  Asset assetOf(String symbol) => kAssets.firstWhere((a) => a.symbol == symbol);
  Asset? findAsset(String symbol) {
    for (final a in kAssets) {
      if (a.symbol == symbol) return a;
    }
    return null;
  }

  double priceOf(String symbol) => _prices.priceOf(symbol);
  double changePercent(String symbol) => _prices.changePercent(symbol);
  List<double> historyOf(String symbol) => _prices.history(symbol);

  // ---- Hesap özeti ----
  double get usedMargin => _positions.fold(0.0, (s, p) => s + p.margin);

  double get unrealizedPnl =>
      _positions.fold(0.0, (s, p) => s + p.pnlAt(priceOf(p.symbol)));

  double get equity => _cash + usedMargin + unrealizedPnl;

  double get totalReturnPercent =>
      (equity - GameConfig.startingBalance) / GameConfig.startingBalance * 100;

  // ---- İşlemler ----
  double commissionFor(Asset asset, double margin, int leverage) =>
      margin * leverage * asset.category.commissionRate;

  /// Başarılıysa null, değilse hata mesajı döner.
  String? openPosition({
    required Asset asset,
    required Side side,
    required double margin,
    required int leverage,
    double? atPrice,
  }) {
    if (margin <= 0) return 'Teminat tutarını girin.';
    if (leverage < 1 || leverage > asset.category.maxLeverage) {
      return 'Kaldıraç 1x ile ${asset.category.maxLeverage}x arasında olmalı.';
    }
    if (GameConfig.enforceMarketHours && !isMarketOpen(asset)) {
      return '${asset.name} piyasası şu an kapalı.';
    }
    // atPrice: kullanıcının ekranda gördüğü fiyat. Verilirse işlem tam bu
    // fiyattan yapılır; onay anında gelen tik fiyatı etkilemez.
    final price = (atPrice != null && atPrice > 0)
        ? atPrice
        : priceOf(asset.symbol);
    if (price <= 0) return 'Fiyat alınamadı.';

    final commission = commissionFor(asset, margin, leverage);
    if (margin + commission > _cash + 1e-9) return 'Yetersiz bakiye.';

    final newQty = margin * leverage / price;
    // Aynı varlık + yön + kaldıraç varsa mevcut pozisyona eklenir ve
    // ortalama maliyet güncellenir.
    final idx = _positions.indexWhere((x) =>
        x.symbol == asset.symbol && x.side == side && x.leverage == leverage);
    final Position held;
    if (idx >= 0) {
      final e = _positions[idx];
      final qty = e.quantity + newQty;
      held = e.copyWith(
        margin: e.margin + margin,
        quantity: qty,
        entryPrice: (e.entryPrice * e.quantity + price * newQty) / qty,
        openCommission: e.openCommission + commission,
      );
      _positions[idx] = held;
    } else {
      held = Position(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        symbol: asset.symbol,
        side: side,
        leverage: leverage,
        margin: margin,
        entryPrice: price,
        quantity: newQty,
        openCommission: commission,
        openedAt: DateTime.now(),
      );
      _positions.add(held);
    }
    _cash -= margin + commission;
    _events.add(
        '${asset.symbol} ${side == Side.long ? 'LONG' : 'SHORT'} ${leverage}x: ${fmtQty(newQty)} adet ₺${fmtPrice(price)} fiyatından alındı. Komisyon: ${fmtTl(commission)} • Ort. maliyet: ₺${fmtPrice(held.avgCost)}');
    _persist();
    notifyListeners();
    return null;
  }

  Position? positionById(String id) {
    for (final p in _positions) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// [atPrice]: kullanıcının butona bastığı anda ekranda gördüğü fiyat.
  /// Verilirse işlem tam bu fiyattan yapılır; arada gelen fiyat güncellemeleri
  /// sonucu etkilemez. Verilmezse güncel fiyat kullanılır.
  ///
  /// [quantity]: kapatılacak adet. Verilmezse pozisyonun tamamı kapanır.
  /// Kısmi kapatmada teminat, açılış komisyonu ve adet orantılı düşer;
  /// kalan pozisyonun ortalama maliyeti değişmez.
  String? closePosition(String id, {double? atPrice, double? quantity}) {
    final idx = _positions.indexWhere((p) => p.id == id);
    if (idx < 0) return 'Pozisyon bulunamadı.';
    final p = _positions[idx];
    final asset = assetOf(p.symbol);
    if (GameConfig.enforceMarketHours && !isMarketOpen(asset)) {
      return '${asset.name} piyasası şu an kapalı.';
    }
    final price =
        (atPrice != null && atPrice > 0) ? atPrice : priceOf(p.symbol);
    if (price <= 0) return 'Fiyat alınamadı.';

    var qty = quantity ?? p.quantity;
    if (qty <= 0) return 'Satılacak adedi girin.';
    if (qty > p.quantity * (1 + 1e-9)) {
      return 'Elindeki adetten fazlasını satamazsın (${fmtQty(p.quantity)}).';
    }
    final full = qty >= p.quantity * (1 - 1e-9);
    if (full) qty = p.quantity;

    final f = qty / p.quantity;
    final marginPart = p.margin * f;
    final openCommPart = p.openCommission * f;
    final gross = p.side == Side.long
        ? (price - p.entryPrice) * qty
        : (p.entryPrice - price) * qty;
    final closeCommission = price * qty * asset.category.commissionRate;

    _cash += max(0.0, marginPart + gross - closeCommission);
    if (full) {
      _positions.removeAt(idx);
    } else {
      _positions[idx] = p.copyWith(
        margin: p.margin - marginPart,
        quantity: p.quantity - qty,
        openCommission: p.openCommission - openCommPart,
      );
    }
    final record = TradeRecord(
      id: full ? p.id : '${p.id}-${DateTime.now().microsecondsSinceEpoch}',
      symbol: p.symbol,
      side: p.side,
      leverage: p.leverage,
      margin: marginPart,
      entryPrice: p.entryPrice,
      exitPrice: price,
      grossPnl: gross,
      commission: openCommPart + closeCommission,
      reason: CloseReason.manual,
      openedAt: p.openedAt,
      closedAt: DateTime.now(),
      quantity: qty,
    );
    _history.insert(0, record);
    _events.add(
        '${p.symbol} ${fmtQty(qty)} adet ₺${fmtPrice(price)} fiyatından ${full ? 'kapatıldı' : 'satıldı'}. Net: ${fmtSigned(record.netPnl)}');
    _persist();
    notifyListeners();
    return null;
  }

  Future<void> resetGame() async {
    _cash = GameConfig.startingBalance;
    _positions = [];
    _history = [];
    _alerts = [];
    await _repo.clear();
    notifyListeners();
  }

  // ---- Fiyat alarmları ----
  List<PriceAlert> alertsFor(String symbol) =>
      _alerts.where((a) => a.symbol == symbol).toList();

  int activeAlertCountFor(String symbol) =>
      _alerts.where((a) => a.symbol == symbol && a.isActive).length;

  /// Başarılıysa null, değilse hata mesajı döner.
  /// Yön (yukarı/aşağı) hedef fiyatın güncel fiyata göre konumundan belirlenir.
  ///
  /// [auto] true ise alarm tetiklenince emir kendiliğinden çalışır:
  /// - [intent] buy: [orderMargin] teminat ve [orderLeverage] ile long açar.
  /// - [intent] sell: eldeki long pozisyonlardan [orderPercent] yüzde ya da
  ///   [orderQuantity] adet satar.
  String? addAlert({
    required Asset asset,
    required double targetPrice,
    AlertIntent intent = AlertIntent.none,
    bool auto = false,
    double? orderMargin,
    int orderLeverage = 1,
    double? orderQuantity,
    double? orderPercent,
  }) {
    if (targetPrice <= 0) return 'Hedef fiyatı girin.';
    if (auto) {
      if (intent == AlertIntent.buy) {
        if (orderMargin == null || orderMargin <= 0) {
          return 'Alınacak teminat tutarını girin.';
        }
        if (orderLeverage < 1 || orderLeverage > asset.category.maxLeverage) {
          return 'Kaldıraç 1x ile ${asset.category.maxLeverage}x arasında olmalı.';
        }
      } else if (intent == AlertIntent.sell) {
        final hasPct =
            orderPercent != null && orderPercent > 0 && orderPercent <= 100;
        final hasQty = orderQuantity != null && orderQuantity > 0;
        if (!hasPct && !hasQty) return 'Satılacak adedi ya da yüzdeyi girin.';
      } else {
        return 'Otomatik emir için Al ya da Sat seçin.';
      }
    }
    final price = priceOf(asset.symbol);
    if (price <= 0) return 'Fiyat alınamadı.';
    if ((targetPrice - price).abs() / price < 1e-6) {
      return 'Hedef fiyat güncel fiyattan farklı olmalı.';
    }
    if (activeAlertCount >= GameConfig.maxActiveAlerts) {
      return 'En fazla ${GameConfig.maxActiveAlerts} aktif alarm kurabilirsin.';
    }

    _alerts.insert(
      0,
      PriceAlert(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        symbol: asset.symbol,
        targetPrice: targetPrice,
        direction:
            targetPrice > price ? AlertDirection.above : AlertDirection.below,
        intent: intent,
        createdAt: DateTime.now(),
        auto: auto,
        orderMargin: auto && intent == AlertIntent.buy ? orderMargin : null,
        orderLeverage: auto && intent == AlertIntent.buy ? orderLeverage : 1,
        orderQuantity: auto && intent == AlertIntent.sell && orderPercent == null
            ? orderQuantity
            : null,
        orderPercent: auto && intent == AlertIntent.sell ? orderPercent : null,
      ),
    );
    // Toplam sınırı aşılırsa en eski tetiklenmiş alarmları sil.
    while (_alerts.length > GameConfig.maxAlerts) {
      final idx = _alerts.lastIndexWhere((a) => !a.isActive);
      if (idx < 0) break;
      _alerts.removeAt(idx);
    }
    _persist();
    notifyListeners();
    return null;
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    _persist();
    notifyListeners();
  }

  void clearTriggeredAlerts() {
    _alerts.removeWhere((a) => !a.isActive);
    _persist();
    notifyListeners();
  }

  List<PriceAlert> _checkAlerts() {
    final hits = <PriceAlert>[];
    for (var i = 0; i < _alerts.length; i++) {
      final a = _alerts[i];
      if (!a.isActive) continue;
      final price = priceOf(a.symbol);
      if (price > 0 && a.isHitBy(price)) {
        final t = a.triggered(price, DateTime.now());
        _alerts[i] = t;
        hits.add(t);
      }
    }
    return hits;
  }

  /// Tetiklenen otomatik emri tetik fiyatından çalıştırır; sonucu açıklar.
  String _runOrder(PriceAlert a, double price) {
    final asset = findAsset(a.symbol);
    if (asset == null) return 'Başarısız: varlık bulunamadı.';

    if (a.intent == AlertIntent.buy) {
      final margin = a.orderMargin ?? 0;
      final err = openPosition(
        asset: asset,
        side: Side.long,
        margin: margin,
        leverage: a.orderLeverage,
        atPrice: price,
      );
      if (err != null) return 'Emir gerçekleşmedi: $err';
      return 'Alındı: ${fmtQty(margin * a.orderLeverage / price)} adet • ₺${fmtPrice(price)}';
    }

    // Sat: eldeki long pozisyonlar (eskiden yeniye).
    final held = _positions
        .where((p) => p.symbol == a.symbol && p.side == Side.long)
        .toList();
    if (held.isEmpty) return 'Emir gerçekleşmedi: satılacak pozisyon yok.';

    var sold = 0.0;
    if (a.orderPercent != null) {
      final f = a.orderPercent! / 100;
      for (final p in held) {
        final q = f >= 1 ? null : p.quantity * f;
        final err = closePosition(p.id, atPrice: price, quantity: q);
        if (err != null) {
          return sold > 0
              ? 'Kısmen satıldı: ${fmtQty(sold)} adet. Kalanı: $err'
              : 'Emir gerçekleşmedi: $err';
        }
        sold += q ?? p.quantity;
      }
    } else {
      var remaining = a.orderQuantity ?? 0;
      for (final p in held) {
        if (remaining <= 0) break;
        final q = remaining < p.quantity ? remaining : p.quantity;
        final err = closePosition(p.id,
            atPrice: price, quantity: q >= p.quantity ? null : q);
        if (err != null) {
          return sold > 0
              ? 'Kısmen satıldı: ${fmtQty(sold)} adet. Kalanı: $err'
              : 'Emir gerçekleşmedi: $err';
        }
        sold += q;
        remaining -= q;
      }
      if (remaining > 1e-9) {
        return 'Satıldı: ${fmtQty(sold)} adet • ₺${fmtPrice(price)} (istenen ${fmtQty(a.orderQuantity!)} adetten fazla yoktu)';
      }
    }
    return 'Satıldı: ${fmtQty(sold)} adet • ₺${fmtPrice(price)}';
  }

  // ---- Likidasyon ----
  void _onTick() {
    final liquidated = <Position>[
      for (final p in _positions)
        if (p.isLiquidatedAt(priceOf(p.symbol))) p,
    ];
    for (final p in liquidated) {
      _liquidate(p);
    }
    final hits = <PriceAlert>[];
    for (final h in _checkAlerts()) {
      if (!h.auto) {
        hits.add(h);
        continue;
      }
      final done = h.withNote(_runOrder(h, h.triggeredPrice!));
      final i = _alerts.indexWhere((x) => x.id == h.id);
      if (i >= 0) _alerts[i] = done;
      hits.add(done);
    }
    if (liquidated.isNotEmpty || hits.isNotEmpty) _persist();
    notifyListeners();
    for (final h in hits) {
      _alertHits.add(h);
    }
  }

  void _liquidate(Position p) {
    _positions.removeWhere((x) => x.id == p.id);
    _history.insert(
      0,
      TradeRecord(
        id: p.id,
        symbol: p.symbol,
        side: p.side,
        leverage: p.leverage,
        margin: p.margin,
        entryPrice: p.entryPrice,
        exitPrice: p.liquidationPrice,
        grossPnl: -p.margin,
        commission: p.openCommission,
        reason: CloseReason.liquidation,
        openedAt: p.openedAt,
        closedAt: DateTime.now(),
        quantity: p.quantity,
      ),
    );
    _events.add('${p.symbol} pozisyonu likide edildi, teminat kaybedildi.');
  }

  void _persist() {
    unawaited(_repo.save(GameSnapshot(
      cash: _cash,
      positions: _positions,
      history: _history,
      alerts: _alerts,
    )));
  }

  @override
  void dispose() {
    _prices.stop();
    _events.close();
    _alertHits.close();
    super.dispose();
  }
}
