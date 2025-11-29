import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/logic/avondale_table.dart';
import 'package:fivehundred/src/game/logic/five_hundred_scorer.dart';
import 'package:fivehundred/src/game/models/game_models.dart';

void main() {
  group('FiveHundredScorer.scoreHand', () {
    const contract = Bid(tricks: 8, suit: BidSuit.hearts, bidder: Position.north);

    test('awards bid value when contract is made', () {
      final score = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 8,
        opponentTricks: 2,
      );

      expect(score.contractMade, isTrue);
      expect(score.contractorPoints, AvondaleTable.getBidValueFromBid(contract));
      expect(score.opponentPoints, 20);
      expect(score.tricksOver, 0);
      expect(score.tricksUnder, 0);
      expect(score.isSlam, isFalse);
    });

    test('applies slam bonus to raise score to 250 for bids < 250', () {
      // 7 Spades is worth 140 points, should be raised to 250 on slam
      const lowBid = Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north);
      final score = FiveHundredScorer.scoreHand(
        contract: lowBid,
        contractorTricks: 10,
        opponentTricks: 0,
      );

      expect(score.contractMade, isTrue);
      expect(score.isSlam, isTrue);
      expect(score.contractorPoints, 250); // Raised from 140
      expect(score.tricksOver, 3); // 10 - 7 = 3 overtricks
    });

    test('keeps normal bid value for slams on bids >= 250', () {
      // 8 Hearts is worth 300 points, should stay 300 on slam
      final score = FiveHundredScorer.scoreHand(
        contract: contract, // 8 Hearts = 300
        contractorTricks: 10,
        opponentTricks: 0,
      );

      expect(score.contractMade, isTrue);
      expect(score.isSlam, isTrue);
      expect(score.contractorPoints, 300); // No change, already >= 250
      expect(score.tricksOver, 2);
    });

    test('penalizes failed contract and reports undertricks', () {
      final score = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 6,
        opponentTricks: 4,
      );

      expect(score.contractMade, isFalse);
      expect(score.contractorPoints, -AvondaleTable.getBidValueFromBid(contract));
      expect(score.tricksUnder, 2);
      expect(score.opponentPoints, 40);
    });

    test('throws when tricks do not sum to ten', () {
      expect(
        () => FiveHundredScorer.scoreHand(
          contract: contract,
          contractorTricks: 3,
          opponentTricks: 3,
        ),
        throwsArgumentError,
      );
    });
  });

  group('FiveHundredScorer.checkGameOver', () {
    test('detects wins and losses at score thresholds', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 500, teamEWScore: 0),
        GameOverStatus.teamNSWins,
      );
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: -510, teamEWScore: 100),
        GameOverStatus.teamNSLoses,
      );
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 100, teamEWScore: 520),
        GameOverStatus.teamEWWins,
      );
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 100, teamEWScore: -505),
        GameOverStatus.teamEWLoses,
      );
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 0, teamEWScore: 0),
        isNull,
      );
    });
  });
}
