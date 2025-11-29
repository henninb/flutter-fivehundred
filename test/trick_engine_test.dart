import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/logic/trick_engine.dart';
import 'package:fivehundred/src/game/logic/trump_rules.dart';
import 'package:fivehundred/src/game/models/card.dart';
import 'package:fivehundred/src/game/models/game_models.dart';

PlayingCard _card(Rank rank, Suit suit) => PlayingCard(rank: rank, suit: suit);

void main() {
  group('TrickEngine.validatePlay', () {
    test('requires following suit when player can', () {
      final trick = Trick(
        plays: [CardPlay(card: _card(Rank.ace, Suit.spades), player: Position.north)],
        leader: Position.north,
        trumpSuit: Suit.hearts,
      );
      final hand = [
        _card(Rank.king, Suit.spades),
        _card(Rank.ten, Suit.clubs),
      ];

      final engine = TrickEngine(trumpRules: const TrumpRules(trumpSuit: Suit.hearts));
      final validation = engine.validatePlay(
        trick: trick,
        card: hand.last,
        hand: hand,
      );

      expect(validation.isValid, isFalse);
      expect(validation.errorMessage, contains('follow suit'));
    });

    test('blocks joker in no-trump when player still has led suit', () {
      final trick = Trick(
        plays: [CardPlay(card: _card(Rank.king, Suit.hearts), player: Position.west)],
        leader: Position.west,
      );
      final hand = [
        const PlayingCard(rank: Rank.joker, suit: Suit.spades),
        _card(Rank.four, Suit.hearts),
      ];

    final engine = TrickEngine(trumpRules: const TrumpRules());
    final validation = engine.validatePlay(
      trick: trick,
      card: hand.first,
      hand: hand,
    );

    expect(validation.isValid, isFalse);
    expect(validation.errorMessage, contains('follow suit'));
  });
  });

  test('getLegalCards respects nominated suit after joker lead in no-trump', () {
    final trick = Trick(
      plays: [
        const CardPlay(
          card: PlayingCard(rank: Rank.joker, suit: Suit.spades),
          player: Position.north,
        ),
      ],
      leader: Position.north,
    );
    final hand = [
      _card(Rank.queen, Suit.clubs),
      _card(Rank.seven, Suit.hearts),
      const PlayingCard(rank: Rank.joker, suit: Suit.spades),
    ];

    final engine = TrickEngine(trumpRules: const TrumpRules());
    final legal = engine.getLegalCards(
      trick: trick,
      hand: hand,
      nominatedSuit: Suit.clubs,
    );

    expect(legal, contains(_card(Rank.queen, Suit.clubs)));
    expect(legal, contains(const PlayingCard(rank: Rank.joker, suit: Suit.spades)));
    expect(legal, isNot(contains(_card(Rank.seven, Suit.hearts))));
  });

  test('getCurrentWinner ranks bowers correctly under trump', () {
    final trick = Trick(
      plays: [
        CardPlay(card: _card(Rank.queen, Suit.hearts), player: Position.north),
        CardPlay(card: _card(Rank.jack, Suit.diamonds), player: Position.east),
        CardPlay(card: _card(Rank.king, Suit.spades), player: Position.south),
        CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.west),
      ],
      leader: Position.north,
      trumpSuit: Suit.hearts,
    );

    final engine = TrickEngine(trumpRules: const TrumpRules(trumpSuit: Suit.hearts));
    final winner = engine.getCurrentWinner(trick);

    expect(winner, Position.east); // Left bower outranks other trump cards
  });

  test('playCard returns error status when card is not in hand', () {
    final trick = Trick(
      plays: [],
      leader: Position.north,
    );
    final hand = [
      _card(Rank.ten, Suit.hearts),
      _card(Rank.jack, Suit.hearts),
    ];

    final engine = TrickEngine(trumpRules: const TrumpRules(trumpSuit: Suit.hearts));
    final result = engine.playCard(
      currentTrick: trick,
      card: _card(Rank.ace, Suit.hearts),
      player: Position.north,
      playerHand: hand,
    );

    expect(result.status, TrickStatus.error);
    expect(result.message, contains('Card not in hand'));
  });
}
