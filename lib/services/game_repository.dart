import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/position.dart';
import '../models/price_alert.dart';
import '../models/trade_record.dart';

class GameSnapshot {
  const GameSnapshot({
    required this.cash,
    required this.positions,
    required this.history,
    this.alerts = const [],
  });

  final double cash;
  final List<Position> positions;
  final List<TradeRecord> history;
  final List<PriceAlert> alerts;
}

/// Oyun durumunun saklandığı yer.
///
/// Şimdilik cihazda saklanır (LocalGameRepository). Veritabanını eklerken
/// bu arayüzü uygulayan bir SupabaseGameRepository yazman yeterli.
abstract class GameRepository {
  Future<GameSnapshot?> load();
  Future<void> save(GameSnapshot snapshot);
  Future<void> clear();
}

class LocalGameRepository implements GameRepository {
  static const _key = 'game_v1';

  @override
  Future<GameSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return GameSnapshot(
        cash: (m['cash'] as num).toDouble(),
        positions: (m['positions'] as List)
            .map((e) => Position.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: (m['history'] as List)
            .map((e) => TradeRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        // Eski kayıtlarda 'alerts' yoktur.
        alerts: ((m['alerts'] as List?) ?? const [])
            .map((e) => PriceAlert.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(GameSnapshot s) async {
    final prefs = await SharedPreferences.getInstance();
    final history = s.history.length > GameConfig.maxHistory
        ? s.history.sublist(0, GameConfig.maxHistory)
        : s.history;
    await prefs.setString(
      _key,
      jsonEncode({
        'cash': s.cash,
        'positions': s.positions.map((e) => e.toJson()).toList(),
        'history': history.map((e) => e.toJson()).toList(),
        'alerts': s.alerts.map((e) => e.toJson()).toList(),
      }),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
