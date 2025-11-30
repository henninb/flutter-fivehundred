import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';
import '../../game/logic/bidding_ai.dart';

/// Modern button-based bidding interface
/// Select suit and trick level with clear button grids
class BiddingCarousel extends StatefulWidget {
  const BiddingCarousel({
    super.key,
    required this.currentHighBid,
    required this.canInkle,
    required this.onBidSelected,
    required this.onPass,
    required this.playerHand,
    required this.bidHistory,
    required this.currentBidder,
    required this.dealer,
  });

  final Bid? currentHighBid;
  final bool canInkle;
  final Function(Bid bid, bool isInkle) onBidSelected;
  final VoidCallback onPass;
  final List<PlayingCard> playerHand;
  final List<BidEntry> bidHistory;
  final Position? currentBidder;
  final Position dealer;

  @override
  State<BiddingCarousel> createState() => _BiddingCarouselState();
}

class _BiddingCarouselState extends State<BiddingCarousel> {
  int? _selectedTrickLevel;
  BidSuit? _selectedSuit;
  BidDecision? _aiRecommendation;

  @override
  void initState() {
    super.initState();

    // Get AI recommendation
    _aiRecommendation = BiddingAI.chooseBid(
      hand: widget.playerHand,
      currentBids: widget.bidHistory,
      position: widget.currentBidder ?? Position.south,
      canInkle: widget.canInkle,
    );
  }

  Bid? get _currentBid {
    if (_selectedTrickLevel == null || _selectedSuit == null) return null;
    return Bid(
      tricks: _selectedTrickLevel!,
      suit: _selectedSuit!,
      bidder: Position.south,
    );
  }

  bool get _isInkle =>
      _selectedTrickLevel == 6 && widget.canInkle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current bid info
          if (widget.currentHighBid != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gavel,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Bid: ${widget.currentHighBid}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                'No bids yet - Start the bidding!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // AI Recommendation (if available)
          if (_aiRecommendation != null &&
              _aiRecommendation!.action != BidAction.pass)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 18,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI Suggests: ${_aiRecommendation!.bid!.tricks}${_suitSymbol(_aiRecommendation!.bid!.suit)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Suit selection buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Suit:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: BidSuit.values.map((suit) {
                    final isSelected = _selectedSuit == suit;
                    final isAIRec = _aiRecommendation?.bid?.suit == suit;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildSuitButton(
                          context,
                          suit,
                          isSelected,
                          isAIRec,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Trick level selection buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Tricks:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    final tricks = index + 6;
                    final isSelected = _selectedTrickLevel == tricks;
                    final isAIRec = _aiRecommendation?.bid?.tricks == tricks;
                    final canSelect = _canSelectTrickLevel(tricks);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildTrickButton(
                          context,
                          tricks,
                          isSelected,
                          isAIRec,
                          canSelect,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Pass button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: widget.onPass,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'Pass',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Confirm bid button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _currentBid != null && _isValidBid(_currentBid!)
                          ? () {
                              widget.onBidSelected(_currentBid!, _isInkle);
                            }
                          : null,
                      child: Text(
                        _currentBid != null
                            ? 'Bid $_selectedTrickLevel${_suitSymbol(_selectedSuit!)} (${_currentBid!.value} pts)'
                            : 'Select Suit & Tricks',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuitButton(
    BuildContext context,
    BidSuit suit,
    bool isSelected,
    bool isAIRec,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedSuit = suit;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 70,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : isAIRec
                      ? colorScheme.secondary
                      : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : (isAIRec ? 2 : 1),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              _suitSymbol(suit),
              style: TextStyle(
                fontSize: isSelected ? 36 : 32,
                color: _getSuitColor(suit, context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canSelectTrickLevel(int tricks) {
    // Check inkle rules
    if (tricks == 6 && widget.canInkle) {
      return true;
    }
    if (tricks == 6 && !widget.canInkle) {
      return false;
    }

    // If no current bid, all levels >= 6 are valid
    if (widget.currentHighBid == null) {
      return true;
    }

    // Must be higher trick level than current bid
    return tricks > widget.currentHighBid!.tricks;
  }

  Widget _buildTrickButton(
    BuildContext context,
    int tricks,
    bool isSelected,
    bool isAIRec,
    bool canSelect,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canSelect
            ? () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTrickLevel = tricks;
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 70,
          decoration: BoxDecoration(
            color: !canSelect
                ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.3)
                : isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !canSelect
                  ? colorScheme.outline.withValues(alpha: 0.1)
                  : isSelected
                      ? colorScheme.primary
                      : isAIRec
                          ? colorScheme.secondary
                          : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : (isAIRec ? 2 : 1),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              tricks.toString(),
              style: TextStyle(
                fontSize: isSelected ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: !canSelect
                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                    : isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidBid(Bid bid) {
    // Check inkle rules
    if (bid.tricks == 6 && widget.canInkle) {
      return true;
    }
    if (bid.tricks == 6 && !widget.canInkle) {
      return false;
    }

    // Check if beats current high bid
    if (widget.currentHighBid != null && !bid.beats(widget.currentHighBid!)) {
      return false;
    }

    return true;
  }

  Color _getSuitColor(BidSuit suit, BuildContext context) {
    switch (suit) {
      case BidSuit.spades:
        return Colors.black87;
      case BidSuit.clubs:
        return Colors.black87;
      case BidSuit.diamonds:
        return Colors.red.shade700;
      case BidSuit.hearts:
        return Colors.red.shade700;
      case BidSuit.noTrump:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _suitSymbol(BidSuit suit) {
    switch (suit) {
      case BidSuit.spades:
        return '♠';
      case BidSuit.clubs:
        return '♣';
      case BidSuit.diamonds:
        return '♦';
      case BidSuit.hearts:
        return '♥';
      case BidSuit.noTrump:
        return 'NT';
    }
  }
}
