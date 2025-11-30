import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';

/// Setup screen shown during initial setup and cut for deal phases
class SetupScreen extends StatelessWidget {
  final GameState state;
  final Function(int)? onSelectCutCard;

  const SetupScreen({
    super.key,
    required this.state,
    this.onSelectCutCard,
  });

  @override
  Widget build(BuildContext context) {
    // Show spread deck if in cut for deal phase and deck is available
    if (state.currentPhase == GamePhase.cutForDeal &&
        state.cutDeck.isNotEmpty &&
        !state.playerHasSelectedCutCard) {
      return _SpreadDeckDisplay(
        state: state,
        onSelectCard: onSelectCutCard,
      );
    }

    // Show ready to start message (including after cut is complete)
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
              Icons.style,
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

/// Display spread deck for player to tap and cut
class _SpreadDeckDisplay extends StatelessWidget {
  final GameState state;
  final Function(int)? onSelectCard;

  const _SpreadDeckDisplay({
    required this.state,
    this.onSelectCard,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              state.gameStatus,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSpreadDeck(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSpreadDeck(BuildContext context) {
    final deckSize = state.cutDeck.length;
    if (deckSize == 0) {
      return const SizedBox.shrink();
    }

    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Card dimensions
    const cardWidth = 60.0;
    const cardHeight = 90.0;

    // Calculate spacing to fit all cards on screen with overlap
    final availableWidth = screenWidth - 32; // 16px padding on each side
    final spacing = (availableWidth - cardWidth) / (deckSize - 1);
    final finalSpacing = spacing.clamp(0.0, cardWidth * 0.8); // Max 80% overlap
    final totalWidth = ((deckSize - 1) * finalSpacing + cardWidth);

    return SizedBox(
      height: cardHeight,
      width: totalWidth,
      child: Stack(
        children: List.generate(deckSize, (index) {
          return Positioned(
            left: index * finalSpacing,
            child: GestureDetector(
              onTap: onSelectCard != null ? () => onSelectCard!(index) : null,
              child: _CardBackWidget(
                width: cardWidth,
                height: cardHeight,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Widget displaying card back
class _CardBackWidget extends StatelessWidget {
  final double width;
  final double height;

  const _CardBackWidget({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Theme.of(context).colorScheme.tertiary,
          size: 24,
        ),
      ),
    );
  }
}
