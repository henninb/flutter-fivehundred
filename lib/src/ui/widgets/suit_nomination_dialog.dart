import 'package:flutter/material.dart';
import '../../game/models/card.dart';

/// Dialog for nominating a suit when leading with joker in no-trump
class SuitNominationDialog extends StatelessWidget {
  const SuitNominationDialog({
    super.key,
    required this.onSuitSelected,
  });

  final Function(Suit) onSuitSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nominate a Suit',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You are leading with the Joker in no-trump.\nSelect which suit you want to nominate:',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Suit selection buttons
            _buildSuitButton(context, Suit.spades, '♠ Spades'),
            const SizedBox(height: 12),
            _buildSuitButton(context, Suit.clubs, '♣ Clubs'),
            const SizedBox(height: 12),
            _buildSuitButton(context, Suit.diamonds, '♦ Diamonds'),
            const SizedBox(height: 12),
            _buildSuitButton(context, Suit.hearts, '♥ Hearts'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuitButton(BuildContext context, Suit suit, String label) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          onSuitSelected(suit);
          Navigator.of(context).pop();
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
