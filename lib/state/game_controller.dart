import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/market_hours.dart';
import '../data/assets_catalog.dart';
import '../models/asset.dart';
import '../models/position.dart';
import '../models/trade_record.dart';
import '../services/game_repository.dart';
import '../services/price_service.dart';

/// Oyunun tüm iş mantığı burada: pozisyon açma/kapama, komisyon, likidasyon.
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
  bool _ready = false;

  final StreamController<String> _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  bool get ready => _ready;
  double get cash => _cash;
  List<Position> get positions => List.unmodifiable(_positions);
  List<TradeRecord> get history => List.unmodifiable(_history);

  Future<void> init() async {
    final s = await _repo.load();
    if (s != null) {
      _cash = s.cash;
      _positions = List.of(s.positions);
      _history = List.of(s.history);
    }
    _prices.start(_onTick);
    _ready = true;
    notifyListeners();
  }

  // ---- Fiyat erişimi ----
  Asset assetOf(String symbol) => kAssets.firstWhere((a) => a.symbol == symbol);
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
  }) {
    if (margin <= 0) return 'Teminat tutarını girin.';
    if (leverage < 1 || leverage > asset.category.maxLeverage) {
      return 'Kaldıraç 1x ile ${asset.category.maxLeverage}x arasında olmalı.';
    }
    if (GameConfig.enforceMarketHours && !isMarketOpen(asset)) {
      return '${asset.name} piyasası şu an kapalı.';
    }
    final price = priceOf(asset.symbol);
    if (price <= 0) return 'Fiyat alınamadı.';

    final commission = commissionFor(asset, margin, leverage);
    if (margin + commission > _cash + 1e-9) return 'Yetersiz bakiye.';

    final position = Position(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      symbol: asset.symbol,
      side: side,
      leverage: leverage,
      margin: margin,
      entryPrice: price,
      quantity: margin * leverage / price,
      openCommission: commission,
      openedAt: DateTime.now(),
    );
    _cash -= margin + commission;
    _positions.add(position);
    _events.add(
        '${asset.symbol} ${side == Side.long ? 'LONG' : 'SHORT'} ${leverage}x açıldı. Komisyon: ${fmtTl(commission)}');
    _persist();
    notifyListeners();
    return null;
  }

  String? closePosition(String id) {
    final idx = _positions.indexWhere((p) => p.id == id);
    if (idx < 0) return 'Pozisyon bulunamadı.';
    final p = _positions[idx];
    final asset = assetOf(p.symbol);
    if (GameConfig.enforceMarketHours && !isMarketOpen(asset)) {
      return '${asset.name} piyasası şu an kapalı.';
    }
    final price = priceOf(p.symbol);
    final gross = p.pnlAt(price);
    final closeCommission = price * p.quantity * asset.category.commissionRate;

    _cash += max(0.0, p.margin + gross - closeCommission);
    _positions.removeAt(idx);
    final record = TradeRecord(
      id: p.id,
      symbol: p.symbol,
      side: p.side,
      leverage: p.leverage,
      margin: p.margin,
      entryPrice: p.entryPrice,
      exitPrice: price,
      grossPnl: gross,
      commission: p.openCommission + closeCommission,
      reason: CloseReason.manual,
      openedAt: p.openedAt,
      closedAt: DateTime.now(),
    );
    _history.insert(0, record);
    _events.add(
        '${p.symbol} pozisyonu kapatıldı. Net: ${fmtSigned(record.netPnl)}');
    _persist();
    notifyListeners();
    return null;
  }

  Future<void> resetGame() async {
    _cash = GameConfig.startingBalance;
    _positions = [];
    _history = [];
    await _repo.clear();
    notifyListeners();
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
    if (liquidated.isNotEmpty) _persist();
    notifyListeners();
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
      ),
    );
    _events.add('${p.symbol} pozisyonu likide edildi, teminat kaybedildi.');
  }

  void _persist() {
    unawaited(_repo.save(GameSnapshot(
      cash: _cash,
      positions: _positions,
      history: _history,
    )));
  }

  @override
  void dispose() {
    _prices.stop();
    _events.close();
    super.dispose();
  }
}
