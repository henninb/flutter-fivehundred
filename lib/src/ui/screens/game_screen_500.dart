import 'package:flutter/material.dart';
import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/game_models.dart';
import '../../game/logic/bidding_engine.dart';
import '../../models/theme_models.dart';
import '../../models/game_settings.dart';
import '../widgets/action_bar_500.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/score_display.dart';
import '../widgets/welcome_screen.dart';

/// Simplified game screen for 500
class GameScreen500 extends StatelessWidget {
  const GameScreen500({
    super.key,
    required this.engine,
    required this.currentTheme,
    required this.onThemeChange,
    required this.currentSettings,
    required this.onSettingsChange,
  });

  final GameEngine engine;
  final CribbageTheme currentTheme;
  final Function(CribbageTheme) onThemeChange;
  final GameSettings currentSettings;
  final Function(GameSettings) onSettingsChange;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('500'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // TODO: Show settings
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Score display - only show when game has started
              if (state.gameStarted) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ScoreDisplay(
                    scoreNS: state.teamNorthSouthScore,
                    scoreEW: state.teamEastWestScore,
                    tricksNS: state.tricksWonNS,
                    tricksEW: state.tricksWonEW,
                    trumpSuit: state.trumpSuit,
                  ),
                ),
                // Status message
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    state.gameStatus,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              // Game area - show welcome screen if game not started
              if (!state.gameStarted)
                const Expanded(
                  child: WelcomeScreen(),
                )
              // Show hand during bidding when it's player's turn
              else if (state.currentPhase == GamePhase.bidding &&
                  state.currentBidder == Position.north)
                // Show just the hand during bidding
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your Hand:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(
                          state.playerHand.length,
                          (index) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                state.playerHand[index].label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Full game area for other phases
                Expanded(
                  child: Center(
                    child: _buildGameArea(context, state),
                  ),
                ),
              // Show bidding panel when it's player's turn to bid
              if (state.currentPhase == GamePhase.bidding &&
                  state.currentBidder == Position.north)
                Expanded(
                  child: _buildBiddingPanel(state),
                )
              else
                // Action bar for other phases
                ActionBar500(
                  state: state,
                  onStartGame: () => engine.startNewGame(),
                  onCutForDeal: () => engine.cutForDeal(),
                  onDealCards: () => engine.dealCards(),
                  onConfirmKitty: () => engine.confirmKittyExchange(),
                  onNextHand: () => engine.startNextHand(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameArea(BuildContext context, GameState state) {
    // Show cut cards during cut for deal phase
    if (state.currentPhase == GamePhase.cutForDeal &&
        state.cutCards.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cut for Deal Results:',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Display each player's cut card
          ...Position.values.map((position) {
            final card = state.cutCards[position];
            if (card == null) return const SizedBox.shrink();

            final playerName = state.getName(position);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          playerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        card.label,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }

    // During play/scoring, if there's a current trick to show, always show it
    // (This handles the 10th trick when hand is empty)
    if (state.currentTrick != null &&
        state.currentTrick!.plays.isNotEmpty &&
        (state.isPlayPhase || state.currentPhase == GamePhase.scoring)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Current Trick:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: state.currentTrick!.plays
                .map((play) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${play.card.label}\n${play.player.name}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),)
                .toList(),
          ),
          const SizedBox(height: 24),
          // Show remaining hand if any cards left
          if (state.playerHand.isNotEmpty) ...[
            Text(
              'Your Hand:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(
                state.playerHand.length,
                (index) => _buildCard(
                  context,
                  state.playerHand[index],
                  index,
                  state,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // During scoring phase, show last completed trick
    if (state.currentPhase == GamePhase.scoring && state.completedTricks.isNotEmpty) {
      final lastTrick = state.completedTricks.last;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Last Trick:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: lastTrick.plays
                .map((play) => Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${play.card.label}\n${play.player.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),)
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Hand Complete',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    }

    // Regular play - show hand only (trick is shown in first check above)
    if (state.playerHand.isEmpty) {
      return const Text('Waiting for cards...');
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Your Hand:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(
            state.playerHand.length,
            (index) => _buildCard(
              context,
              state.playerHand[index],
              index,
              state,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    card,
    int index,
    GameState state,
  ) {
    final bool canPlay =
        state.isPlayPhase && state.currentPlayer == Position.north;
    final bool isKittyExchange =
        state.currentPhase == GamePhase.kittyExchange &&
        state.contractor == Position.north;
    final bool isSelected = state.selectedCardIndices.contains(index);

    // Determine card color
    Color? cardColor;
    if (isKittyExchange && isSelected) {
      cardColor = Theme.of(context).colorScheme.errorContainer; // Highlight selected cards for discard
    } else if (canPlay) {
      cardColor = Theme.of(context).colorScheme.primaryContainer; // Highlight playable cards
    }

    return InkWell(
      onTap: () {
        if (isKittyExchange) {
          // Kitty exchange: tap to toggle selection
          engine.toggleCardSelection(index);
        } else if (canPlay) {
          // Play phase: tap to play card
          engine.playCard(index);
        }
      },
      child: Card(
        color: cardColor,
        elevation: isSelected ? 8 : 1, // Raise selected cards
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            card.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiddingPanel(GameState state) {
    // Check if player can inkle
    final biddingEngine = BiddingEngine(dealer: state.dealer);
    final canInkle = biddingEngine.canInkle(Position.north, state.bidHistory);

    return BiddingPanel(
      currentHighBid: state.currentHighBid,
      canInkle: canInkle,
      playerHand: state.playerHand,
      onBidSelected: (bid, isInkle) {
        engine.submitPlayerBid(bid, isInkle: isInkle);
      },
      onPass: () {
        engine.submitPlayerBid(null);
      },
    );
  }
}
