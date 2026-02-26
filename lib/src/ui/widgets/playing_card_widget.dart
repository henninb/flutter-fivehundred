import 'package:flutter/material.dart';
import '../../game/models/card.dart';

/// A widget that displays a playing card with modern styling inspired by
/// traditional playing card design.
///
/// Features:
/// - Traditional corner indices (rank + suit in corners)
/// - Large centered suit symbol
/// - Dual-shadow depth system
/// - Proportional sizing (all elements scale with card width)
/// - State-based styling (selected, playable, played, winning)
class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    required this.card,
    required this.width,
    this.height,
    this.isSelected = false,
    this.isPlayable = true,
    this.isPlayed = false,
    this.isWinning = false,
    this.onTap,
    super.key,
  });

  final PlayingCard card;
  final double width;
  final double? height;
  final bool isSelected;
  final bool isPlayable;
  final bool isPlayed;
  final bool isWinning;
  final VoidCallback? onTap;

  /// Height calculated from width to maintain 5:7 aspect ratio
  double get _height => height ?? (width * 1.4);

  /// Get suit color (red for hearts/diamonds, black for spades/clubs)
  Color get _suitColor {
    if (card.isJoker) return const Color(0xFF212121);

    switch (card.suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return const Color(0xFFD32F2F); // Rich red
      case Suit.spades:
      case Suit.clubs:
        return const Color(0xFF212121); // Pure black
    }
  }

  /// Get suit symbol
  String get _suitSymbol {
    if (card.isJoker) return '🃏';

    switch (card.suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }

  /// Get rank string for display
  String get _rankString {
    if (card.isJoker) return 'JKR';

    switch (card.rank) {
      case Rank.ace:
        return 'A';
      case Rank.king:
        return 'K';
      case Rank.queen:
        return 'Q';
      case Rank.jack:
        return 'J';
      case Rank.ten:
        return '10';
      case Rank.nine:
        return '9';
      case Rank.eight:
        return '8';
      case Rank.seven:
        return '7';
      case Rank.six:
        return '6';
      case Rank.five:
        return '5';
      case Rank.four:
        return '4';
      case Rank.joker:
        return 'JKR';
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPlayed
        ? const Color(0xFFE0E0E0) // Light gray for played cards
        : isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : isWinning
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.white;

    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : isWinning
            ? Theme.of(context).colorScheme.primary
            : isPlayable
                ? const Color(0xFF757575) // Medium gray
                : const Color(0xFFBDBDBD); // Light gray

    final borderWidth = isSelected || isWinning ? 3.0 : 1.5;
    final opacity = isPlayed ? 0.5 : 1.0;

    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: _height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(width * 0.1),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: isPlayed
              ? []
              : [
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
        child: Opacity(
          opacity: opacity,
          child: Stack(
            children: [
              // Top-left corner index
              Positioned(
                top: width * 0.08,
                left: width * 0.12,
                child: _buildCornerIndex(),
              ),
              // Bottom-right corner index (rotated 180°)
              Positioned(
                bottom: width * 0.08,
                right: width * 0.12,
                child: Transform.rotate(
                  angle: 3.14159, // π radians = 180 degrees
                  child: _buildCornerIndex(),
                ),
              ),
              // Center suit symbol
              if (!card.isJoker)
                Center(
                  child: Text(
                    _suitSymbol,
                    style: TextStyle(
                      fontSize: width * 0.35,
                      color: _suitColor.withValues(alpha: 0.3),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              // Joker text in center
              if (card.isJoker)
                Center(
                  child: Text(
                    'JOKER',
                    style: TextStyle(
                      fontSize: width * 0.18,
                      color: _suitColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build corner index (rank + suit stacked vertically)
  Widget _buildCornerIndex() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank
        Text(
          _rankString,
          style: TextStyle(
            fontSize: width * 0.25,
            fontWeight: FontWeight.bold,
            color: _suitColor,
            height: 0.9,
          ),
        ),
        // Suit symbol (skip for joker)
        if (!card.isJoker)
          Text(
            _suitSymbol,
            style: TextStyle(
              fontSize: width * 0.22,
              color: _suitColor,
              height: 0.9,
            ),
          ),
      ],
    );
  }
}
