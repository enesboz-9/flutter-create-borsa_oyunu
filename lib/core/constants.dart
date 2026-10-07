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

  /// TL ⇄ USD çevirisinde alınan komisyon oranı (TL tutar üzerinden).
  static const double exchangeCommission = 0.0005;

  /// Dolar/TL kurunun alındığı varlık.
  static const String usdTrySymbol = 'USDTRY';

  /// Aynı anda kurulabilecek aktif alarm sayısı.
  static const int maxActiveAlerts = 30;

  /// Aktif + tetiklenmiş toplam alarm sayısı (eskiler silinir).
  static const int maxAlerts = 60;
}

// ---- Renkler ----
const Color kBg = Color(0xFF0B0F1A);
const Color kCard = Color(0xFF151B2B);
const Color kAccent = Color(0xFF7C6CFF);
const Color kGreen = Color(0xFF16C784);
const Color kRed = Color(0xFFEA3943);
const Color kMuted = Color(0xFF8A93A8);

const LinearGradient kHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6C5CE7), Color(0xFF00B8A9)],
);

const LinearGradient kBuyGradient = LinearGradient(
  colors: [Color(0xFF1BD38F), Color(0xFF0E9F6E)],
);

const LinearGradient kSellGradient = LinearGradient(
  colors: [Color(0xFFF2545B), Color(0xFFB4232C)],
);

Color? pnlColor(double v) => v > 0 ? kGreen : (v < 0 ? kRed : null);
