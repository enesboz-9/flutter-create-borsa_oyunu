import 'dart:async';

import 'package:flutter/material.dart';

import '../core/category_style.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../models/asset.dart';

/// Yuvarlak köşeli, hafif çerçeveli kart. İsteğe bağlı gradient ve dokunma.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.onTap,
    this.borderColor,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? kCard : null,
        gradient: gradient,
        borderRadius: r,
        border: Border.all(color: borderColor ?? Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Toplam varlığın yanında gösterilen dolar rozeti (örn. $1.234,56).
class UsdChip extends StatelessWidget {
  const UsdChip({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        fmtUsd(amount),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Yüzde ya da tutar için renkli küçük hap rozet.
class PnlPill extends StatelessWidget {
  const PnlPill({super.key, required this.value, required this.text, this.small = false});

  final double value;
  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = pnlColor(value) ?? kMuted;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Fiyat değişince kısa süre yeşil/kırmızı yanıp sönen metin.
class PriceText extends StatefulWidget {
  const PriceText({super.key, required this.value, required this.text, this.style});

  final double value;
  final String text;
  final TextStyle? style;

  @override
  State<PriceText> createState() => _PriceTextState();
}

class _PriceTextState extends State<PriceText> {
  Color? _flash;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant PriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _flash = widget.value > oldWidget.value ? kGreen : kRed;
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flash = null);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: base.copyWith(color: _flash),
      child: Text(widget.text),
    );
  }
}

/// Kategori renginde, sembol baş harfli yuvarlak simge.
class AssetAvatar extends StatelessWidget {
  const AssetAvatar({super.key, required this.asset, this.size = 44});

  final Asset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = asset.category.color;
    final label = asset.symbol.length <= 3
        ? asset.symbol
        : asset.symbol.substring(0, 2);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withOpacity(0.35), c.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.28,
        ),
      ),
    );
  }
}

/// Küçük çizgi grafik (liste satırları için).
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.color});

  final List<double> values;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final up = values.length < 2 || values.last >= values.first;
    return CustomPaint(
      painter: _SparkPainter(values, color ?? (up ? kGreen : kRed)),
      size: Size.infinite,
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var minV = values.first;
    var maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    var range = maxV - minV;
    if (range == 0) range = 1;
    const pad = 2.0;
    final h = size.height - pad * 2;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = pad + h - (values[i] - minV) / range * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => true;
}

/// Gradient dolgulu, gölgeli büyük buton.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.onPressed,
    this.icon,
    this.foreground = Colors.white,
  });

  final String label;
  final LinearGradient gradient;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: foreground, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sol etiket, sağ değer satırı.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.valueColor, this.bold = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kMuted)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bölüm başlığı.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(color: kMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

String signedTl(double v) => fmtSigned(v);
