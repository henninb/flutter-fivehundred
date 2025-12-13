import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/logic/avondale_table.dart';
import 'package:fivehundred/src/game/models/game_models.dart';

void main() {
  group('AvondaleTable.getBidValue', () {
    test('returns correct values for 6-trick bids', () {
      expect(AvondaleTable.getBidValue(6, BidSuit.spades), 40);
      expect(AvondaleTable.getBidValue(6, BidSuit.clubs), 60);
      expect(AvondaleTable.getBidValue(6, BidSuit.diamonds), 80);
      expect(AvondaleTable.getBidValue(6, BidSuit.hearts), 100);
      expect(AvondaleTable.getBidValue(6, BidSuit.noTrump), 120);
    });

    test('returns correct values for 7-trick bids', () {
      expect(AvondaleTable.getBidValue(7, BidSuit.spades), 140);
      expect(AvondaleTable.getBidValue(7, BidSuit.clubs), 160);
      expect(AvondaleTable.getBidValue(7, BidSuit.diamonds), 180);
      expect(AvondaleTable.getBidValue(7, BidSuit.hearts), 200);
      expect(AvondaleTable.getBidValue(7, BidSuit.noTrump), 220);
    });

    test('returns correct values for 8-trick bids', () {
      expect(AvondaleTable.getBidValue(8, BidSuit.spades), 240);
      expect(AvondaleTable.getBidValue(8, BidSuit.clubs), 260);
      expect(AvondaleTable.getBidValue(8, BidSuit.diamonds), 280);
      expect(AvondaleTable.getBidValue(8, BidSuit.hearts), 300);
      expect(AvondaleTable.getBidValue(8, BidSuit.noTrump), 320);
    });

    test('returns correct values for 9-trick bids', () {
      expect(AvondaleTable.getBidValue(9, BidSuit.spades), 340);
      expect(AvondaleTable.getBidValue(9, BidSuit.clubs), 360);
      expect(AvondaleTable.getBidValue(9, BidSuit.diamonds), 380);
      expect(AvondaleTable.getBidValue(9, BidSuit.hearts), 400);
      expect(AvondaleTable.getBidValue(9, BidSuit.noTrump), 420);
    });

    test('returns correct values for 10-trick bids', () {
      expect(AvondaleTable.getBidValue(10, BidSuit.spades), 440);
      expect(AvondaleTable.getBidValue(10, BidSuit.clubs), 460);
      expect(AvondaleTable.getBidValue(10, BidSuit.diamonds), 480);
      expect(AvondaleTable.getBidValue(10, BidSuit.hearts), 500);
      expect(AvondaleTable.getBidValue(10, BidSuit.noTrump), 520);
    });

    test('returns 0 for invalid trick counts', () {
      expect(AvondaleTable.getBidValue(5, BidSuit.spades), 0);
      expect(AvondaleTable.getBidValue(11, BidSuit.hearts), 0);
      expect(AvondaleTable.getBidValue(0, BidSuit.noTrump), 0);
      expect(AvondaleTable.getBidValue(-1, BidSuit.clubs), 0);
      expect(AvondaleTable.getBidValue(100, BidSuit.diamonds), 0);
    });

    test('suit order is correct: spades < clubs < diamonds < hearts < NT', () {
      // At same trick level, higher suits worth more
      expect(
        AvondaleTable.getBidValue(7, BidSuit.clubs),
        greaterThan(AvondaleTable.getBidValue(7, BidSuit.spades)),
      );
      expect(
        AvondaleTable.getBidValue(7, BidSuit.diamonds),
        greaterThan(AvondaleTable.getBidValue(7, BidSuit.clubs)),
      );
      expect(
        AvondaleTable.getBidValue(7, BidSuit.hearts),
        greaterThan(AvondaleTable.getBidValue(7, BidSuit.diamonds)),
      );
      expect(
        AvondaleTable.getBidValue(7, BidSuit.noTrump),
        greaterThan(AvondaleTable.getBidValue(7, BidSuit.hearts)),
      );
    });

    test('higher tricks always worth more than lower tricks', () {
      expect(
        AvondaleTable.getBidValue(7, BidSuit.spades),
        greaterThan(AvondaleTable.getBidValue(6, BidSuit.noTrump)),
      );
      expect(
        AvondaleTable.getBidValue(8, BidSuit.spades),
        greaterThan(AvondaleTable.getBidValue(7, BidSuit.noTrump)),
      );
    });
  });

  group('AvondaleTable.getBidValueFromBid', () {
    test('returns same value as getBidValue for valid bid', () {
      final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      expect(
        AvondaleTable.getBidValueFromBid(bid),
        AvondaleTable.getBidValue(7, BidSuit.hearts),
      );
    });

    test('handles all suit types', () {
      for (final suit in BidSuit.values) {
        final bid = Bid(tricks: 8, suit: suit, bidder: Position.south);
        expect(
          AvondaleTable.getBidValueFromBid(bid),
          AvondaleTable.getBidValue(8, suit),
        );
      }
    });
  });

  group('AvondaleTable.isValidBid', () {
    test('returns true for 6-10 tricks', () {
      expect(AvondaleTable.isValidBid(6), isTrue);
      expect(AvondaleTable.isValidBid(7), isTrue);
      expect(AvondaleTable.isValidBid(8), isTrue);
      expect(AvondaleTable.isValidBid(9), isTrue);
      expect(AvondaleTable.isValidBid(10), isTrue);
    });

    test('returns false for less than 6 tricks', () {
      expect(AvondaleTable.isValidBid(5), isFalse);
      expect(AvondaleTable.isValidBid(0), isFalse);
      expect(AvondaleTable.isValidBid(-1), isFalse);
    });

    test('returns false for more than 10 tricks', () {
      expect(AvondaleTable.isValidBid(11), isFalse);
      expect(AvondaleTable.isValidBid(20), isFalse);
    });
  });

  group('AvondaleTable.getAllBidsInOrder', () {
    test('returns 25 bids (5 suits × 5 trick levels)', () {
      final bids = AvondaleTable.getAllBidsInOrder(Position.west);
      expect(bids.length, 25);
    });

    test('bids are sorted by value', () {
      final bids = AvondaleTable.getAllBidsInOrder(Position.east);
      for (int i = 0; i < bids.length - 1; i++) {
        expect(bids[i].value, lessThanOrEqualTo(bids[i + 1].value));
      }
    });

    test('lowest bid is 6 spades (40 points)', () {
      final bids = AvondaleTable.getAllBidsInOrder(Position.north);
      expect(bids.first.tricks, 6);
      expect(bids.first.suit, BidSuit.spades);
      expect(bids.first.value, 40);
    });

    test('highest bid is 10 no-trump (520 points)', () {
      final bids = AvondaleTable.getAllBidsInOrder(Position.south);
      expect(bids.last.tricks, 10);
      expect(bids.last.suit, BidSuit.noTrump);
      expect(bids.last.value, 520);
    });

    test('all bids have specified bidder', () {
      final bids = AvondaleTable.getAllBidsInOrder(Position.west);
      for (final bid in bids) {
        expect(bid.bidder, Position.west);
      }
    });

    test('includes all suit types for each trick level', () {
      final bids = AvondaleTable.getAllBidsInOrder(Position.north);
      for (int tricks = 6; tricks <= 10; tricks++) {
        final bidsAtLevel = bids.where((b) => b.tricks == tricks).toList();
        expect(bidsAtLevel.length, 5); // All 5 suits
        expect(bidsAtLevel.any((b) => b.suit == BidSuit.spades), isTrue);
        expect(bidsAtLevel.any((b) => b.suit == BidSuit.clubs), isTrue);
        expect(bidsAtLevel.any((b) => b.suit == BidSuit.diamonds), isTrue);
        expect(bidsAtLevel.any((b) => b.suit == BidSuit.hearts), isTrue);
        expect(bidsAtLevel.any((b) => b.suit == BidSuit.noTrump), isTrue);
      }
    });
  });

  group('AvondaleTable.getMinimumBeatBid', () {
    test('returns higher suit at same level when available', () {
      final currentBid =
          Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north);
      final beatBid =
          AvondaleTable.getMinimumBeatBid(currentBid, Position.south);

      expect(beatBid, isNotNull);
      expect(beatBid!.tricks, 7);
      expect(beatBid.suit, BidSuit.clubs);
      expect(beatBid.bidder, Position.south);
    });

    test('returns next trick level when no higher suit available', () {
      final currentBid =
          Bid(tricks: 7, suit: BidSuit.noTrump, bidder: Position.north);
      final beatBid =
          AvondaleTable.getMinimumBeatBid(currentBid, Position.east);

      expect(beatBid, isNotNull);
      expect(beatBid!.tricks, 8);
      expect(beatBid.suit, BidSuit.spades);
      expect(beatBid.bidder, Position.east);
    });

    test('returns null when 10 no-trump cannot be beaten', () {
      final currentBid =
          Bid(tricks: 10, suit: BidSuit.noTrump, bidder: Position.west);
      final beatBid =
          AvondaleTable.getMinimumBeatBid(currentBid, Position.south);

      expect(beatBid, isNull);
    });

    test('works correctly for middle suits', () {
      final currentBid =
          Bid(tricks: 8, suit: BidSuit.clubs, bidder: Position.north);
      final beatBid =
          AvondaleTable.getMinimumBeatBid(currentBid, Position.south);

      expect(beatBid, isNotNull);
      expect(beatBid!.tricks, 8);
      expect(beatBid.suit, BidSuit.diamonds);
    });

    test('returned bid actually beats the current bid', () {
      for (int tricks = 6; tricks < 10; tricks++) {
        for (final suit in BidSuit.values) {
          if (tricks == 10 && suit == BidSuit.noTrump) continue; // Skip max bid

          final currentBid =
              Bid(tricks: tricks, suit: suit, bidder: Position.north);
          final beatBid =
              AvondaleTable.getMinimumBeatBid(currentBid, Position.south);

          expect(beatBid, isNotNull);
          expect(beatBid!.beats(currentBid), isTrue);
        }
      }
    });

    test('preserves bidder position', () {
      final currentBid =
          Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      final beatBid =
          AvondaleTable.getMinimumBeatBid(currentBid, Position.west);

      expect(beatBid, isNotNull);
      expect(beatBid!.bidder, Position.west);
    });
  });

  group('AvondaleTable scoring progression', () {
    test('value increases by 20 for each suit within same trick level', () {
      for (int tricks = 6; tricks <= 10; tricks++) {
        expect(
          AvondaleTable.getBidValue(tricks, BidSuit.clubs) -
              AvondaleTable.getBidValue(tricks, BidSuit.spades),
          20,
        );
        expect(
          AvondaleTable.getBidValue(tricks, BidSuit.diamonds) -
              AvondaleTable.getBidValue(tricks, BidSuit.clubs),
          20,
        );
        expect(
          AvondaleTable.getBidValue(tricks, BidSuit.hearts) -
              AvondaleTable.getBidValue(tricks, BidSuit.diamonds),
          20,
        );
        expect(
          AvondaleTable.getBidValue(tricks, BidSuit.noTrump) -
              AvondaleTable.getBidValue(tricks, BidSuit.hearts),
          20,
        );
      }
    });

    test('value increases by 100 for each additional trick in spades', () {
      for (int tricks = 6; tricks < 10; tricks++) {
        expect(
          AvondaleTable.getBidValue(tricks + 1, BidSuit.spades) -
              AvondaleTable.getBidValue(tricks, BidSuit.spades),
          100,
        );
      }
    });

    test('10 hearts equals exactly 500 points', () {
      expect(AvondaleTable.getBidValue(10, BidSuit.hearts), 500);
    });

    test('10 no-trump is the highest possible bid at 520 points', () {
      final allBids = AvondaleTable.getAllBidsInOrder(Position.north);
      final max = allBids.map((b) => b.value).reduce((a, b) => a > b ? a : b);
      expect(max, 520);
      expect(AvondaleTable.getBidValue(10, BidSuit.noTrump), 520);
    });
  });
}
