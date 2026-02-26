import 'package:flutter/material.dart';
import '../../../game/models/card.dart';
import '../playing_card_widget.dart';

/// Bottom sheet for kitty exchange with card selection UI.
///
/// Displays all 15 cards (10 from hand + 5 from kitty) in a grid layout.
/// Users tap to select/deselect cards to discard. Cards from the kitty are
/// highlighted with a gold border. The confirm button is enabled only when
/// exactly 5 cards are selected.
class KittyExchangeBottomSheet extends StatefulWidget {
  const KittyExchangeBottomSheet({
    super.key,
    required this.hand,
    required this.kitty,
    required this.onConfirm,
  });

  final List<PlayingCard> hand;
  final List<PlayingCard> kitty;
  final Function(Set<int> selectedIndices) onConfirm;

  @override
  State<KittyExchangeBottomSheet> createState() =>
      _KittyExchangeBottomSheetState();
}

class _KittyExchangeBottomSheetState extends State<KittyExchangeBottomSheet> {
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    final allCards = [...widget.hand, ...widget.kitty];
    final isValid = _selectedIndices.length == 5;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withAlpha(128),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Exchange Kitty',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isValid
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isValid
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withAlpha(128),
                  ),
                ),
                child: Text(
                  '${_selectedIndices.length} / 5',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isValid
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Instructions
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select 5 cards to discard. Kitty cards have gold borders.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: allCards.length,
              itemBuilder: (context, index) {
                final card = allCards[index];
                final isFromKitty = index >= widget.hand.length;
                final isSelected = _selectedIndices.contains(index);

                return _buildCard(
                  context,
                  card,
                  index,
                  isFromKitty,
                  isSelected,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Confirm button
          FilledButton.icon(
            onPressed: isValid
                ? () {
                    widget.onConfirm(_selectedIndices);
                    Navigator.pop(context);
                  }
                : null,
            icon: const Icon(Icons.check),
            label: const Text('Confirm Discard'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    PlayingCard card,
    int index,
    bool isFromKitty,
    bool isSelected,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the available width from grid constraints
        final cardWidth = constraints.maxWidth;

        return GestureDetector(
          onTap: () => _toggleSelection(index),
          child: Stack(
            children: [
              // Playing card with custom border overlay for kitty cards
              Container(
                decoration: isFromKitty
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(cardWidth * 0.1),
                        border: Border.all(
                          color: Colors.amber.shade700,
                          width: 3,
                        ),
                      )
                    : null,
                child: PlayingCardWidget(
                  card: card,
                  width: cardWidth,
                  isSelected: isSelected,
                  onTap: () => _toggleSelection(index),
                ),
              ),

              // Star icon for kitty cards
              if (isFromKitty)
                Positioned(
                  bottom: cardWidth * 0.12,
                  left: 0,
                  right: 0,
                  child: Icon(
                    Icons.star,
                    size: cardWidth * 0.25,
                    color: Colors.amber.shade700,
                  ),
                ),

              // Selection checkmark
              if (isSelected)
                Positioned(
                  top: cardWidth * 0.08,
                  right: cardWidth * 0.08,
                  child: Container(
                    padding: EdgeInsets.all(cardWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: cardWidth * 0.2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else if (_selectedIndices.length < 5) {
        _selectedIndices.add(index);
      }
    });
  }
}
