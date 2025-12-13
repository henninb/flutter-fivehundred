import 'package:flutter/material.dart';
import '../../game/models/card.dart';
import '../../game/engine/game_state.dart';

/// Displays the player's hand of cards with tap interaction support.
///
/// Cards can be tapped to play them (during play phase) or to select/deselect
/// them (during kitty exchange). When allowPeek is true, touching a card
/// temporarily lifts it to show the full card (useful during bidding when
/// cards overlap).
class HandDisplay extends StatefulWidget {
  const HandDisplay({
    super.key,
    required this.hand,
    required this.onCardTap,
    required this.selectedIndices,
    required this.phase,
    this.enabled = true,
    this.allowPeek = false,
  });

  final List<PlayingCard> hand;
  final Function(int index) onCardTap;
  final Set<int> selectedIndices;
  final GamePhase phase;
  final bool enabled;
  final bool allowPeek;

  @override
  State<HandDisplay> createState() => _HandDisplayState();
}

class _HandDisplayState extends State<HandDisplay> {
  int? _peekingCardIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.hand.isEmpty) {
      // Hide "No cards" message during setup and cut for deal phases
      if (widget.phase == GamePhase.setup ||
          widget.phase == GamePhase.cutForDeal) {
        return const SizedBox(height: 80);
      }

      return Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          'No cards',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Card dimensions
        const cardWidth = 60.0;
        const cardHeight = 84.0;

        // Calculate overlap needed to fit all cards
        final availableWidth = constraints.maxWidth - 16; // Account for padding
        final totalCardsWidth = cardWidth * widget.hand.length;

        double cardSpacing;
        if (totalCardsWidth <= availableWidth) {
          // Cards fit without overlap
          cardSpacing = cardWidth + 8;
        } else {
          // Calculate spacing to fit all cards with overlap
          // Formula: (numCards - 1) * spacing + cardWidth = availableWidth
          cardSpacing = (availableWidth - cardWidth) / (widget.hand.length - 1);
          // Ensure minimum overlap
          cardSpacing = cardSpacing.clamp(15.0, cardWidth + 8);
        }

        // Build card list with peeking card on top
        final cardWidgets = <Widget>[];
        for (int index = 0; index < widget.hand.length; index++) {
          // Skip peeking card in first pass
          if (index == _peekingCardIndex) continue;

          cardWidgets.add(
            Positioned(
              left: index * cardSpacing,
              top: 0,
              child: _buildCard(context, widget.hand[index], index),
            ),
          );
        }

        // Add peeking card last so it appears on top
        if (_peekingCardIndex != null &&
            _peekingCardIndex! < widget.hand.length) {
          cardWidgets.add(
            Positioned(
              left: _peekingCardIndex! * cardSpacing,
              top: 0,
              child: _buildCard(
                context,
                widget.hand[_peekingCardIndex!],
                _peekingCardIndex!,
              ),
            ),
          );
        }

        return SizedBox(
          height: 100,
          child: Center(
            child: SizedBox(
              width: (widget.hand.length - 1) * cardSpacing + cardWidth,
              height: cardHeight,
              child: Stack(children: cardWidgets),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, PlayingCard card, int index) {
    final bool isKittyExchange = widget.phase == GamePhase.kittyExchange;
    final bool isSelected = widget.selectedIndices.contains(index);
    final bool isPeeking = _peekingCardIndex == index;
    final bool isJoker = card.label == 'JOKER';

    // Determine card color
    Color cardColor;
    Color textColor;

    if (isKittyExchange && isSelected) {
      cardColor = Theme.of(context).colorScheme.errorContainer;
      textColor = Theme.of(context).colorScheme.onErrorContainer;
    } else {
      cardColor = Colors.white;
      textColor = _getCardColor(card.label);
    }

    // Calculate vertical offset - selected cards and peeking cards lift up
    double yOffset = 0;
    if (isSelected) {
      yOffset = -8;
    } else if (isPeeking) {
      yOffset = -20; // Lift higher when peeking
    }

    final cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: yOffset != 0 ? Matrix4.translationValues(0, yOffset, 0) : null,
      child: Card(
        color: cardColor,
        elevation: isPeeking ? 16 : (isSelected ? 12 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                )
              : (isPeeking
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : BorderSide.none),
        ),
        child: Container(
          width: 60,
          height: 84,
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              card.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isJoker || isSelected || isPeeking
                    ? FontWeight.bold
                    : FontWeight.normal,
                letterSpacing: isJoker ? 1.5 : 0,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    // If peek mode is enabled, use GestureDetector for press detection
    if (widget.allowPeek) {
      return GestureDetector(
        onTapDown: (_) {
          setState(() {
            _peekingCardIndex = index;
          });
        },
        onTapUp: (_) {
          setState(() {
            _peekingCardIndex = null;
          });
        },
        onTapCancel: () {
          setState(() {
            _peekingCardIndex = null;
          });
        },
        child: cardWidget,
      );
    }

    // Otherwise, use InkWell for normal tap behavior
    return InkWell(
      onTap: widget.enabled ? () => widget.onCardTap(index) : null,
      borderRadius: BorderRadius.circular(8),
      child: cardWidget,
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
