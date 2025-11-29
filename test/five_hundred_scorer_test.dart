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

    test('applies slam bonus when all tricks won', () {
      final score = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 10,
        opponentTricks: 0,
      );

      expect(score.contractMade, isTrue);
      expect(score.isSlam, isTrue);
      expect(score.contractorPoints, 250);
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
