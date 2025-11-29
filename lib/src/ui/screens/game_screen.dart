import 'package:flutter/material.dart';
import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/game_models.dart';
import '../../game/logic/bidding_engine.dart';
import '../../models/theme_models.dart';
import '../../models/game_settings.dart';
import '../widgets/action_bar.dart';
import '../widgets/bidding_panel.dart';
import '../widgets/score_display.dart';
import '../widgets/welcome_screen.dart';
import '../widgets/setup_screen.dart';
import '../widgets/suit_nomination_dialog.dart';
import 'settings_screen.dart';

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
  final FiveHundredTheme currentTheme;
  final Function(FiveHundredTheme) onThemeChange;
  final GameSettings currentSettings;
  final Function(GameSettings) onSettingsChange;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;

        // Show suit nomination dialog when needed
        if (state.showSuitNominationDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSuitNominationDialog(context);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Five Hundred'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        currentSettings: currentSettings,
                        onSettingsChange: onSettingsChange,
                        onBackPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
              // Score display - only show when past setup/cut phases
              if (state.gameStarted &&
                  state.currentPhase != GamePhase.setup &&
                  state.currentPhase != GamePhase.cutForDeal) ...[
                Padding(
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
              // Show setup screen during setup/cut for deal phases
              else if (state.currentPhase == GamePhase.setup ||
                  state.currentPhase == GamePhase.cutForDeal)
                Expanded(
                  child: SetupScreen(state: state),
                )
              // Show hand during bidding when it's player's turn
              else if (state.currentPhase == GamePhase.bidding &&
                  state.currentBidder == Position.south)
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
                          (index) {
                            final card = state.playerHand[index];
                            return Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  card.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getCardColor(card.label),
                                  ),
                                ),
                              ),
                            );
                          },
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
                  state.currentBidder == Position.south) ...[
                const Spacer(),
                _buildBiddingPanel(state),
              ] else
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
            // Game over modal overlay
            if (state.showGameOverDialog && state.gameOverData != null)
              _GameOverModal(
                data: state.gameOverData!,
                onDismiss: () => engine.dismissGameOverDialog(),
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
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${play.card.label}\n${play.player.name}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                          ),
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
                      color: Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${play.card.label}\n${play.player.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
        state.isPlayPhase && state.currentPlayer == Position.south;
    final bool isKittyExchange =
        state.currentPhase == GamePhase.kittyExchange &&
        state.contractor == Position.south;
    final bool isSelected = state.selectedCardIndices.contains(index);
    final bool isJoker = card.label == 'JOKER';

    // Determine card color
    Color cardColor;
    Color textColor;

    if (isKittyExchange && isSelected) {
      cardColor = Theme.of(context).colorScheme.errorContainer; // Highlight selected cards for discard
      textColor = Theme.of(context).colorScheme.onErrorContainer;
    } else {
      // Default: white background for all cards
      cardColor = Colors.white;
      // Use suit-appropriate colors (red for hearts/diamonds, black for spades/clubs)
      textColor = _getCardColor(card.label);
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
        elevation: isSelected ? 8 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            card.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isJoker || isSelected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: isJoker ? 1.5 : 0,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiddingPanel(GameState state) {
    // Check if player can inkle
    final biddingEngine = BiddingEngine(dealer: state.dealer);
    final canInkle = biddingEngine.canInkle(Position.south, state.bidHistory);

    return BiddingPanel(
      currentHighBid: state.currentHighBid,
      canInkle: canInkle,
      playerHand: state.playerHand,
      bidHistory: state.bidHistory,
      currentBidder: state.currentBidder,
      dealer: state.dealer,
      onBidSelected: (bid, isInkle) {
        engine.submitPlayerBid(bid, isInkle: isInkle);
      },
      onPass: () {
        engine.submitPlayerBid(null);
      },
    );
  }

  void _showSuitNominationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuitNominationDialog(
        onSuitSelected: (suit) {
          engine.confirmCardPlayWithNominatedSuit(suit);
        },
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

/// Game over modal with polished design
class _GameOverModal extends StatelessWidget {
  final GameOverData data;
  final VoidCallback onDismiss;

  const _GameOverModal({
    required this.data,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final playerWon = data.winningTeam == Team.northSouth;
    final winnerName = playerWon ? 'North-South' : 'East-West';

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: GestureDetector(
                onTap: onDismiss,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          playerWon
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                          playerWon
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trophy/Crown Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              playerWon
                                  ? Icons.emoji_events
                                  : Icons.close,
                              size: 40,
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Winner Name
                          Text(
                            '$winnerName Won!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: playerWon
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Final Score
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Final Score',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data.finalScoreNS} - ${data.finalScoreEW}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Statistics Grid
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Statistics',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _StatRow(
                                  label: 'Record',
                                  value:
                                      '${data.gamesWon} - ${data.gamesLost}',
                                  icon: Icons.sports_score,
                                  isPlayerWin: playerWon,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tap anywhere instruction
                          Text(
                            'Tap anywhere to continue',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: playerWon
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.8)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer
                                          .withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat row widget for statistics display
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPlayerWin;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isPlayerWin,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isPlayerWin
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;

    return Row(
      children: [
        Icon(
          icon,
          color: textColor.withValues(alpha: 0.7),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
