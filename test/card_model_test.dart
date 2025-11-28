import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/models/card.dart';

void main() {
  group('PlayingCard encoding and values', () {
    test('encode/decode round trip preserves rank and suit', () {
      const original = PlayingCard(rank: Rank.queen, suit: Suit.diamonds);
      final decoded = PlayingCard.decode(original.encode());
      expect(decoded, original);
    });

    test('decode clamps invalid indices into valid enum ranges', () {
      final decoded = PlayingCard.decode('99|99');
      expect(decoded.rank, Rank.ace);
      expect(decoded.suit, Suit.spades);
    });

    test('value maps card ranks to expected values', () {
      expect(const PlayingCard(rank: Rank.joker, suit: Suit.spades).value, 0);
      expect(const PlayingCard(rank: Rank.four, suit: Suit.spades).value, 4);
      expect(const PlayingCard(rank: Rank.ten, suit: Suit.spades).value, 10);
      expect(const PlayingCard(rank: Rank.ace, suit: Suit.spades).value, 11);
    });

    test('label produces concise rank and suit symbols', () {
      const card = PlayingCard(rank: Rank.ace, suit: Suit.clubs);
      expect(card.label, 'A♣');
      const joker = PlayingCard(rank: Rank.joker, suit: Suit.hearts);
      expect(joker.label, 'JOKER');
    });
  });

  group('Deck creation', () {
    test('createDeck returns 45 unique cards with one joker', () {
      final deck = createDeck();
      expect(deck, hasLength(45));
      expect(deck.toSet(), hasLength(45));
      expect(deck.where((c) => c.isJoker), hasLength(1));
    });

    test('createDeck accepts seeded random for deterministic shuffle', () {
      final deckA = createDeck(random: Random(42));
      final deckB = createDeck(random: Random(42));
      expect(deckA, deckB);
    });
  });

  group('Hand sorting', () {
    test('sortHandBySuit groups by suit with joker first before trump declared', () {
      final hand = [
        const PlayingCard(rank: Rank.king, suit: Suit.spades),
        const PlayingCard(rank: Rank.four, suit: Suit.clubs),
        const PlayingCard(rank: Rank.jack, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.joker, suit: Suit.spades),
      ];

      final sorted = sortHandBySuit(hand);
      expect(sorted.first.isJoker, isTrue);
      expect(sorted[1], const PlayingCard(rank: Rank.king, suit: Suit.spades));
      expect(sorted[2], const PlayingCard(rank: Rank.jack, suit: Suit.hearts));
      expect(sorted[3], const PlayingCard(rank: Rank.five, suit: Suit.diamonds));
      expect(sorted.last, const PlayingCard(rank: Rank.four, suit: Suit.clubs));
    });

    test('sortHandBySuit prioritizes trump with left and right bowers', () {
      final hand = [
        const PlayingCard(rank: Rank.joker, suit: Suit.spades),
        const PlayingCard(rank: Rank.jack, suit: Suit.hearts), // Right bower
        const PlayingCard(rank: Rank.jack, suit: Suit.diamonds), // Left bower for hearts
        const PlayingCard(rank: Rank.ace, suit: Suit.spades),
        const PlayingCard(rank: Rank.king, suit: Suit.clubs),
      ];

      final sorted = sortHandBySuit(hand, trumpSuit: Suit.hearts);

      expect(sorted.take(3), [
        const PlayingCard(rank: Rank.joker, suit: Suit.spades),
        const PlayingCard(rank: Rank.jack, suit: Suit.hearts),
        const PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
      ]);
      expect(sorted.last, const PlayingCard(rank: Rank.king, suit: Suit.clubs));
    });
  });
}
