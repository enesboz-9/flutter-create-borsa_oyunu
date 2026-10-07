import 'position.dart';

enum CloseReason { manual, liquidation }

class TradeRecord {
  const TradeRecord({
    required this.id,
    required this.symbol,
    required this.side,
    required this.leverage,
    required this.margin,
    required this.entryPrice,
    required this.exitPrice,
    required this.grossPnl,
    required this.commission,
    required this.reason,
    required this.openedAt,
    required this.closedAt,
  });

  final String id;
  final String symbol;
  final Side side;
  final int leverage;
  final double margin;
  final double entryPrice;
  final double exitPrice;

  /// Komisyon öncesi kâr/zarar.
  final double grossPnl;

  /// Açılış + kapanış komisyonu toplamı.
  final double commission;
  final CloseReason reason;
  final DateTime openedAt;
  final DateTime closedAt;

  double get netPnl => grossPnl - commission;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.name,
        'leverage': leverage,
        'margin': margin,
        'entryPrice': entryPrice,
        'exitPrice': exitPrice,
        'grossPnl': grossPnl,
        'commission': commission,
        'reason': reason.name,
        'openedAt': openedAt.toIso8601String(),
        'closedAt': closedAt.toIso8601String(),
      };

  factory TradeRecord.fromJson(Map<String, dynamic> j) => TradeRecord(
        id: j['id'] as String,
        symbol: j['symbol'] as String,
        side: Side.values.byName(j['side'] as String),
        leverage: (j['leverage'] as num).toInt(),
        margin: (j['margin'] as num).toDouble(),
        entryPrice: (j['entryPrice'] as num).toDouble(),
        exitPrice: (j['exitPrice'] as num).toDouble(),
        grossPnl: (j['grossPnl'] as num).toDouble(),
        commission: (j['commission'] as num).toDouble(),
        reason: CloseReason.values.byName(j['reason'] as String),
        openedAt: DateTime.parse(j['openedAt'] as String),
        closedAt: DateTime.parse(j['closedAt'] as String),
      );
}
