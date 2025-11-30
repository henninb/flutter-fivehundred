import 'package:flutter/material.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/models/game_models.dart';
import '../../../game/models/card.dart';

/// Bottom sheet overlay displaying cut for deal results.
///
/// Shows a 2x2 grid of cards cut by each player with the dealer highlighted.
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
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 12),

            // Title
            Text(
              'Cut for Deal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Highest card deals first',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Cut cards grid
            _buildCutCardsGrid(context),

            const SizedBox(height: 16),

            // Result message
            if (state.gameStatus.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.gameStatus,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCutCardsGrid(BuildContext context) {
    // Build a 2x2 grid for the four players
    final positions = [
      Position.north, // Partner (top)
      Position.west, // Opponent right
      Position.east, // Opponent left
      Position.south, // Human player (bottom)
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: positions.map((position) {
        final card = state.cutCards[position];
        final playerName = state.getName(position);

        return CutCardItem(
          playerName: playerName,
          card: card,
          isDealer: state.dealer == position,
        );
      }).toList(),
    );
  }
}

/// Individual cut card display for a player (reusable component).
class CutCardItem extends StatelessWidget {
  const CutCardItem({
    super.key,
    required this.playerName,
    required this.card,
    required this.isDealer,
  });

  final String playerName;
  final PlayingCard? card;
  final bool isDealer;

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: isDealer ? 8 : 2,
      color: isDealer
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playerName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isDealer ? FontWeight.bold : FontWeight.normal,
                    color: isDealer
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isDealer) ...[
              const SizedBox(height: 4),
              Text(
                'Dealer',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDealer
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: isDealer ? 2 : 1,
                ),
              ),
              child: Text(
                card!.label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getCardColor(card!.label),
                ),
              ),
            ),
          ],
        ),
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
