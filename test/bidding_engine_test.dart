import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/logic/bidding_engine.dart';
import 'package:cribbage/src/game/models/game_models.dart';

void main() {
  group('BiddingEngine', () {
    test('bidding order starts to the dealer left and wraps clockwise', () {
      final engine = BiddingEngine(dealer: Position.south);
      expect(engine.getBiddingOrder(), [
        Position.west,
        Position.north,
        Position.east,
        Position.south,
      ]);
    });

    test('canInkle only allows first two bidders on first turn', () {
      final engine = BiddingEngine(dealer: Position.west);
      final bids = <BidEntry>[];

      expect(engine.canInkle(Position.north, bids), isTrue);
      expect(engine.canInkle(Position.east, bids), isTrue);

      bids.add(BidEntry(
        bidder: Position.north,
        action: BidAction.bid,
        bid: Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north),
      ));

      expect(engine.canInkle(Position.north, bids), isFalse);
      expect(engine.canInkle(Position.south, bids), isFalse);
    });

    test('validateBid enforces order and beating high bid rules', () {
      final engine = BiddingEngine(dealer: Position.north);
      final current = <BidEntry>[
        BidEntry(
          bidder: Position.east,
          action: BidAction.bid,
          bid: Bid(tricks: 7, suit: BidSuit.clubs, bidder: Position.east),
        ),
      ];

      final lowBid = Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.south);
      expect(
        engine.validateBid(
          bidder: Position.south,
          proposedBid: lowBid,
          currentBids: current,
          isInkle: false,
        ).isValid,
        isFalse,
      );

      final higher = Bid(tricks: 8, suit: BidSuit.spades, bidder: Position.south);
      expect(
        engine.validateBid(
          bidder: Position.south,
          proposedBid: higher,
          currentBids: current,
          isInkle: false,
        ).isValid,
        isTrue,
      );
    });

    test('determineWinner identifies winning bid or redeal states', () {
      final engine = BiddingEngine(dealer: Position.south);
      final bids = engine.getBiddingOrder().map((position) {
        return BidEntry(
          bidder: position,
          action: BidAction.bid,
          bid: Bid(tricks: 7, suit: BidSuit.hearts, bidder: position),
        );
      }).toList();

      final result = engine.determineWinner(bids);
      expect(result.status, AuctionStatus.won);
      expect(result.winner, Position.west);

      final inkles = engine.getBiddingOrder().map((position) {
        return BidEntry(
          bidder: position,
          action: BidAction.inkle,
          bid: Bid(tricks: 6, suit: BidSuit.spades, bidder: position),
        );
      }).toList();

      final redeal = engine.determineWinner(inkles);
      expect(redeal.status, AuctionStatus.redeal);
    });
  });
}
