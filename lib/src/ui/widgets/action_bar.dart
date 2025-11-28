import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/game_models.dart';

/// Simplified action bar for 500
class ActionBar500 extends StatelessWidget {
  const ActionBar500({
    super.key,
    required this.state,
    required this.onStartGame,
    required this.onCutForDeal,
    required this.onDealCards,
    required this.onConfirmKitty,
    required this.onNextHand,
  });

  final GameState state;
  final VoidCallback onStartGame;
  final VoidCallback onCutForDeal;
  final VoidCallback onDealCards;
  final VoidCallback onConfirmKitty;
  final VoidCallback onNextHand;

  @override
  Widget build(BuildContext context) {
    final buttons = _buildButtons(context);

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: buttons,
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final buttons = <Widget>[];

    // Setup phase - Start New Game
    if (!state.gameStarted) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onStartGame,
            child: const Text('Start New Game'),
          ),
        ),
      );
      return buttons;
    }

    // Setup phase - Cut for Deal or Deal
    if (state.currentPhase == GamePhase.setup) {
      // Show "Cut for Deal" button if status mentions cutting
      if (state.gameStatus.contains('Cut for Deal')) {
        buttons.add(
          Expanded(
            child: FilledButton(
              onPressed: onCutForDeal,
              child: const Text('Cut for Deal'),
            ),
          ),
        );
      } else {
        // Otherwise show Deal button
        buttons.add(
          Expanded(
            child: FilledButton(
              onPressed: onDealCards,
              child: const Text('Deal'),
            ),
          ),
        );
      }
      return buttons;
    }

    // Cut for deal phase - show Deal button once winner is determined
    if (state.currentPhase == GamePhase.cutForDeal) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onDealCards,
            child: const Text('Deal'),
          ),
        ),
      );
      return buttons;
    }

    // Kitty exchange phase (player is contractor)
    if (state.currentPhase == GamePhase.kittyExchange &&
        state.contractor == Position.south) {
      final selectedCount = state.selectedCardIndices.length;
      final canDiscard = selectedCount == 5;

      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: canDiscard ? onConfirmKitty : null,
            child: Text(
              canDiscard
                  ? 'Discard 5 Cards'
                  : 'Select ${5 - selectedCount} more',
            ),
          ),
        ),
      );
      return buttons;
    }

    // Scoring phase - show Next Hand button
    if (state.currentPhase == GamePhase.scoring) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onNextHand,
            child: const Text('Next Hand'),
          ),
        ),
      );
      return buttons;
    }

    // Game over - allow starting a new game
    if (state.currentPhase == GamePhase.gameOver) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onStartGame,
            child: const Text('New Game'),
          ),
        ),
      );
      return buttons;
    }

    return buttons;
  }
}
