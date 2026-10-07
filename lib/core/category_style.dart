import 'package:flutter/material.dart';

import '../models/asset.dart';

extension AssetCategoryStyle on AssetCategory {
  IconData get icon => switch (this) {
        AssetCategory.bist => Icons.business_outlined,
        AssetCategory.crypto => Icons.currency_bitcoin,
        AssetCategory.forex => Icons.currency_exchange,
        AssetCategory.metal => Icons.diamond_outlined,
      };

  Color get color => switch (this) {
        AssetCategory.bist => const Color(0xFF4DA3FF),
        AssetCategory.crypto => const Color(0xFFF7931A),
        AssetCategory.forex => const Color(0xFF2ED3B7),
        AssetCategory.metal => const Color(0xFFFFC857),
      };
}
