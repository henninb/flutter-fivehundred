import 'package:flutter/material.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';
import '../../game/logic/avondale_table.dart';

/// Dialog for player to make a bid
class BiddingDialog extends StatefulWidget {
  const BiddingDialog({
    super.key,
    required this.currentHighBid,
    required this.canInkle,
    required this.onBidSelected,
    required this.onPass,
    required this.playerHand,
  });

  final Bid? currentHighBid;
  final bool canInkle;
  final Function(Bid bid, bool isInkle) onBidSelected;
  final VoidCallback onPass;
  final List<PlayingCard> playerHand;

  @override
  State<BiddingDialog> createState() => _BiddingDialogState();
}

class _BiddingDialogState extends State<BiddingDialog> {
  Bid? _selectedBid;
  bool _selectedIsInkle = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Bid',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (widget.currentHighBid != null)
              Text(
                'Current high bid: ${widget.currentHighBid!.tricks}${_suitLabel(widget.currentHighBid!.suit)} (${widget.currentHighBid!.value} pts)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            // Player's hand display
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                border:
                    Border.all(color: Theme.of(context).colorScheme.secondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Hand:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.playerHand.map((card) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          card.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getCardColor(card.label),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bid grid
                    _buildBidGrid(context),
                    const SizedBox(height: 16),
                    // Confirm bid button (only shown when a bid is selected)
                    if (_selectedBid != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            widget.onBidSelected(
                              _selectedBid!,
                              _selectedIsInkle,
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Confirm Bid: ${_selectedBid!.tricks}${_suitLabel(_selectedBid!.suit)} (${_selectedBid!.value} pts)',
                          ),
                        ),
                      ),
                    if (_selectedBid != null) const SizedBox(height: 8),
                    // Pass button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onPass,
                        child: const Text('Pass'),
                      ),
                    ),
                  ],
                ),
              ),
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
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
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
        for (int tricks = 6; tricks <= 10; tricks++)
          _buildBidRow(context, tricks),
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
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: !isValid
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
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

  Color _getCardColor(String label) {
    // Red for hearts and diamonds, black for clubs and spades
    if (label.contains('♥') || label.contains('♦')) {
      return Colors.red.shade800;
    }
    return Colors.black;
  }
}
