import 'package:flutter/material.dart';

/// A widget that displays the back of a playing card with a gradient
/// background and decorative diamond pattern.
///
/// Features:
/// - Theme-aware gradient background
/// - Custom painted diamond pattern
/// - Centered icon
/// - Proportional sizing
/// - Dual-shadow depth system
class CardBackWidget extends StatelessWidget {
  const CardBackWidget({
    required this.width,
    this.height,
    super.key,
  });

  final double width;
  final double? height;

  /// Height calculated from width to maintain 5:7 aspect ratio
  double get _height => height ?? (width * 1.4);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.primary;
    final darkColor = colorScheme.primaryContainer;

    return Container(
      width: width,
      height: _height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkColor, baseColor],
        ),
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(
          color: baseColor,
          width: 1.5,
        ),
        boxShadow: [
          // Outer shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: width * 0.15,
            offset: Offset(0, width * 0.06),
          ),
          // Inner shadow for subtle depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: width * 0.08,
            offset: Offset(0, width * 0.02),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Diamond pattern
          CustomPaint(
            size: Size(width, _height),
            painter: _CardBackPatternPainter(width: width),
          ),
          // Centered icon
          Center(
            child: Icon(
              Icons.style,
              color: colorScheme.onPrimary.withValues(alpha: 0.4),
              size: width * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a diamond pattern on the card back
class _CardBackPatternPainter extends CustomPainter {
  _CardBackPatternPainter({required this.width});

  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final spacing = width * 0.15;

    // Draw diagonal lines creating diamond pattern
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      // Top-left to bottom-right diagonals
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
      // Top-right to bottom-left diagonals
      canvas.drawLine(
        Offset(size.width - i, 0),
        Offset(size.width - i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
