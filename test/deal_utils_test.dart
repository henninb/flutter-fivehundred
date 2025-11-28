import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/logic/deal_utils.dart';
import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/game/models/game_models.dart';

List<PlayingCard> _orderedDeck() {
  final cards = <PlayingCard>[
    const PlayingCard(rank: Rank.joker, suit: Suit.spades),
  ];

  for (final suit in Suit.values) {
    for (final rank in Rank.values) {
      if (rank == Rank.joker) continue;
      cards.add(PlayingCard(rank: rank, suit: suit));
    }
  }

  return cards;
}

void main() {
  group('dealHand', () {
    test('throws when deck length is not 45', () {
      expect(
        () => dealHand(deck: _orderedDeck()..removeLast(), dealer: Position.south),
        throwsArgumentError,
      );
    });

    test('deals 10 cards to each player and 5 to kitty', () {
      final result = dealHand(deck: _orderedDeck(), dealer: Position.south);

      expect(result.hands[Position.north], hasLength(10));
      expect(result.hands[Position.south], hasLength(10));
      expect(result.hands[Position.east], hasLength(10));
      expect(result.hands[Position.west], hasLength(10));
      expect(result.kitty, hasLength(5));

      final allCards = [
        ...result.kitty,
        ...result.hands.values.expand((hand) => hand),
      ];
      expect(allCards.toSet(), hasLength(45));
    });

    test('follows dealing order starting to the dealer left', () {
      final deck = _orderedDeck();
      final result = dealHand(deck: deck, dealer: Position.south);

      // Dealer south -> order: west, north, east, south
      expect(result.hands[Position.west]!.first.isJoker, isTrue);
      expect(
        result.hands[Position.north]!.first,
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
      );
      expect(
        result.kitty.first,
        const PlayingCard(rank: Rank.four, suit: Suit.diamonds),
      );
    });
  });

  test('getNextDealer rotates clockwise', () {
    expect(getNextDealer(Position.north), Position.east);
    expect(getNextDealer(Position.east), Position.south);
    expect(getNextDealer(Position.south), Position.west);
    expect(getNextDealer(Position.west), Position.north);
  });
}
