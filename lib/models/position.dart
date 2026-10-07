import '../core/constants.dart';

enum Side { long, short }

class Position {
  const Position({
    required this.id,
    required this.symbol,
    required this.side,
    required this.leverage,
    required this.margin,
    required this.entryPrice,
    required this.quantity,
    required this.openCommission,
    required this.openedAt,
  });

  final String id;
  final String symbol;
  final Side side;
  final int leverage;

  /// Yatırılan teminat (TL).
  final double margin;
  final double entryPrice;

  /// Pozisyon büyüklüğü / giriş fiyatı.
  final double quantity;
  final double openCommission;
  final DateTime openedAt;

  double get notional => margin * leverage;

  double pnlAt(double price) => side == Side.long
      ? (price - entryPrice) * quantity
      : (entryPrice - price) * quantity;

  double get liquidationPrice => liquidationPriceFor(
        side: side,
        entryPrice: entryPrice,
        leverage: leverage,
      );

  bool isLiquidatedAt(double price) =>
      side == Side.long ? price <= liquidationPrice : price >= liquidationPrice;

  static double liquidationPriceFor({
    required Side side,
    required double entryPrice,
    required int leverage,
  }) {
    const m = GameConfig.maintenanceMargin;
    return side == Side.long
        ? entryPrice * (1 - 1 / leverage + m)
        : entryPrice * (1 + 1 / leverage - m);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.name,
        'leverage': leverage,
        'margin': margin,
        'entryPrice': entryPrice,
        'quantity': quantity,
        'openCommission': openCommission,
        'openedAt': openedAt.toIso8601String(),
      };

  factory Position.fromJson(Map<String, dynamic> j) => Position(
        id: j['id'] as String,
        symbol: j['symbol'] as String,
        side: Side.values.byName(j['side'] as String),
        leverage: (j['leverage'] as num).toInt(),
        margin: (j['margin'] as num).toDouble(),
        entryPrice: (j['entryPrice'] as num).toDouble(),
        quantity: (j['quantity'] as num).toDouble(),
        openCommission: (j['openCommission'] as num).toDouble(),
        openedAt: DateTime.parse(j['openedAt'] as String),
      );
}
