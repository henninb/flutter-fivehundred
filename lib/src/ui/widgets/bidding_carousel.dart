import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';
import '../../game/logic/avondale_table.dart';
import '../../game/logic/bidding_ai.dart';

/// Modern carousel-based bidding interface
/// Swipe through trick levels, tap suit icons to bid
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
  late PageController _pageController;
  int _currentTrickLevel = 7; // Start at 7 (minimum normal bid)
  BidDecision? _aiRecommendation;
  Map<BidSuit, SuitEvaluation>? _handEvaluations;
  Bid? _selectedBid;
  bool _selectedIsInkle = false;
  BidSuit? _selectedSuit; // Track selected suit separately to persist across trick levels

  @override
  void initState() {
    super.initState();

    // Find first valid trick level to start on
    _currentTrickLevel = _findInitialTrickLevel();
    _pageController = PageController(initialPage: _currentTrickLevel - 6);

    // Get AI recommendation
    _aiRecommendation = BiddingAI.chooseBid(
      hand: widget.playerHand,
      currentBids: widget.bidHistory,
      position: widget.currentBidder ?? Position.south,
      canInkle: widget.canInkle,
    );

    // Get hand evaluations for strength indicator
    _handEvaluations = {
      BidSuit.spades: BiddingAI.evaluateSuit(widget.playerHand, Suit.spades),
      BidSuit.clubs: BiddingAI.evaluateSuit(widget.playerHand, Suit.clubs),
      BidSuit.diamonds:
          BiddingAI.evaluateSuit(widget.playerHand, Suit.diamonds),
      BidSuit.hearts: BiddingAI.evaluateSuit(widget.playerHand, Suit.hearts),
      BidSuit.noTrump: BiddingAI.evaluateNoTrump(widget.playerHand),
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Find first valid trick level to display
  int _findInitialTrickLevel() {
    // If we can inkle, start at 6
    if (widget.canInkle) return 6;

    // Otherwise start at minimum beating level
    if (widget.currentHighBid != null) {
      return widget.currentHighBid!.tricks;
    }

    // Default to 7
    return 7;
  }

  /// Get previous bids made before current player
  List<BidEntry> _getPreviousBids() {
    if (widget.currentBidder == null) return [];

    final biddingOrder = _getBiddingOrder();
    final currentBidderIndex = biddingOrder.indexOf(widget.currentBidder!);

    return widget.bidHistory.where((entry) {
      final entryIndex = biddingOrder.indexOf(entry.bidder);
      return entryIndex < currentBidderIndex;
    }).toList();
  }

  /// Get bidding order starting from dealer's left
  List<Position> _getBiddingOrder() {
    final order = <Position>[];
    var current = widget.dealer.next;
    for (int i = 0; i < 4; i++) {
      order.add(current);
      current = current.next;
    }
    return order;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Mini avatars with previous bids
          if (_getPreviousBids().isNotEmpty) _buildBidHistory(context),

          // Hand strength and AI recommendation
          _buildHandStrengthAndAI(context),

          const SizedBox(height: 4),

          // Carousel with trick levels
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentTrickLevel = index + 6;

                  // Preserve suit selection when changing trick level
                  if (_selectedSuit != null) {
                    final newBid = Bid(
                      tricks: _currentTrickLevel,
                      suit: _selectedSuit!,
                      bidder: Position.south,
                    );

                    // Only keep the selection if the new bid is valid
                    if (_isValidBid(_currentTrickLevel, _selectedSuit!)) {
                      _selectedBid = newBid;
                      _selectedIsInkle = _currentTrickLevel == 6 && widget.canInkle;
                    } else {
                      // Clear if new bid is invalid
                      _selectedBid = null;
                      _selectedIsInkle = false;
                      _selectedSuit = null;
                    }
                  }
                });
              },
              itemCount: 5, // Trick levels 6-10
              itemBuilder: (context, index) {
                final tricks = index + 6;
                return _buildTrickLevelPage(context, tricks);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Trick level selector label + buttons
          Column(
            children: [
              Text(
                'Choose Bid Level:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              _buildTrickLevelSelector(context),
            ],
          ),

          const SizedBox(height: 8),

          // Action buttons (Pass and Confirm)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // Pass button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: widget.onPass,
                      child: const Text(
                        'Pass',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Confirm bid button (shown when bid selected)
                if (_selectedBid != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: () {
                          widget.onBidSelected(_selectedBid!, _selectedIsInkle);
                        },
                        child: Text(
                          'Bid: ${_selectedBid!.tricks}${_suitSymbol(_selectedBid!.suit)} (${_selectedBid!.value})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidHistory(BuildContext context) {
    final previousBids = _getPreviousBids();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: previousBids.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildPlayerBidAvatar(context, entry),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerBidAvatar(BuildContext context, BidEntry entry) {
    final isPassed = entry.action == BidAction.pass;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPassed
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: isPassed
                  ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _getPositionInitial(entry.bidder),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPassed
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isPassed
              ? 'Pass'
              : '${entry.bid!.tricks}${_suitSymbol(entry.bid!.suit)}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: isPassed ? FontWeight.normal : FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHandStrengthAndAI(BuildContext context) {
    // Calculate overall hand strength (0-10 scale)
    final maxTricks = _handEvaluations?.values
            .map((e) => e.estimatedTricks)
            .reduce((a, b) => a > b ? a : b) ??
        0.0;

    final strength = (maxTricks / 10.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Hand strength indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hand Strength',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStrengthColor(context, strength),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // AI recommendation
          if (_aiRecommendation != null &&
              _aiRecommendation!.action != BidAction.pass)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI: ${_aiRecommendation!.bid!.tricks}${_suitSymbol(_aiRecommendation!.bid!.suit)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            )
          else if (_aiRecommendation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI: Pass',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStrengthColor(BuildContext context, double strength) {
    if (strength < 0.4) {
      return Theme.of(context).colorScheme.error;
    } else if (strength < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildTrickLevelPage(BuildContext context, int tricks) {
    return Column(
      children: [
        // Bid level number
        Text(
          'Bid $tricks',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),

        const SizedBox(height: 12),

        // Suit icons in a row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: BidSuit.values.map((suit) {
              return _buildSuitIcon(context, tricks, suit);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuitIcon(BuildContext context, int tricks, BidSuit suit) {
    final bid = Bid(tricks: tricks, suit: suit, bidder: Position.south);

    // Check if valid
    bool isValid = _isValidBid(tricks, suit);
    bool isInkle = tricks == 6 && widget.canInkle;

    // Check if this is the AI recommendation
    final isAIRec = _aiRecommendation?.bid != null &&
        _aiRecommendation!.bid!.tricks == tricks &&
        _aiRecommendation!.bid!.suit == suit;

    // Check if this bid is currently selected
    final isSelected = _selectedBid != null &&
        _selectedBid!.tricks == tricks &&
        _selectedBid!.suit == suit;

    // Determine background color based on state
    final Color backgroundColor;
    if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
    } else {
      // All non-selected suits get white background
      backgroundColor = Colors.white;
    }

    // Determine suit icon color based on state
    final Color suitColor;
    if (!isValid) {
      suitColor = Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(alpha: 0.3);
    } else if (isSelected) {
      suitColor = _getSuitColor(suit, context);
    } else {
      suitColor = _getSuitColor(suit, context).withValues(alpha: 0.7);
    }

    return GestureDetector(
      onTap: isValid
          ? () {
              HapticFeedback.mediumImpact();
              setState(() {
                _selectedBid = bid;
                _selectedIsInkle = isInkle;
                _selectedSuit = suit; // Remember the selected suit
              });
            }
          : null,
      onLongPress: isValid
          ? () {
              HapticFeedback.lightImpact();
              _showBidValueTooltip(context, tricks, suit);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: !isValid
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
                : isSelected
                    ? Theme.of(context).colorScheme.primary
                    : isAIRec
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
            width: isSelected ? 3 : (isAIRec ? 2 : 1.5),
          ),
          boxShadow: isValid && (isSelected || isAIRec)
              ? [
                  BoxShadow(
                    color: (isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary)
                        .withValues(alpha: 0.3),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            _suitSymbol(suit),
            style: TextStyle(
              fontSize: isSelected ? 28 : 26,
              color: suitColor,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidBid(int tricks, BidSuit suit) {
    final bid = Bid(tricks: tricks, suit: suit, bidder: Position.south);

    // Check inkle rules
    if (tricks == 6 && widget.canInkle) {
      return true;
    }
    if (tricks == 6 && !widget.canInkle) {
      return false;
    }

    // Check if beats current high bid
    if (widget.currentHighBid != null && !bid.beats(widget.currentHighBid!)) {
      return false;
    }

    return true;
  }

  void _showBidValueTooltip(BuildContext context, int tricks, BidSuit suit) {
    final value = AvondaleTable.getBidValue(tricks, suit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$tricks${_suitSymbol(suit)} is worth $value points',
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 250,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTrickLevelSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final tricks = index + 6;
          final isActive = tricks == _currentTrickLevel;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: isActive
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
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
        return Colors.black87;
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

  String _getPositionInitial(Position position) {
    switch (position) {
      case Position.north:
        return 'N';
      case Position.south:
        return 'S';
      case Position.east:
        return 'E';
      case Position.west:
        return 'W';
    }
  }
}
