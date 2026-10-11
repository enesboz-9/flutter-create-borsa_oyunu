import '../core/format.dart';
import 'asset.dart';
import 'position.dart';

/// Emir türü.
/// - market: piyasa emri. Piyasa kapalıysa açılışta ilk fiyattan işleme girer.
/// - limit: alışta fiyat ≤ emir fiyatı, satışta fiyat ≥ emir fiyatı olunca işleme girer.
/// - stop: alışta fiyat ≥ emir fiyatı, satışta fiyat ≤ emir fiyatı olunca
///   piyasa emrine dönüşür (zarar durdur / kırılım alımı).
enum OrderType { market, limit, stop }

extension OrderTypeX on OrderType {
  String get label => switch (this) {
        OrderType.market => 'Piyasa',
        OrderType.limit => 'Limit',
        OrderType.stop => 'Stop',
      };
}

enum OrderAction { open, close }

/// Kuyrukta bekleyen emir. Piyasa kapalıyken verilen emirler ya da henüz
/// fiyatı gelmemiş limit/stop emirleri burada tutulur.
class PendingOrder {
  const PendingOrder({
    required this.id,
    required this.symbol,
    required this.action,
    required this.side,
    required this.type,
    required this.createdAt,
    this.triggerPrice,
    this.margin,
    this.leverage = 1,
    this.reserved = 0,
    this.positionId,
    this.quantity,
  });

  final String id;
  final String symbol;
  final OrderAction action;

  /// open: açılacak pozisyonun yönü. close: kapatılan pozisyonun yönü.
  final Side side;
  final OrderType type;
  final DateTime createdAt;

  /// Limit/stop emir fiyatı.
  final double? triggerPrice;

  // ---- Açılış emri ----
  final double? margin;
  final int leverage;

  /// Emir verilirken nakitten ayrılan tutar (teminat + komisyon).
  final double reserved;

  // ---- Kapanış emri ----
  final String? positionId;

  /// null ise pozisyonun tamamı.
  final double? quantity;

  /// Emir alış yönlü mü? (long açmak ve short kapatmak = alış)
  bool get isBuy => (action == OrderAction.open) == (side == Side.long);

  bool isTriggeredBy(double price) {
    final t = triggerPrice;
    switch (type) {
      case OrderType.market:
        return true;
      case OrderType.limit:
        return t != null && (isBuy ? price <= t : price >= t);
      case OrderType.stop:
        return t != null && (isBuy ? price >= t : price <= t);
    }
  }

  String summary(Currency cur) {
    final dir = action == OrderAction.open
        ? '${side == Side.long ? 'AL (Long)' : 'SAT (Short)'} ${leverage}x'
        : (side == Side.long ? 'SAT' : 'KAPAT (Short)');
    final price = type == OrderType.market || triggerPrice == null
        ? 'Piyasa • açılışta'
        : '${type.label} ${fmtPriceIn(triggerPrice!, cur)}';
    final size = action == OrderAction.open
        ? 'Teminat ${fmtMoney(margin ?? 0, cur)}'
        : (quantity == null ? 'Tamamı' : '${fmtQty(quantity!)} adet');
    return '$dir • $price • $size';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'action': action.name,
        'side': side.name,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'triggerPrice': triggerPrice,
        'margin': margin,
        'leverage': leverage,
        'reserved': reserved,
        'positionId': positionId,
        'quantity': quantity,
      };

  factory PendingOrder.fromJson(Map<String, dynamic> j) => PendingOrder(
        id: j['id'] as String,
        symbol: j['symbol'] as String,
        action: OrderAction.values.byName(j['action'] as String),
        side: Side.values.byName(j['side'] as String),
        type: OrderType.values.byName(j['type'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        triggerPrice: (j['triggerPrice'] as num?)?.toDouble(),
        margin: (j['margin'] as num?)?.toDouble(),
        leverage: (j['leverage'] as num?)?.toInt() ?? 1,
        reserved: (j['reserved'] as num?)?.toDouble() ?? 0,
        positionId: j['positionId'] as String?,
        quantity: (j['quantity'] as num?)?.toDouble(),
      );
}
