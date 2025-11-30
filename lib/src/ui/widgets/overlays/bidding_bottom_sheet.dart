import 'package:flutter/material.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/models/game_models.dart';
import '../bidding_carousel.dart';
import '../hand_display.dart';

/// Bottom sheet wrapper for the bidding carousel.
///
/// Displays the bidding interface in a draggable bottom sheet when it's the
/// player's turn to bid. Includes a title bar and wraps the existing
/// BiddingCarousel widget for consistent UI patterns.
class BiddingBottomSheet extends StatelessWidget {
  const BiddingBottomSheet({
    super.key,
    required this.state,
    required this.onBidSelected,
    required this.onPass,
    required this.canInkle,
  });

  final GameState state;
  final Function(Bid bid, bool isInkle) onBidSelected;
  final VoidCallback onPass;
  final bool canInkle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Bid',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Bidding Help',
                onPressed: () => _showBiddingHelp(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current bid status
          if (state.currentHighBid != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.gavel,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current bid: ${state.currentHighBid}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Player's hand display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Hand:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              HandDisplay(
                hand: state.playerHand,
                onCardTap: (_) {}, // No interaction during bidding
                selectedIndices: const {},
                phase: state.currentPhase,
                enabled: false, // Cards not tappable during bidding
                allowPeek: true, // Allow peeking at overlapping cards
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bidding carousel
          Expanded(
            child: BiddingCarousel(
              currentHighBid: state.currentHighBid,
              canInkle: canInkle,
              onBidSelected: onBidSelected,
              onPass: onPass,
              playerHand: state.playerHand,
              bidHistory: state.bidHistory,
              currentBidder: state.currentBidder,
              dealer: state.dealer,
            ),
          ),
        ],
      ),
    );
  }

  void _showBiddingHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bidding Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to Bid:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Choose the number of tricks (6-10) your team will win\n'
                '• Select a trump suit (♠♣♦♥) or No Trump\n'
                '• Each bid must beat the previous bid\n'
                '• Higher tricks beat lower tricks\n'
                '• Same tricks: suit order is ♠ < ♣ < ♦ < ♥ < NT\n'
                '• The dealer can "inkle" to match the highest bid',
              ),
              const SizedBox(height: 12),
              Text(
                'Strategy Tips:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Use the hand strength indicators as a guide\n'
                '• Consider your partner may have strong cards\n'
                '• Don\'t overbid - penalties are harsh!\n'
                '• Pass if you have a weak hand',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
