import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/logic/avondale_table.dart';
import 'package:fivehundred/src/game/logic/five_hundred_scorer.dart';
import 'package:fivehundred/src/game/models/game_models.dart';

void main() {
  group('FiveHundredScorer.scoreHand', () {
    const contract =
        Bid(tricks: 8, suit: BidSuit.hearts, bidder: Position.north);

    test('awards bid value when contract is made', () {
      final score = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 8,
        opponentTricks: 2,
      );

      expect(score.contractMade, isTrue);
      expect(
        score.contractorPoints,
        AvondaleTable.getBidValueFromBid(contract),
      );
      expect(score.opponentPoints, 20);
      expect(score.tricksOver, 0);
      expect(score.tricksUnder, 0);
      expect(score.isSlam, isFalse);
    });

    test('applies slam bonus to raise score to 250 for bids < 250', () {
      // 7 Spades is worth 140 points, should be raised to 250 on slam
      const lowBid =
          Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north);
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
      expect(
        score.contractorPoints,
        -AvondaleTable.getBidValueFromBid(contract),
      );
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

    test('awards bid value with overtricks correctly', () {
      final score = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 9,
        opponentTricks: 1,
      );

      expect(score.contractMade, isTrue);
      expect(
        score.contractorPoints,
        300,
      ); // 8 Hearts value, no bonus for overtricks
      expect(score.tricksOver, 1);
      expect(score.opponentPoints, 10);
    });

    test('opponents always score 10 per trick', () {
      final score1 = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 8,
        opponentTricks: 2,
      );
      expect(score1.opponentPoints, 20);

      final score2 = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 5,
        opponentTricks: 5,
      );
      expect(score2.opponentPoints, 50);

      final score3 = FiveHundredScorer.scoreHand(
        contract: contract,
        contractorTricks: 10,
        opponentTricks: 0,
      );
      expect(score3.opponentPoints, 0);
    });

    test('slam on exactly 250 point bid keeps normal value', () {
      // 8 Spades = 240, should be raised to 250
      const bid = Bid(tricks: 8, suit: BidSuit.spades, bidder: Position.north);
      final score = FiveHundredScorer.scoreHand(
        contract: bid,
        contractorTricks: 10,
        opponentTricks: 0,
      );

      expect(score.isSlam, isTrue);
      expect(score.contractorPoints, 250); // Raised from 240
    });

    test('all valid bids score correctly when made exactly', () {
      for (int tricks = 6; tricks <= 10; tricks++) {
        for (final suit in BidSuit.values) {
          final bid = Bid(tricks: tricks, suit: suit, bidder: Position.north);
          final score = FiveHundredScorer.scoreHand(
            contract: bid,
            contractorTricks: tricks,
            opponentTricks: 10 - tricks,
          );

          expect(score.contractMade, isTrue);
          expect(score.contractorPoints, AvondaleTable.getBidValueFromBid(bid));
          expect(score.tricksOver, 0);
          expect(score.tricksUnder, 0);
        }
      }
    });

    test('failed contracts always score negative bid value', () {
      const bid =
          Bid(tricks: 10, suit: BidSuit.noTrump, bidder: Position.north);
      final score = FiveHundredScorer.scoreHand(
        contract: bid,
        contractorTricks: 9,
        opponentTricks: 1,
      );

      expect(score.contractMade, isFalse);
      expect(score.contractorPoints, -520); // Negative bid value
      expect(score.tricksUnder, 1);
    });

    test('6-trick inkle slam gets 250 points', () {
      const bid = Bid(tricks: 6, suit: BidSuit.spades, bidder: Position.north);
      final score = FiveHundredScorer.scoreHand(
        contract: bid,
        contractorTricks: 10,
        opponentTricks: 0,
      );

      expect(score.isSlam, isTrue);
      expect(score.contractorPoints, 250); // Raised from 40
    });
  });

  group('FiveHundredScorer.checkGameOver', () {
    test('detects North-South win at exactly 500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 500, teamEWScore: 0),
        GameOverStatus.teamNSWins,
      );
    });

    test('detects East-West win at exactly 500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 0, teamEWScore: 500),
        GameOverStatus.teamEWWins,
      );
    });

    test('detects North-South loss at exactly -500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: -500, teamEWScore: 0),
        GameOverStatus.teamNSLoses,
      );
    });

    test('detects East-West loss at exactly -500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 0, teamEWScore: -500),
        GameOverStatus.teamEWLoses,
      );
    });

    test('detects North-South win above 500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 600, teamEWScore: 100),
        GameOverStatus.teamNSWins,
      );
    });

    test('detects East-West win above 500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 100, teamEWScore: 700),
        GameOverStatus.teamEWWins,
      );
    });

    test('detects North-South loss below -500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: -600, teamEWScore: 0),
        GameOverStatus.teamNSLoses,
      );
    });

    test('detects East-West loss below -500', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 0, teamEWScore: -700),
        GameOverStatus.teamEWLoses,
      );
    });

    test('both teams reach 500+ higher score wins', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 520, teamEWScore: 500),
        GameOverStatus.teamNSWins,
      );

      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 500, teamEWScore: 550),
        GameOverStatus.teamEWWins,
      );
    });

    test('game continues when scores are 499/-499', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 499, teamEWScore: -499),
        isNull,
      );
    });

    test('game continues at 0-0', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 0, teamEWScore: 0),
        isNull,
      );
    });

    test('game continues with normal scores', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: 200, teamEWScore: 150),
        isNull,
      );
    });

    test('loss condition takes precedence over normal scores', () {
      expect(
        FiveHundredScorer.checkGameOver(teamNSScore: -500, teamEWScore: 400),
        GameOverStatus.teamNSLoses,
      );
    });
  });

  group('FiveHundredScorer.getHandResultDescription', () {
    test('describes made contract exactly', () {
      const contract =
          Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      const score = HandScore(
        contractorPoints: 200,
        opponentPoints: 30,
        contractMade: true,
        tricksOver: 0,
        tricksUnder: 0,
      );

      final desc = FiveHundredScorer.getHandResultDescription(
        contract: contract,
        score: score,
        contractorTeam: Team.northSouth,
      );

      expect(desc.toLowerCase(), contains('north-south'));
      expect(desc, contains('7'));
      expect(desc, contains('exactly'));
      expect(desc, contains('+200'));
    });

    test('describes contract with overtricks', () {
      const contract =
          Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
      const score = HandScore(
        contractorPoints: 200,
        opponentPoints: 20,
        contractMade: true,
        tricksOver: 1,
        tricksUnder: 0,
      );

      final desc = FiveHundredScorer.getHandResultDescription(
        contract: contract,
        score: score,
        contractorTeam: Team.northSouth,
      );

      expect(desc, contains('1 overtrick'));
      expect(desc, contains('+200'));
    });

    test('describes slam', () {
      const contract =
          Bid(tricks: 7, suit: BidSuit.spades, bidder: Position.north);
      const score = HandScore(
        contractorPoints: 250,
        opponentPoints: 0,
        contractMade: true,
        tricksOver: 3,
        tricksUnder: 0,
        isSlam: true,
      );

      final desc = FiveHundredScorer.getHandResultDescription(
        contract: contract,
        score: score,
        contractorTeam: Team.northSouth,
      );

      expect(desc.toUpperCase(), contains('SLAM'));
      expect(desc, contains('10 tricks'));
      expect(desc, contains('+250'));
    });

    test('describes failed contract', () {
      const contract =
          Bid(tricks: 8, suit: BidSuit.hearts, bidder: Position.north);
      const score = HandScore(
        contractorPoints: -300,
        opponentPoints: 40,
        contractMade: false,
        tricksOver: 0,
        tricksUnder: 2,
      );

      final desc = FiveHundredScorer.getHandResultDescription(
        contract: contract,
        score: score,
        contractorTeam: Team.northSouth,
      );

      expect(desc.toLowerCase(), contains('failed'));
      expect(desc, contains('2 trick'));
      expect(desc, contains('-300'));
    });
  });

  group('FiveHundredScorer.getGameOverMessage', () {
    test('generates correct message for North-South win', () {
      final msg = FiveHundredScorer.getGameOverMessage(
        GameOverStatus.teamNSWins,
        520,
        400,
      );

      expect(msg, contains('North-South wins'));
      expect(msg, contains('520'));
      expect(msg, contains('400'));
    });

    test('generates correct message for East-West win', () {
      final msg = FiveHundredScorer.getGameOverMessage(
        GameOverStatus.teamEWWins,
        400,
        550,
      );

      expect(msg, contains('East-West wins'));
      expect(msg, contains('550'));
      expect(msg, contains('400'));
    });

    test('generates correct message for North-South loss', () {
      final msg = FiveHundredScorer.getGameOverMessage(
        GameOverStatus.teamNSLoses,
        -510,
        200,
      );

      expect(msg, contains('North-South loses'));
      expect(msg, contains('-500'));
    });

    test('generates correct message for East-West loss', () {
      final msg = FiveHundredScorer.getGameOverMessage(
        GameOverStatus.teamEWLoses,
        200,
        -520,
      );

      expect(msg, contains('East-West loses'));
      expect(msg, contains('-500'));
    });
  });
}
