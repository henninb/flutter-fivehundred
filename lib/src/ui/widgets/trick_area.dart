import 'package:flutter/material.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';
import 'playing_card_widget.dart';

/// Displays the current trick with cards arranged in a cross pattern (N/S/E/W).
///
/// When no trick is in progress, shows a placeholder icon. When a trick is
/// active, displays the cards played by each player in their respective positions.
class TrickArea extends StatelessWidget {
  const TrickArea({
    super.key,
    this.trick,
    this.currentWinner,
  });

  final Trick? trick;
  final Position? currentWinner;

  @override
  Widget build(BuildContext context) {
    // Show placeholder when no trick in progress
    if (trick == null || trick!.isEmpty) {
      return Center(
        child: Icon(
          Icons.blur_circular,
          size: 48,
          color: Theme.of(context).colorScheme.outline.withAlpha(77),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card size based on available space
        final maxDimension = constraints.maxWidth.clamp(200.0, 400.0);
        final cardWidth = maxDimension * 0.2;
        final cardHeight = cardWidth * 1.4;
        final spacing = maxDimension * 0.15;

        return SizedBox(
          width: maxDimension,
          height: maxDimension,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Center indicator (led suit)
              if (trick!.ledSuit != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.outline.withAlpha(77),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _suitLabel(trick!.ledSuit!),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),

              // Position cards in cross pattern
              ...trick!.plays.map((play) {
                final isWinning = currentWinner == play.player;
                return _buildPositionedCard(
                  context,
                  play,
                  cardWidth,
                  cardHeight,
                  spacing,
                  isWinning,
                  maxDimension,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPositionedCard(
    BuildContext context,
    CardPlay play,
    double cardWidth,
    double cardHeight,
    double spacing,
    bool isWinning,
    double maxDimension,
  ) {
    // Determine position offset based on player position
    double? top, bottom, left, right;

    switch (play.player) {
      case Position.north:
        top = spacing;
        left = (maxDimension - cardWidth) / 2;
        break;
      case Position.south:
        bottom = spacing;
        left = (maxDimension - cardWidth) / 2;
        break;
      case Position.east:
        right = spacing;
        top = (maxDimension - cardHeight) / 2;
        break;
      case Position.west:
        left = spacing;
        top = (maxDimension - cardHeight) / 2;
        break;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Playing card
          PlayingCardWidget(
            card: play.card,
            width: cardWidth,
            height: cardHeight,
            isWinning: isWinning,
            isPlayable: false, // Cards in trick area are not playable
          ),
          // Player position label
          const SizedBox(height: 4),
          Text(
            play.player.name[0].toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  fontSize: cardWidth * 0.12,
                  fontWeight: isWinning ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  String _suitLabel(Suit suit) {
    switch (suit) {
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
}
