import 'package:flutter/material.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';
import '../../game/logic/avondale_table.dart';

/// Inline panel for player to make a bid (displayed on main screen)
class BiddingPanel extends StatefulWidget {
  const BiddingPanel({
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
  State<BiddingPanel> createState() => _BiddingPanelState();
}

class _BiddingPanelState extends State<BiddingPanel> {
  Bid? _selectedBid;
  bool _selectedIsInkle = false;

  /// Get the bidding order based on dealer
  List<Position> _getBiddingOrder() {
    final order = <Position>[];
    var current = widget.dealer.next;
    for (int i = 0; i < 4; i++) {
      order.add(current);
      current = current.next;
    }
    return order;
  }

  /// Get only the bids that were made before the current bidder
  List<BidEntry> _getPreviousBids() {
    if (widget.currentBidder == null) return [];

    final biddingOrder = _getBiddingOrder();
    final currentBidderIndex = biddingOrder.indexOf(widget.currentBidder!);

    // Get all bids made before this player's position in the bidding order
    return widget.bidHistory.where((entry) {
      final entryIndex = biddingOrder.indexOf(entry.bidder);
      return entryIndex < currentBidderIndex;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with current high bid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Bid',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.currentHighBid != null)
                  Text(
                    'High: ${widget.currentHighBid!.tricks}${_suitLabel(widget.currentHighBid!.suit)} (${widget.currentHighBid!.value})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Previous bids display
            if (_getPreviousBids().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _getPreviousBids().map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: entry.action == BidAction.pass
                                ? Theme.of(context).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: entry.action == BidAction.pass
                                  ? Theme.of(context).dividerColor
                                  : Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _formatBidEntry(entry),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: entry.action != BidAction.pass ? FontWeight.bold : FontWeight.normal,
                              color: entry.action == BidAction.pass
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Bid grid
            _buildBidGrid(context),
            const SizedBox(height: 8),
            // Buttons row
            Row(
              children: [
                // Pass button
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onPass,
                    child: const Text('Pass'),
                  ),
                ),
                if (_selectedBid != null) ...[
                  const SizedBox(width: 6),
                  // Confirm bid button
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        widget.onBidSelected(_selectedBid!, _selectedIsInkle);
                      },
                      child: Text(
                        'Bid: ${_selectedBid!.tricks}${_suitLabel(_selectedBid!.suit)} (${_selectedBid!.value})',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidGrid(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Theme.of(context).dividerColor),
      defaultColumnWidth: const FlexColumnWidth(),
      columnWidths: const {
        0: FlexColumnWidth(0.5), // First column (trick numbers) is half the width
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
          children: [
            _buildHeaderCell(''),
            _buildHeaderCell('♠'),
            _buildHeaderCell('♣'),
            _buildHeaderCell('♦'),
            _buildHeaderCell('♥'),
            _buildHeaderCell('NT'),
          ],
        ),
        // Bid rows (6-10)
        for (int tricks = 6; tricks <= 10; tricks++) _buildBidRow(context, tricks),
      ],
    );
  }

  TableRow _buildBidRow(BuildContext context, int tricks) {
    return TableRow(
      children: [
        _buildHeaderCell(tricks.toString()),
        for (final suit in BidSuit.values) _buildBidCell(context, tricks, suit),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildBidCell(BuildContext context, int tricks, BidSuit suit) {
    final bid = Bid(tricks: tricks, suit: suit, bidder: Position.south);
    final value = AvondaleTable.getBidValue(tricks, suit);

    // Check if this bid is valid (beats current high bid)
    bool isValid = true;
    bool isInkle = false;

    if (widget.currentHighBid != null && !bid.beats(widget.currentHighBid!)) {
      isValid = false;
    }

    // Check if this is an inkle
    if (tricks == 6 && widget.canInkle) {
      isInkle = true;
      isValid = true; // Inkle is always valid if allowed
    }

    // Can't win with inkle
    if (tricks == 6 && !widget.canInkle) {
      isValid = false;
    }

    // Check if this bid is currently selected
    final isSelected = _selectedBid != null &&
        _selectedBid!.tricks == tricks &&
        _selectedBid!.suit == suit;

    return InkWell(
      onTap: isValid
          ? () {
              setState(() {
                _selectedBid = bid;
                _selectedIsInkle = isInkle;
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: !isValid
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            value.toString(),
            style: TextStyle(
              color: !isValid
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatBidEntry(BidEntry entry) {
    final playerName = _getShortName(entry.bidder);
    if (entry.action == BidAction.pass) {
      return '$playerName: Pass';
    } else if (entry.action == BidAction.inkle && entry.bid != null) {
      return '$playerName: ${entry.bid!.tricks}${_suitLabel(entry.bid!.suit)} (Inkle)';
    } else if (entry.bid != null) {
      return '$playerName: ${entry.bid!.tricks}${_suitLabel(entry.bid!.suit)}';
    }
    return '$playerName: ?';
  }

  String _getShortName(Position position) {
    switch (position) {
      case Position.south:
        return 'You';
      case Position.north:
        return 'Partner';
      case Position.east:
        return 'East';
      case Position.west:
        return 'West';
    }
  }

  String _suitLabel(BidSuit suit) {
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
