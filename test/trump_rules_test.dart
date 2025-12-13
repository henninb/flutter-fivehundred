import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/logic/trump_rules.dart';
import 'package:fivehundred/src/game/models/card.dart';

PlayingCard _card(Rank rank, Suit suit) => PlayingCard(rank: rank, suit: suit);
const PlayingCard _joker = PlayingCard(rank: Rank.joker, suit: Suit.spades);

void main() {
  group('TrumpRules.isTrump', () {
    test('joker is always trump regardless of trump suit', () {
      expect(const TrumpRules(trumpSuit: Suit.hearts).isTrump(_joker), isTrue);
      expect(const TrumpRules(trumpSuit: Suit.spades).isTrump(_joker), isTrue);
      expect(const TrumpRules(trumpSuit: null).isTrump(_joker), isTrue);
    });

    test('cards of trump suit are trump', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isTrump(_card(Rank.ace, Suit.hearts)), isTrue);
      expect(rules.isTrump(_card(Rank.four, Suit.hearts)), isTrue);
      expect(rules.isTrump(_card(Rank.queen, Suit.hearts)), isTrue);
    });

    test('cards not of trump suit are not trump (except left bower)', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isTrump(_card(Rank.ace, Suit.spades)), isFalse);
      expect(rules.isTrump(_card(Rank.king, Suit.clubs)), isFalse);
    });

    test('left bower is trump (jack of same color)', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      // Jack of Diamonds is left bower when Hearts is trump
      expect(rules.isTrump(_card(Rank.jack, Suit.diamonds)), isTrue);
    });

    test('no cards are trump in no-trump except joker', () {
      final rules = const TrumpRules(trumpSuit: null);
      expect(rules.isTrump(_card(Rank.ace, Suit.hearts)), isFalse);
      expect(rules.isTrump(_card(Rank.jack, Suit.spades)), isFalse);
      expect(rules.isTrump(_joker), isTrue);
    });
  });

  group('TrumpRules.isRightBower', () {
    test('identifies right bower correctly', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isRightBower(_card(Rank.jack, Suit.hearts)), isTrue);
    });

    test('other jacks are not right bower', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isRightBower(_card(Rank.jack, Suit.spades)), isFalse);
      expect(rules.isRightBower(_card(Rank.jack, Suit.clubs)), isFalse);
      expect(rules.isRightBower(_card(Rank.jack, Suit.diamonds)), isFalse);
    });

    test('non-jacks are not right bower', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isRightBower(_card(Rank.ace, Suit.hearts)), isFalse);
      expect(rules.isRightBower(_card(Rank.queen, Suit.hearts)), isFalse);
    });

    test('no right bower in no-trump', () {
      final rules = const TrumpRules(trumpSuit: null);
      expect(rules.isRightBower(_card(Rank.jack, Suit.hearts)), isFalse);
    });
  });

  group('TrumpRules.isLeftBower', () {
    test('identifies left bower for hearts (diamonds)', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isLeftBower(_card(Rank.jack, Suit.diamonds)), isTrue);
    });

    test('identifies left bower for diamonds (hearts)', () {
      final rules = const TrumpRules(trumpSuit: Suit.diamonds);
      expect(rules.isLeftBower(_card(Rank.jack, Suit.hearts)), isTrue);
    });

    test('identifies left bower for spades (clubs)', () {
      final rules = const TrumpRules(trumpSuit: Suit.spades);
      expect(rules.isLeftBower(_card(Rank.jack, Suit.clubs)), isTrue);
    });

    test('identifies left bower for clubs (spades)', () {
      final rules = const TrumpRules(trumpSuit: Suit.clubs);
      expect(rules.isLeftBower(_card(Rank.jack, Suit.spades)), isTrue);
    });

    test('right bower is not left bower', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isLeftBower(_card(Rank.jack, Suit.hearts)), isFalse);
    });

    test('non-jacks are not left bower', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.isLeftBower(_card(Rank.ace, Suit.diamonds)), isFalse);
      expect(rules.isLeftBower(_card(Rank.king, Suit.diamonds)), isFalse);
    });

    test('no left bower in no-trump', () {
      final rules = const TrumpRules(trumpSuit: null);
      expect(rules.isLeftBower(_card(Rank.jack, Suit.diamonds)), isFalse);
    });
  });

  group('TrumpRules.getEffectiveSuit', () {
    test('joker takes on trump suit when trump declared', () {
      expect(
        const TrumpRules(trumpSuit: Suit.hearts).getEffectiveSuit(_joker),
        Suit.hearts,
      );
      expect(
        const TrumpRules(trumpSuit: Suit.spades).getEffectiveSuit(_joker),
        Suit.spades,
      );
    });

    test('joker has arbitrary suit in no-trump', () {
      final suit = const TrumpRules(trumpSuit: null).getEffectiveSuit(_joker);
      expect(suit, isNotNull); // Just needs to return something
    });

    test('left bower counts as trump suit', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(
        rules.getEffectiveSuit(_card(Rank.jack, Suit.diamonds)),
        Suit.hearts,
      );
    });

    test('regular cards keep their printed suit', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.getEffectiveSuit(_card(Rank.ace, Suit.spades)), Suit.spades);
      expect(rules.getEffectiveSuit(_card(Rank.king, Suit.clubs)), Suit.clubs);
      expect(rules.getEffectiveSuit(_card(Rank.ace, Suit.hearts)), Suit.hearts);
    });
  });

  group('TrumpRules.compare', () {
    test('trump always beats non-trump', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(
        rules.compare(
          _card(Rank.four, Suit.hearts),
          _card(Rank.ace, Suit.spades),
        ),
        greaterThan(0),
      );
    });

    test('non-trump never beats trump', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(
        rules.compare(
          _card(Rank.ace, Suit.spades),
          _card(Rank.four, Suit.hearts),
        ),
        lessThan(0),
      );
    });

    test('trump cards ranked correctly: joker > right bower > left bower', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final joker = _joker;
      final rightBower = _card(Rank.jack, Suit.hearts);
      final leftBower = _card(Rank.jack, Suit.diamonds);

      expect(rules.compare(joker, rightBower), greaterThan(0));
      expect(rules.compare(joker, leftBower), greaterThan(0));
      expect(rules.compare(rightBower, leftBower), greaterThan(0));
    });

    test('trump ace beats lower trump cards', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(
        rules.compare(
          _card(Rank.ace, Suit.hearts),
          _card(Rank.king, Suit.hearts),
        ),
        greaterThan(0),
      );
      expect(
        rules.compare(
          _card(Rank.ace, Suit.hearts),
          _card(Rank.four, Suit.hearts),
        ),
        greaterThan(0),
      );
    });

    test('non-trump cards compared by rank', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(
        rules.compare(
          _card(Rank.ace, Suit.spades),
          _card(Rank.king, Suit.spades),
        ),
        greaterThan(0),
      );
      expect(
        rules.compare(
          _card(Rank.ten, Suit.clubs),
          _card(Rank.nine, Suit.clubs),
        ),
        greaterThan(0),
      );
    });

    test('in no-trump, joker beats all cards', () {
      final rules = const TrumpRules(trumpSuit: null);
      expect(
        rules.compare(_joker, _card(Rank.ace, Suit.hearts)),
        greaterThan(0),
      );
      expect(
        rules.compare(_joker, _card(Rank.jack, Suit.spades)),
        greaterThan(0),
      );
    });

    test('in no-trump, regular cards compared by rank', () {
      final rules = const TrumpRules(trumpSuit: null);
      expect(
        rules.compare(
          _card(Rank.ace, Suit.hearts),
          _card(Rank.king, Suit.hearts),
        ),
        greaterThan(0),
      );
    });
  });

  group('TrumpRules.getTrumpCards', () {
    test('returns only trump cards from hand', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final hand = [
        _card(Rank.ace, Suit.hearts),
        _card(Rank.king, Suit.spades),
        _card(Rank.jack, Suit.diamonds), // Left bower
        _card(Rank.queen, Suit.clubs),
        _joker,
      ];

      final trumps = rules.getTrumpCards(hand);
      expect(trumps.length, 3);
      expect(trumps.contains(_card(Rank.ace, Suit.hearts)), isTrue);
      expect(trumps.contains(_card(Rank.jack, Suit.diamonds)), isTrue);
      expect(trumps.contains(_joker), isTrue);
    });

    test('returns empty list when no trump cards', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final hand = [
        _card(Rank.ace, Suit.spades),
        _card(Rank.king, Suit.clubs),
      ];

      final trumps = rules.getTrumpCards(hand);
      expect(trumps.isEmpty, isTrue);
    });
  });

  group('TrumpRules.getNonTrumpCards', () {
    test('returns only non-trump cards from hand', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final hand = [
        _card(Rank.ace, Suit.hearts),
        _card(Rank.king, Suit.spades),
        _card(Rank.jack, Suit.diamonds), // Left bower
        _card(Rank.queen, Suit.clubs),
        _joker,
      ];

      final nonTrumps = rules.getNonTrumpCards(hand);
      expect(nonTrumps.length, 2);
      expect(nonTrumps.contains(_card(Rank.king, Suit.spades)), isTrue);
      expect(nonTrumps.contains(_card(Rank.queen, Suit.clubs)), isTrue);
    });

    test('returns all cards in no-trump except joker', () {
      final rules = const TrumpRules(trumpSuit: null);
      final hand = [
        _card(Rank.ace, Suit.hearts),
        _card(Rank.jack, Suit.spades),
        _joker,
      ];

      final nonTrumps = rules.getNonTrumpCards(hand);
      expect(nonTrumps.length, 2);
    });
  });

  group('TrumpRules.countTrump', () {
    test('counts trump cards correctly', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final hand = [
        _card(Rank.ace, Suit.hearts),
        _card(Rank.king, Suit.spades),
        _card(Rank.jack, Suit.diamonds), // Left bower
        _joker,
      ];

      expect(rules.countTrump(hand), 3);
    });

    test('returns zero when no trumps', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final hand = [
        _card(Rank.ace, Suit.spades),
        _card(Rank.king, Suit.clubs),
      ];

      expect(rules.countTrump(hand), 0);
    });
  });

  group('TrumpRules.getHighestCard', () {
    test('returns joker when present', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final cards = [
        _card(Rank.ace, Suit.hearts),
        _joker,
        _card(Rank.king, Suit.spades),
      ];

      expect(rules.getHighestCard(cards), _joker);
    });

    test('returns right bower when no joker', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final cards = [
        _card(Rank.ace, Suit.hearts),
        _card(Rank.jack, Suit.hearts),
        _card(Rank.king, Suit.spades),
      ];

      expect(rules.getHighestCard(cards), _card(Rank.jack, Suit.hearts));
    });

    test('returns null for empty list', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.getHighestCard([]), isNull);
    });

    test('returns highest non-trump when no trumps present', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final cards = [
        _card(Rank.king, Suit.spades),
        _card(Rank.ace, Suit.clubs),
        _card(Rank.queen, Suit.spades),
      ];

      expect(rules.getHighestCard(cards), _card(Rank.ace, Suit.clubs));
    });
  });

  group('TrumpRules.getLowestCard', () {
    test('returns lowest card correctly', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final cards = [
        _card(Rank.ace, Suit.spades),
        _card(Rank.four, Suit.clubs),
        _card(Rank.king, Suit.spades),
      ];

      expect(rules.getLowestCard(cards), _card(Rank.four, Suit.clubs));
    });

    test('returns null for empty list', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      expect(rules.getLowestCard([]), isNull);
    });

    test('non-trump is lower than trump', () {
      final rules = const TrumpRules(trumpSuit: Suit.hearts);
      final cards = [
        _card(Rank.ace, Suit.spades),
        _card(Rank.four, Suit.hearts), // Trump
      ];

      expect(rules.getLowestCard(cards), _card(Rank.ace, Suit.spades));
    });
  });

  group('TrumpRules.toString', () {
    test('displays no-trump correctly', () {
      expect(
        const TrumpRules(trumpSuit: null).toString(),
        contains('No Trump'),
      );
    });

    test('displays trump suit correctly', () {
      expect(
        const TrumpRules(trumpSuit: Suit.hearts).toString(),
        contains('♥'),
      );
      expect(
        const TrumpRules(trumpSuit: Suit.spades).toString(),
        contains('♠'),
      );
    });
  });
}
