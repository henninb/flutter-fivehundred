import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/game_models.dart';

/// Setup screen shown during initial setup and cut for deal phases
class SetupScreen extends StatelessWidget {
  final GameState state;

  const SetupScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Show cut for deal results if cards have been cut
    if (state.currentPhase == GamePhase.cutForDeal &&
        state.cutCards.isNotEmpty) {
      return _CutForDealDisplay(state: state);
    }

    // Show ready to start message
    return _ReadyToStartDisplay(state: state);
  }
}

/// Display shown when ready to cut for deal or start the game
class _ReadyToStartDisplay extends StatelessWidget {
  final GameState state;

  const _ReadyToStartDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.casino_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Play!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              state.gameStatus.contains('Cut for Deal')
                  ? 'Tap "Cut for Deal" to determine the first dealer'
                  : 'Tap "Deal" to begin the first hand',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Display the cut for deal results
class _CutForDealDisplay extends StatelessWidget {
  final GameState state;

  const _CutForDealDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cut for Deal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lowest card deals first',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            // Display each player's cut card in a grid
            _buildCutCardsGrid(context),
            const SizedBox(height: 24),
            // Show result message
            if (state.gameStatus.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.gameStatus,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
      Position.north,
      Position.east,
      Position.south,
      Position.west
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: positions
          .map((position) {
            final card = state.cutCards[position];
            final playerName = state.getName(position);

            return _CutCardItem(
              playerName: playerName,
              card: card,
              isDealer: state.dealer == position,
            );
          })
          .toList(),
    );
  }
}

/// Individual cut card display for a player
class _CutCardItem extends StatelessWidget {
  final String playerName;
  final dynamic card;
  final bool isDealer;

  const _CutCardItem({
    required this.playerName,
    required this.card,
    required this.isDealer,
  });

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: isDealer ? 8 : 2,
      color: isDealer
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.surface,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playerName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isDealer ? FontWeight.bold : FontWeight.normal,
                    color: isDealer
                        ? Theme.of(context).colorScheme.onSecondaryContainer
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                card.label,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _getCardColor(card.label),
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
