import 'package:flutter/material.dart';
import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/game_models.dart';
import 'action_bar.dart';
import 'hand_display.dart';
import 'score_display.dart';
import 'setup_screen.dart';
import 'status_bar.dart';
import 'trick_area.dart';

/// The persistent game board that remains visible across all game phases.
///
/// This widget composes all the persistent UI elements:
/// - StatusBar: Current game status message (always visible)
/// - ScoreDisplay: Team scores and tricks (hidden during setup/bidding)
/// - TrickArea: Cards currently being played (center, cross pattern)
/// - HandDisplay: Player's hand cards at bottom (always visible)
/// - ActionBar: Phase-specific action buttons (always visible)
///
/// The board uses conditional visibility to hide score/trick area when
/// not relevant, saving screen space and reducing clutter.
class PersistentGameBoard extends StatelessWidget {
  const PersistentGameBoard({
    super.key,
    required this.state,
    required this.engine,
    required this.onStartGame,
    required this.onCutForDeal,
    required this.onSelectCutCard,
    required this.onDealCards,
    required this.onConfirmKitty,
    required this.onNextHand,
    required this.onClaimTricks,
  });

  final GameState state;
  final GameEngine engine;
  final VoidCallback onStartGame;
  final VoidCallback onCutForDeal;
  final Function(int) onSelectCutCard;
  final VoidCallback onDealCards;
  final VoidCallback onConfirmKitty;
  final VoidCallback onNextHand;
  final VoidCallback onClaimTricks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status bar - always visible
        StatusBar(status: state.gameStatus),

        // Score display - visible during play and scoring phases
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _shouldShowScore()
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: ScoreDisplay(
                    scoreNS: state.teamNorthSouthScore,
                    scoreEW: state.teamEastWestScore,
                    tricksNS: state.tricksWonNS,
                    tricksEW: state.tricksWonEW,
                    trumpSuit: state.trumpSuit,
                    winningBid: state.winningBid,
                    dealer: state.dealer,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Trick area / Setup screen - expands to fill available space
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCenterContent(),
            ),
          ),
        ),

        // Player hand - always visible at bottom
        HandDisplay(
          hand: state.playerHand,
          onCardTap: (index) => engine.playCard(index),
          selectedIndices: state.selectedCardIndices,
          phase: state.currentPhase,
          enabled: state.currentPlayer == Position.south,
        ),

        // Action bar - always visible at bottom
        ActionBar(
          state: state,
          onStartGame: onStartGame,
          onCutForDeal: onCutForDeal,
          onDealCards: onDealCards,
          onConfirmKitty: onConfirmKitty,
          onNextHand: onNextHand,
          canClaimTricks: state.canPlayerClaimRemainingTricks,
          onClaimTricks: onClaimTricks,
        ),
      ],
    );
  }

  /// Determine if score should be shown based on game phase
  bool _shouldShowScore() {
    // Show score after game has started, but hide during setup and cut for deal
    return state.gameStarted &&
           state.currentPhase != GamePhase.setup &&
           state.currentPhase != GamePhase.cutForDeal;
  }

  /// Build the center content - either setup screen or trick area
  Widget _buildCenterContent() {
    // Show setup screen during setup and cut for deal phases
    if (state.currentPhase == GamePhase.setup ||
        state.currentPhase == GamePhase.cutForDeal) {
      return SetupScreen(
        key: ValueKey(state.currentPhase),
        state: state,
        onSelectCutCard: onSelectCutCard,
      );
    }

    // Show trick area during other phases
    return TrickArea(
      key: ValueKey(state.currentTrick?.plays.length ?? 0),
      trick: state.currentTrick,
      currentWinner: engine.getCurrentTrickWinner(),
    );
  }
}
