import 'position.dart';

/// Alarmın hangi yöne tetikleneceği (kurulduğu andaki fiyata göre belirlenir).
enum AlertDirection { above, below }

/// Alarm tetiklenince ne yapmak istediğin. Sadece bir hatırlatmadır;
/// işlem otomatik açılmaz, tek dokunuşla işlem ekranı açılır.
enum AlertIntent { none, buy, sell }

extension AlertIntentX on AlertIntent {
  String get label => switch (this) {
        AlertIntent.none => 'Haber ver',
        AlertIntent.buy => 'Al',
        AlertIntent.sell => 'Sat',
      };

  /// Alarmdan açılacak işlem yönü (haber ver ise null).
  Side? get side => switch (this) {
        AlertIntent.none => null,
        AlertIntent.buy => Side.long,
        AlertIntent.sell => Side.short,
      };
}

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.symbol,
    required this.targetPrice,
    required this.direction,
    required this.intent,
    required this.createdAt,
    this.triggeredAt,
    this.triggeredPrice,
  });

  final String id;
  final String symbol;
  final double targetPrice;
  final AlertDirection direction;
  final AlertIntent intent;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final double? triggeredPrice;

  bool get isActive => triggeredAt == null;

  bool isHitBy(double price) => direction == AlertDirection.above
      ? price >= targetPrice
      : price <= targetPrice;

  PriceAlert triggered(double price, DateTime at) => PriceAlert(
        id: id,
        symbol: symbol,
        targetPrice: targetPrice,
        direction: direction,
        intent: intent,
        createdAt: createdAt,
        triggeredAt: at,
        triggeredPrice: price,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'targetPrice': targetPrice,
        'direction': direction.name,
        'intent': intent.name,
        'createdAt': createdAt.toIso8601String(),
        'triggeredAt': triggeredAt?.toIso8601String(),
        'triggeredPrice': triggeredPrice,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> j) => PriceAlert(
        id: j['id'] as String,
        symbol: j['symbol'] as String,
        targetPrice: (j['targetPrice'] as num).toDouble(),
        direction: AlertDirection.values.byName(j['direction'] as String),
        intent: AlertIntent.values.byName(j['intent'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        triggeredAt: j['triggeredAt'] == null
            ? null
            : DateTime.parse(j['triggeredAt'] as String),
        triggeredPrice: (j['triggeredPrice'] as num?)?.toDouble(),
      );
}
