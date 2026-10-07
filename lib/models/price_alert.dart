import '../core/format.dart';
import 'position.dart';

/// Alarmın hangi yöne tetikleneceği (kurulduğu andaki fiyata göre belirlenir).
enum AlertDirection { above, below }

/// Alarmın türü.
/// - none: sadece bildirim.
/// - buy / sell + [PriceAlert.auto] = true: tetiklenince otomatik emir
///   (buy: long pozisyon aç, sell: eldeki long pozisyonu sat).
/// - buy / sell + auto = false: eski tip hatırlatma (bildirimdeki butonla
///   işlem sayfası açılır).
enum AlertIntent { none, buy, sell }

extension AlertIntentX on AlertIntent {
  String get label => switch (this) {
        AlertIntent.none => 'Haber ver',
        AlertIntent.buy => 'Al',
        AlertIntent.sell => 'Sat',
      };

  /// Hatırlatma bildiriminden açılacak işlem yönü (haber ver ise null).
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
    this.auto = false,
    this.orderMargin,
    this.orderLeverage = 1,
    this.orderQuantity,
    this.orderPercent,
    this.note,
  });

  final String id;
  final String symbol;
  final double targetPrice;
  final AlertDirection direction;
  final AlertIntent intent;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final double? triggeredPrice;

  /// true ise tetiklenince emir otomatik çalışır.
  final bool auto;

  /// Otomatik AL: harcanacak teminat (TL) ve kaldıraç.
  final double? orderMargin;
  final int orderLeverage;

  /// Otomatik SAT: ya sabit adet ya da eldekinin yüzdesi.
  final double? orderQuantity;
  final double? orderPercent;

  /// Tetiklenince emrin sonucu (gerçekleşti / neden olmadı).
  final String? note;

  bool get isActive => triggeredAt == null;

  bool isHitBy(double price) => direction == AlertDirection.above
      ? price >= targetPrice
      : price <= targetPrice;

  /// Kısa emir özeti (alarm satırında gösterilir).
  String get orderSummary {
    if (!auto) return '';
    if (intent == AlertIntent.buy) {
      return '₺${fmtPrice(orderMargin ?? 0)} teminatla al • ${orderLeverage}x';
    }
    if (orderPercent != null) {
      return 'Eldekinin %${orderPercent!.toStringAsFixed(0)}\'ini sat';
    }
    return '${fmtQty(orderQuantity ?? 0)} adet sat';
  }

  PriceAlert _copy({
    DateTime? triggeredAt,
    double? triggeredPrice,
    String? note,
  }) =>
      PriceAlert(
        id: id,
        symbol: symbol,
        targetPrice: targetPrice,
        direction: direction,
        intent: intent,
        createdAt: createdAt,
        triggeredAt: triggeredAt ?? this.triggeredAt,
        triggeredPrice: triggeredPrice ?? this.triggeredPrice,
        auto: auto,
        orderMargin: orderMargin,
        orderLeverage: orderLeverage,
        orderQuantity: orderQuantity,
        orderPercent: orderPercent,
        note: note ?? this.note,
      );

  PriceAlert triggered(double price, DateTime at) =>
      _copy(triggeredAt: at, triggeredPrice: price);

  PriceAlert withNote(String n) => _copy(note: n);

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'targetPrice': targetPrice,
        'direction': direction.name,
        'intent': intent.name,
        'createdAt': createdAt.toIso8601String(),
        'triggeredAt': triggeredAt?.toIso8601String(),
        'triggeredPrice': triggeredPrice,
        'auto': auto,
        'orderMargin': orderMargin,
        'orderLeverage': orderLeverage,
        'orderQuantity': orderQuantity,
        'orderPercent': orderPercent,
        'note': note,
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
        auto: (j['auto'] as bool?) ?? false,
        orderMargin: (j['orderMargin'] as num?)?.toDouble(),
        orderLeverage: (j['orderLeverage'] as num?)?.toInt() ?? 1,
        orderQuantity: (j['orderQuantity'] as num?)?.toDouble(),
        orderPercent: (j['orderPercent'] as num?)?.toDouble(),
        note: j['note'] as String?,
      );
}
