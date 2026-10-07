import 'package:flutter/material.dart';

class GameConfig {
  /// Her oyuncunun başlangıç bakiyesi (sanal TL).
  static const double startingBalance = 1000000;

  /// Bakım teminatı oranı (likidasyon hesabında kullanılır).
  static const double maintenanceMargin = 0.005;

  /// true yapılırsa kapalı piyasalarda işlem engellenir (BIST mesai saatleri vb.).
  static const bool enforceMarketHours = false;

  /// Mock fiyat servisinin güncelleme aralığı.
  static const Duration tickInterval = Duration(seconds: 2);

  /// Grafikte tutulan nokta sayısı.
  static const int historyLength = 120;

  /// Kayıtlı işlem geçmişi üst sınırı.
  static const int maxHistory = 200;
}

const Color kGreen = Color(0xFF16C784);
const Color kRed = Color(0xFFEA3943);

Color? pnlColor(double v) => v > 0 ? kGreen : (v < 0 ? kRed : null);
