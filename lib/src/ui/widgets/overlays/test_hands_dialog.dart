import 'dart:math';
import 'package:flutter/material.dart';
import '../../../game/models/card.dart';
import '../../../game/models/test_hands.dart';

/// Dialog for selecting test hands during debugging/testing
///
/// Provides two tabs:
/// 1. Canned Scenarios - Pre-defined interesting hands
/// 2. Random with Constraints - Generate random hands with specific requirements
class TestHandsDialog extends StatefulWidget {
  const TestHandsDialog({
    super.key,
    required this.onTestHandSelected,
  });

  final Function(List<PlayingCard> testHand) onTestHandSelected;

  @override
  State<TestHandsDialog> createState() => _TestHandsDialogState();
}

class _TestHandsDialogState extends State<TestHandsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Test Hands',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a test hand for debugging',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Canned Scenarios'),
                Tab(text: 'Random + Constraints'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCannedScenariosTab(),
                  _buildConstraintsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCannedScenariosTab() {
    return ListView.builder(
      itemCount: TestHands.scenarios.length,
      itemBuilder: (context, index) {
        final scenario = TestHands.scenarios[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              scenario.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(scenario.description),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: scenario.cards
                      .map(
                        (card) => Chip(
                          label: Text(
                            card.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCardColor(card, context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => widget.onTestHandSelected(scenario.cards),
          ),
        );
      },
    );
  }

  Widget _buildConstraintsTab() {
    return ListView.builder(
      itemCount: TestHands.constraints.length,
      itemBuilder: (context, index) {
        final constraint = TestHands.constraints[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              constraint.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(constraint.description),
            trailing: const Icon(Icons.shuffle),
            onTap: () {
              final hand = _generateHandFromConstraint(constraint);
              widget.onTestHandSelected(hand);
            },
          ),
        );
      },
    );
  }

  Color _getCardColor(PlayingCard card, BuildContext context) {
    if (card.isJoker) {
      return Theme.of(context).colorScheme.primary;
    }
    switch (card.suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return Colors.red;
      case Suit.spades:
      case Suit.clubs:
        return Colors.black87;
    }
  }

  List<PlayingCard> _generateHandFromConstraint(HandConstraint constraint) {
    final random = Random();
    final deck = createDeck(random: random);
    final hand = <PlayingCard>[];

    // Special case: Balanced hand
    if (constraint.name == 'Balanced Hand') {
      return _generateBalancedHand(deck, random);
    }

    // Handle Joker constraint
    if (constraint.includeJoker) {
      final joker = deck.firstWhere((card) => card.isJoker);
      hand.add(joker);
      deck.remove(joker);
    }

    // Handle suit constraint (5+ of a suit)
    if (constraint.minSuit != null) {
      final suitCards =
          deck.where((card) => card.suit == constraint.minSuit!).toList();
      // Take 5-7 cards of that suit
      final numToTake = 5 + random.nextInt(3);
      suitCards.shuffle(random);
      hand.addAll(suitCards.take(numToTake));
      for (final card in hand) {
        deck.remove(card);
      }
    }

    // Handle high cards constraint
    if (constraint.minHighCards > 0) {
      final highCards = deck
          .where(
            (card) =>
                card.rank == Rank.ace ||
                card.rank == Rank.king ||
                card.rank == Rank.queen,
          )
          .toList();
      highCards.shuffle(random);
      final numNeeded = constraint.minHighCards - hand.length;
      if (numNeeded > 0) {
        hand.addAll(highCards.take(numNeeded));
        for (final card in hand.skip(hand.length - numNeeded)) {
          deck.remove(card);
        }
      }
    }

    // Fill remaining slots randomly
    deck.shuffle(random);
    while (hand.length < 10 && deck.isNotEmpty) {
      hand.add(deck.removeAt(0));
    }

    // Sort by suit
    return sortHandBySuit(hand);
  }

  List<PlayingCard> _generateBalancedHand(
    List<PlayingCard> deck,
    Random random,
  ) {
    final hand = <PlayingCard>[];

    // Try to get 2-3 cards of each suit
    for (final suit in Suit.values) {
      final suitCards = deck.where((card) => card.suit == suit).toList();
      suitCards.shuffle(random);
      final numToTake = 2 + random.nextInt(2); // 2 or 3 cards per suit
      hand.addAll(suitCards.take(numToTake.clamp(0, suitCards.length)));
    }

    // Ensure exactly 10 cards
    if (hand.length < 10) {
      final remaining = deck.where((card) => !hand.contains(card)).toList();
      remaining.shuffle(random);
      hand.addAll(remaining.take(10 - hand.length));
    } else if (hand.length > 10) {
      hand.shuffle(random);
      hand.removeRange(10, hand.length);
    }

    return sortHandBySuit(hand);
  }
}
