import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/models/card.dart';
import 'package:fivehundred/src/game/models/game_models.dart';

PlayingCard _card(Rank rank, Suit suit) => PlayingCard(rank: rank, suit: suit);

void main() {
  group('Position enum', () {
    test('has exactly 4 positions', () {
      expect(Position.values.length, 4);
    });

    test('team getter assigns correct teams', () {
      expect(Position.north.team, Team.northSouth);
      expect(Position.south.team, Team.northSouth);
      expect(Position.east.team, Team.eastWest);
      expect(Position.west.team, Team.eastWest);
    });

    test('partner getter returns correct partners', () {
      expect(Position.north.partner, Position.south);
      expect(Position.south.partner, Position.north);
      expect(Position.east.partner, Position.west);
      expect(Position.west.partner, Position.east);
    });

    test('next getter rotates clockwise', () {
      expect(Position.north.next, Position.east);
      expect(Position.east.next, Position.south);
      expect(Position.south.next, Position.west);
      expect(Position.west.next, Position.north);
    });

    test('next forms complete cycle', () {
      var pos = Position.north;
      pos = pos.next; // east
      pos = pos.next; // south
      pos = pos.next; // west
      pos = pos.next; // back to north
      expect(pos, Position.north);
    });
  });

  group('Team enum', () {
    test('has exactly 2 teams', () {
      expect(Team.values.length, 2);
    });
  });

  group('BidSuit enum', () {
    test('has exactly 5 suit options', () {
      expect(BidSuit.values.length, 5);
    });

    test('suit order matches bidding hierarchy', () {
      expect(BidSuit.spades.index, 0);
      expect(BidSuit.clubs.index, 1);
      expect(BidSuit.diamonds.index, 2);
      expect(BidSuit.hearts.index, 3);
      expect(BidSuit.noTrump.index, 4);
    });
  });

  group('Bid', () {
    test('stores tricks, suit, and bidder correctly', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      expect(bid.tricks, 7);
      expect(bid.suit, BidSuit.hearts);
      expect(bid.bidder, Position.north);
    });

    test('value getter returns correct Avondale table value', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.south);
      expect(bid.value, 200); // 7 hearts = 200 points
    });

    test('beats method compares tricks first', () {
      final bid7 = Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north);
      final bid8 = Bid(tricks: 8, suit: BidSuit.spades, bidder: Position.south);

      expect(bid8.beats(bid7), isTrue);
      expect(bid7.beats(bid8), isFalse);
    });

    test('beats method compares suits when tricks equal', () {
      final spadeBid =
          Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north);
      final clubBid =
          Bid(tricks: 7, suit: BidSuit.clubs, bidder: Position.south);
      final heartBid =
          Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.east);

      expect(clubBid.beats(spadeBid), isTrue);
      expect(heartBid.beats(clubBid), isTrue);
      expect(spadeBid.beats(clubBid), isFalse);
    });

    test('bid does not beat itself', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      expect(bid.beats(bid), isFalse);
    });

    test('no-trump beats all suits at same trick level', () {
      final noTrumpBid =
          Bid(tricks: 7, suit: BidSuit.noTrump, bidder: Position.north);
      final heartBid =
          Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.south);

      expect(noTrumpBid.beats(heartBid), isTrue);
      expect(heartBid.beats(noTrumpBid), isFalse);
    });

    test('equality works correctly', () {
      final bid1 = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final bid2 = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final bid3 = Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north);

      expect(bid1 == bid2, isTrue);
      expect(bid1 == bid3, isFalse);
    });

    test('hashCode is consistent with equality', () {
      final bid1 = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final bid2 = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);

      expect(bid1.hashCode, bid2.hashCode);
    });

    test('toString includes tricks, suit, and bidder', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final str = bid.toString();

      expect(str, contains('7'));
      expect(str, contains('♥'));
      expect(str, contains('north'));
    });
  });

  group('CardPlay', () {
    test('stores card and player correctly', () {
      final card = _card(Rank.ace, Suit.hearts);
      final play = CardPlay(card: card, player: Position.north);

      expect(play.card, card);
      expect(play.player, Position.north);
    });

    test('equality works correctly', () {
      final card = _card(Rank.ace, Suit.hearts);
      final play1 = CardPlay(card: card, player: Position.north);
      final play2 = CardPlay(card: card, player: Position.north);
      final play3 = CardPlay(card: card, player: Position.south);

      expect(play1 == play2, isTrue);
      expect(play1 == play3, isFalse);
    });

    test('hashCode is consistent with equality', () {
      final card = _card(Rank.ace, Suit.hearts);
      final play1 = CardPlay(card: card, player: Position.north);
      final play2 = CardPlay(card: card, player: Position.north);

      expect(play1.hashCode, play2.hashCode);
    });

    test('toString includes card and player', () {
      final card = _card(Rank.ace, Suit.hearts);
      final play = CardPlay(card: card, player: Position.north);
      final str = play.toString();

      expect(str, contains('A♥'));
      expect(str, contains('north'));
    });
  });

  group('Trick', () {
    test('isEmpty returns true for empty trick', () {
      final trick = Trick(plays: [], leader: Position.north);
      expect(trick.isEmpty, isTrue);
    });

    test('isEmpty returns false for non-empty trick', () {
      final trick = Trick(
        plays: [
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.north),
        ],
        leader: Position.north,
      );
      expect(trick.isEmpty, isFalse);
    });

    test('isComplete returns true when 4 cards played', () {
      final trick = Trick(
        plays: [
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.north),
          CardPlay(card: _card(Rank.king, Suit.hearts), player: Position.east),
          CardPlay(
            card: _card(Rank.queen, Suit.hearts),
            player: Position.south,
          ),
          CardPlay(card: _card(Rank.jack, Suit.hearts), player: Position.west),
        ],
        leader: Position.north,
      );
      expect(trick.isComplete, isTrue);
    });

    test('isComplete returns false when less than 4 cards', () {
      final trick = Trick(
        plays: [
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.north),
        ],
        leader: Position.north,
      );
      expect(trick.isComplete, isFalse);
    });

    test('ledSuit returns null for empty trick', () {
      final trick = Trick(plays: [], leader: Position.north);
      expect(trick.ledSuit, isNull);
    });

    test('ledSuit returns suit of first card', () {
      final trick = Trick(
        plays: [
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.north),
        ],
        leader: Position.north,
      );
      expect(trick.ledSuit, Suit.hearts);
    });

    test('addPlay adds card to trick', () {
      final trick = Trick(plays: [], leader: Position.north);
      final play =
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.north);
      final newTrick = trick.addPlay(play);

      expect(newTrick.plays.length, 1);
      expect(newTrick.plays.first, play);
    });

    test('addPlay preserves existing plays', () {
      final play1 =
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.north);
      final play2 =
          CardPlay(card: _card(Rank.king, Suit.hearts), player: Position.east);

      final trick = Trick(plays: [play1], leader: Position.north);
      final newTrick = trick.addPlay(play2);

      expect(newTrick.plays.length, 2);
      expect(newTrick.plays[0], play1);
      expect(newTrick.plays[1], play2);
    });

    test('addPlay preserves leader', () {
      final trick = Trick(plays: [], leader: Position.west);
      final play =
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.west);
      final newTrick = trick.addPlay(play);

      expect(newTrick.leader, Position.west);
    });

    test('addPlay preserves trumpSuit', () {
      final trick =
          Trick(plays: [], leader: Position.north, trumpSuit: Suit.spades);
      final play =
          CardPlay(card: _card(Rank.ace, Suit.hearts), player: Position.north);
      final newTrick = trick.addPlay(play);

      expect(newTrick.trumpSuit, Suit.spades);
    });
  });

  group('BidAction enum', () {
    test('has exactly 3 actions', () {
      expect(BidAction.values.length, 3);
    });

    test('includes pass, bid, and inkle', () {
      expect(BidAction.values, contains(BidAction.pass));
      expect(BidAction.values, contains(BidAction.bid));
      expect(BidAction.values, contains(BidAction.inkle));
    });
  });

  group('BidEntry', () {
    test('stores bidder, action, and bid correctly for pass', () {
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.pass,
        bid: null,
      );

      expect(entry.bidder, Position.north);
      expect(entry.action, BidAction.pass);
      expect(entry.bid, isNull);
    });

    test('stores bidder, action, and bid correctly for actual bid', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.bid,
        bid: bid,
      );

      expect(entry.bidder, Position.north);
      expect(entry.action, BidAction.bid);
      expect(entry.bid, bid);
    });

    test('isPass returns true for pass action', () {
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.pass,
        bid: null,
      );

      expect(entry.isPass, isTrue);
    });

    test('isPass returns false for bid action', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.bid,
        bid: bid,
      );

      expect(entry.isPass, isFalse);
    });

    test('isInkle returns true for inkle action', () {
      final bid = Bid(tricks: 6, suit: BidSuit.spades, bidder: Position.north);
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.inkle,
        bid: bid,
      );

      expect(entry.isInkle, isTrue);
    });

    test('isInkle returns false for regular bid action', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.bid,
        bid: bid,
      );

      expect(entry.isInkle, isFalse);
    });

    test('toString represents pass correctly', () {
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.pass,
        bid: null,
      );

      expect(entry.toString().toLowerCase(), contains('pass'));
    });

    test('toString represents bid correctly', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.bid,
        bid: bid,
      );

      expect(entry.toString(), contains('7'));
      expect(entry.toString(), contains('♥'));
    });

    test('toString represents inkle correctly', () {
      final bid = Bid(tricks: 6, suit: BidSuit.spades, bidder: Position.north);
      final entry = BidEntry(
        bidder: Position.north,
        action: BidAction.inkle,
        bid: bid,
      );

      expect(entry.toString().toLowerCase(), contains('inkle'));
    });
  });
}
