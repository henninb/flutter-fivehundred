import 'package:flutter/material.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/models/game_models.dart';

/// Bottom sheet overlay displaying cut for deal results.
///
/// Shows cards arranged in a cross pattern (N/S/E/W) representing each player's
/// cut card. The dealer's card is highlighted with enhanced styling and effects.
/// This overlay is shown after the cut for deal is complete and auto-dismisses
/// after 3 seconds.
class SetupOverlay extends StatelessWidget {
  const SetupOverlay({
    super.key,
    required this.state,
  });

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final dealer = state.dealer;
    final dealerName = state.getName(dealer);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Modern title with gradient accent
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withAlpha(51),
                    Theme.of(context).colorScheme.secondary.withAlpha(51),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Cutting for Deal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  if (dealerName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$dealerName wins the deal!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Cut cards in cross pattern
            _buildCutCardsCross(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Build cards in a cross pattern (N at top, S at bottom, E at right, W at left)
  Widget _buildCutCardsCross(BuildContext context) {
    const cardSize = 100.0;
    const spacing = 20.0;

    return SizedBox(
      width: cardSize * 3 + spacing * 2,
      height: cardSize * 3 + spacing * 2,
      child: Stack(
        children: [
          // Center decoration (table center)
          Positioned(
            left: cardSize + spacing,
            top: cardSize + spacing,
            child: Container(
              width: cardSize,
              height: cardSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withAlpha(26),
                    Theme.of(context).colorScheme.secondary.withAlpha(26),
                  ],
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(77),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.cut,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary.withAlpha(128),
                ),
              ),
            ),
          ),

          // North (top)
          Positioned(
            left: cardSize + spacing,
            top: 0,
            child: _buildCrossCard(context, Position.north),
          ),

          // South (bottom)
          Positioned(
            left: cardSize + spacing,
            bottom: 0,
            child: _buildCrossCard(context, Position.south),
          ),

          // East (right)
          Positioned(
            right: 0,
            top: cardSize + spacing,
            child: _buildCrossCard(context, Position.east),
          ),

          // West (left)
          Positioned(
            left: 0,
            top: cardSize + spacing,
            child: _buildCrossCard(context, Position.west),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossCard(BuildContext context, Position position) {
    final card = state.cutCards[position];
    final playerName = state.getName(position);
    final isDealer = state.dealer == position;

    if (card == null) {
      return const SizedBox(width: 100, height: 100);
    }

    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player name with position indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDealer
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDealer
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withAlpha(128),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              playerName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isDealer ? FontWeight.bold : FontWeight.w600,
                    color: isDealer
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),

          // Card with modern design
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDealer
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withAlpha(77),
                  width: isDealer ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDealer
                        ? Theme.of(context).colorScheme.primary.withAlpha(77)
                        : Colors.black.withAlpha(26),
                    blurRadius: isDealer ? 12 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  card.label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getCardColor(card.label),
                  ),
                ),
              ),
            ),
          ),

          // Dealer badge
          if (isDealer) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DEALER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCardColor(String label) {
    // Red for hearts and diamonds, black for clubs and spades
    if (label.contains('♥') || label.contains('♦')) {
      return Colors.red.shade800;
    }
    return Colors.black;
  }
}
