import 'package:flutter/material.dart';
import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/logic/bidding_engine.dart';
import '../../game/models/game_models.dart';
import '../../models/game_settings.dart';
import '../../models/theme_models.dart';
import '../widgets/overlays/bidding_bottom_sheet.dart';
import '../widgets/overlays/game_over_modal.dart';
import '../widgets/overlays/kitty_exchange_bottom_sheet.dart';
import '../widgets/overlays/setup_overlay.dart';
import '../widgets/overlays/welcome_overlay.dart';
import '../widgets/persistent_game_board.dart';
import '../widgets/suit_nomination_dialog.dart';
import 'settings_screen.dart';

/// Main game screen for Five Hundred using single-page overlay design.
///
/// The screen uses a Stack layout with:
/// - PersistentGameBoard as the base layer (always visible)
/// - Overlays that appear based on game phase (welcome, bidding, etc.)
/// - Bottom sheets for contextual interactions (bidding, kitty exchange)
///
/// This design ensures the core game board (score, trick, hand, actions) is
/// always visible while phase-specific UI appears as overlays.
class GameScreen extends StatefulWidget {
  const GameScreen({
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
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Track which overlays have been shown to prevent duplicates
  bool _setupOverlayShown = false;
  bool _biddingOverlayShown = false;
  bool _kittyOverlayShown = false;
  bool _suitNominationDialogShown = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;

        // Reset overlay flags on phase changes
        _resetOverlayFlags(state);

        // Show suit nomination dialog when needed
        if (state.showSuitNominationDialog && !_suitNominationDialogShown) {
          _suitNominationDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Check if widget is still mounted before showing dialog
            if (!mounted) return;
            _showSuitNominationDialog(context);
          });
        }

        // Show bottom sheets based on game phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check if widget is still mounted before handling overlays
          if (!mounted) return;
          _handleOverlays(context, state);
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Five Hundred'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Persistent game board (always visible)
              PersistentGameBoard(
                state: state,
                engine: widget.engine,
                onStartGame: () => widget.engine.startNewGame(),
                onCutForDeal: () => widget.engine.cutForDeal(),
                onDealCards: () => widget.engine.dealCards(),
                onConfirmKitty: () => widget.engine.confirmKittyExchange(),
                onNextHand: () => widget.engine.startNextHand(),
                onClaimTricks: () => widget.engine.claimRemainingTricks(),
              ),

              // Welcome overlay (when game not started)
              if (!state.gameStarted)
                WelcomeOverlay(
                  onStartGame: () => widget.engine.startNewGame(),
                ),

              // Game over modal
              if (state.showGameOverDialog && state.gameOverData != null)
                GameOverModal(
                  data: state.gameOverData!,
                  onDismiss: () => widget.engine.dismissGameOverDialog(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Reset overlay shown flags when phase changes
  void _resetOverlayFlags(GameState state) {
    if (state.currentPhase != GamePhase.cutForDeal) {
      _setupOverlayShown = false;
    }
    if (state.currentPhase != GamePhase.bidding ||
        state.currentBidder != Position.south) {
      _biddingOverlayShown = false;
    }
    if (state.currentPhase != GamePhase.kittyExchange ||
        state.contractor != Position.south) {
      _kittyOverlayShown = false;
    }
    if (!state.showSuitNominationDialog) {
      _suitNominationDialogShown = false;
    }
  }

  /// Handle showing bottom sheet overlays based on game state
  void _handleOverlays(BuildContext context, GameState state) {
    // Additional safety check - should not be needed but prevents edge cases
    if (!mounted) return;

    // Show setup overlay after cut for deal
    if (state.currentPhase == GamePhase.cutForDeal &&
        state.cutCards.isNotEmpty &&
        !_setupOverlayShown) {
      _setupOverlayShown = true;
      _showSetupOverlay(context, state);
    }

    // Show bidding sheet when player's turn
    if (state.currentPhase == GamePhase.bidding &&
        state.currentBidder == Position.south &&
        !_biddingOverlayShown) {
      _biddingOverlayShown = true;
      _showBiddingSheet(context, state);
    }

    // Show kitty exchange when contractor
    if (state.currentPhase == GamePhase.kittyExchange &&
        state.contractor == Position.south &&
        !_kittyOverlayShown) {
      _kittyOverlayShown = true;
      _showKittyExchange(context, state);
    }
  }

  /// Show setup overlay (cut for deal results)
  void _showSetupOverlay(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => SetupOverlay(state: state),
    );
  }

  /// Show bidding bottom sheet
  void _showBiddingSheet(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Must bid or pass
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AnimatedBuilder(
          animation: widget.engine,
          builder: (context, _) {
            final currentState = widget.engine.state;
            final biddingEngine = BiddingEngine(dealer: currentState.dealer);
            final canInkle = biddingEngine.canInkle(Position.south, currentState.bidHistory);

            return BiddingBottomSheet(
              key: ValueKey(currentState.playerHand.length + currentState.playerHand.hashCode),
              state: currentState,
              canInkle: canInkle,
              onBidSelected: (bid, isInkle) {
                widget.engine.submitPlayerBid(bid, isInkle: isInkle);
                Navigator.pop(context);
              },
              onPass: () {
                widget.engine.submitPlayerBid(null);
                Navigator.pop(context);
              },
              onTestHandSelected: (testHand) {
                widget.engine.applyTestHand(testHand);
                // Don't close the bidding sheet - let user bid with new hand
              },
            );
          },
        ),
      ),
    );
  }

  /// Show kitty exchange bottom sheet
  void _showKittyExchange(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Must complete exchange
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => KittyExchangeBottomSheet(
          hand: state.playerHand,
          kitty: state.kitty,
          onConfirm: (selectedIndices) {
            // Clear existing selections
            for (var i in state.selectedCardIndices) {
              widget.engine.toggleCardSelection(i);
            }
            // Apply new selections
            for (var i in selectedIndices) {
              widget.engine.toggleCardSelection(i);
            }
            // Confirm the exchange
            widget.engine.confirmKittyExchange();
          },
        ),
      ),
    );
  }

  /// Show suit nomination dialog for joker in no-trump
  void _showSuitNominationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuitNominationDialog(
        onSuitSelected: (suit) {
          widget.engine.confirmCardPlayWithNominatedSuit(suit);
          // Note: Dialog pops itself in the button handler
        },
      ),
    );
  }

  /// Show settings overlay
  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: SettingsScreen(
          currentSettings: widget.currentSettings,
          onSettingsChange: widget.onSettingsChange,
          onBackPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
