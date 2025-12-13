import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import 'avondale_table.dart';

/// Handles scoring for the game of 500
///
/// Scoring rules:
/// - Contractor makes bid: Score = bid value (from Avondale table)
/// - Contractor fails bid: Score = -bid value (can go negative)
/// - Opponents: Score 10 points per trick taken (always)
/// - SLAM BONUS: If contractor wins all 10 tricks on a bid worth < 250, score is raised to 250
///   (Bids worth 250+ keep their normal value even with a slam)
/// - No bonus for overtricks (unless it's a slam with bid < 250)
/// - Game ends when a team reaches 500+ (wins) or -500 (loses)
class FiveHundredScorer {
  // Private constructor to prevent instantiation
  FiveHundredScorer._();

  /// Score a completed hand
  static HandScore scoreHand({
    required Bid contract,
    required int contractorTricks,
    required int opponentTricks,
  }) {
    if (kDebugMode) {
      debugPrint('\n[SCORER] Scoring hand');
      debugPrint(
        '  Contract: ${contract.tricks}${_suitLabel(contract.suit)} by ${contract.bidder.name}',
      );
      debugPrint('  Contractor tricks: $contractorTricks');
      debugPrint('  Opponent tricks: $opponentTricks');
    }

    // Validate trick counts
    if (contractorTricks + opponentTricks != 10) {
      final error =
          'Total tricks must equal 10 (got ${contractorTricks + opponentTricks})';
      if (kDebugMode) {
        debugPrint('  ⚠️  ERROR: $error');
      }
      throw ArgumentError(error);
    }

    final bidValue = AvondaleTable.getBidValueFromBid(contract);
    final contractMade = contractorTricks >= contract.tricks;
    final isSlam = contractorTricks == 10;

    if (kDebugMode) {
      debugPrint('  Bid value: $bidValue');
      debugPrint('  Contract made: $contractMade');
      debugPrint('  Is slam: $isSlam');
    }

    // Contractor scoring
    int contractorPoints;
    if (contractMade && isSlam) {
      // SLAM BONUS: If bid value < 250, raise to 250. Otherwise use bid value.
      contractorPoints = bidValue < 250 ? 250 : bidValue;
      if (kDebugMode) {
        debugPrint(
          '  SLAM! Contractor points: $contractorPoints (bid value was $bidValue)',
        );
      }
    } else if (contractMade) {
      // Normal made contract: bid value
      contractorPoints = bidValue;
      if (kDebugMode) {
        final overtricks = contractorTricks - contract.tricks;
        debugPrint(
          '  Contract made with $overtricks overtrick(s). Contractor points: $contractorPoints',
        );
      }
    } else {
      // Failed contract: negative bid value
      contractorPoints = -bidValue;
      if (kDebugMode) {
        final undertricks = contract.tricks - contractorTricks;
        debugPrint(
          '  Contract failed by $undertricks trick(s). Contractor points: $contractorPoints',
        );
      }
    }

    // Opponents always score 10 per trick
    final opponentPoints = opponentTricks * 10;

    if (kDebugMode) {
      debugPrint(
        '  Opponent points: $opponentPoints ($opponentTricks tricks × 10)',
      );
      debugPrint(
        '  Final: Contractor ${contractorPoints > 0 ? '+' : ''}$contractorPoints, Opponents +$opponentPoints',
      );
    }

    return HandScore(
      contractorPoints: contractorPoints,
      opponentPoints: opponentPoints,
      contractMade: contractMade,
      tricksOver: contractMade ? contractorTricks - contract.tricks : 0,
      tricksUnder: contractMade ? 0 : contract.tricks - contractorTricks,
      isSlam: isSlam,
    );
  }

  /// Check if game is over and determine winner/loser
  static GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
  }) {
    if (kDebugMode) {
      debugPrint('\n[SCORER] Checking game over status');
      debugPrint('  North-South score: $teamNSScore');
      debugPrint('  East-West score: $teamEWScore');
    }

    // Check for wins (500+)
    if (teamNSScore >= 500 && teamEWScore >= 500) {
      // Both teams reached 500+ - highest score wins
      if (teamNSScore > teamEWScore) {
        if (kDebugMode) {
          debugPrint(
            '  GAME OVER: Both teams reached 500+, North-South wins ($teamNSScore > $teamEWScore)',
          );
        }
        return GameOverStatus.teamNSWins;
      } else {
        if (kDebugMode) {
          debugPrint(
            '  GAME OVER: Both teams reached 500+, East-West wins ($teamEWScore > $teamNSScore)',
          );
        }
        return GameOverStatus.teamEWWins;
      }
    }

    if (teamNSScore >= 500) {
      if (kDebugMode) {
        debugPrint('  GAME OVER: North-South reaches 500+ ($teamNSScore)');
      }
      return GameOverStatus.teamNSWins;
    }

    if (teamEWScore >= 500) {
      if (kDebugMode) {
        debugPrint('  GAME OVER: East-West reaches 500+ ($teamEWScore)');
      }
      return GameOverStatus.teamEWWins;
    }

    // Check for losses (-500 or below)
    if (teamNSScore <= -500) {
      if (kDebugMode) {
        debugPrint(
          '  GAME OVER: North-South drops to -500 or below ($teamNSScore)',
        );
      }
      return GameOverStatus.teamNSLoses;
    }

    if (teamEWScore <= -500) {
      if (kDebugMode) {
        debugPrint(
          '  GAME OVER: East-West drops to -500 or below ($teamEWScore)',
        );
      }
      return GameOverStatus.teamEWLoses;
    }

    // Game continues
    if (kDebugMode) {
      debugPrint('  Game continues (no win/lose condition met)');
    }
    return null;
  }

  /// Get a description of the hand result
  static String getHandResultDescription({
    required Bid contract,
    required HandScore score,
    required Team contractorTeam,
  }) {
    final contractorName = _teamName(contractorTeam);

    if (score.contractMade) {
      if (score.isSlam) {
        return '$contractorName SLAM! Won all 10 tricks (+${score.contractorPoints})';
      } else if (score.tricksOver == 0) {
        return '$contractorName made ${contract.tricks}${_suitLabel(contract.suit)} exactly (+${score.contractorPoints})';
      } else {
        return '$contractorName made ${contract.tricks}${_suitLabel(contract.suit)} with ${score.tricksOver} overtrick(s) (+${score.contractorPoints})';
      }
    } else {
      return '$contractorName failed ${contract.tricks}${_suitLabel(contract.suit)} by ${score.tricksUnder} trick(s) (${score.contractorPoints})';
    }
  }

  /// Get game over message
  static String getGameOverMessage(
    GameOverStatus status,
    int scoreNS,
    int scoreEW,
  ) {
    switch (status) {
      case GameOverStatus.teamNSWins:
        return 'Team North-South wins! Final score: $scoreNS to $scoreEW';
      case GameOverStatus.teamEWWins:
        return 'Team East-West wins! Final score: $scoreEW to $scoreNS';
      case GameOverStatus.teamNSLoses:
        return 'Team North-South loses (score below -500). East-West wins!';
      case GameOverStatus.teamEWLoses:
        return 'Team East-West loses (score below -500). North-South wins!';
    }
  }

  static String _teamName(Team team) {
    switch (team) {
      case Team.northSouth:
        return 'North-South';
      case Team.eastWest:
        return 'East-West';
    }
  }

  static String _suitLabel(BidSuit suit) {
    switch (suit) {
      case BidSuit.spades:
        return '♠';
      case BidSuit.clubs:
        return '♣';
      case BidSuit.diamonds:
        return '♦';
      case BidSuit.hearts:
        return '♥';
      case BidSuit.noTrump:
        return 'NT';
    }
  }
}

/// Result of scoring a hand
class HandScore {
  const HandScore({
    required this.contractorPoints,
    required this.opponentPoints,
    required this.contractMade,
    required this.tricksOver,
    required this.tricksUnder,
    this.isSlam = false,
  });

  final int contractorPoints; // + or - bid value (or 250 for slam)
  final int opponentPoints; // 10 per trick
  final bool contractMade;
  final int tricksOver; // Overtricks (if contract made)
  final int tricksUnder; // Undertricks (if contract failed)
  final bool isSlam; // True if contractor won all 10 tricks

  @override
  String toString() {
    if (contractMade) {
      if (isSlam) {
        return 'SLAM! +$contractorPoints (contractors), +$opponentPoints (opponents)';
      }
      return 'Contract made: +$contractorPoints (contractors), +$opponentPoints (opponents)';
    } else {
      return 'Contract failed: $contractorPoints (contractors), +$opponentPoints (opponents)';
    }
  }
}

/// Game over status
enum GameOverStatus {
  teamNSWins, // North-South reached 500+
  teamEWWins, // East-West reached 500+
  teamNSLoses, // North-South at -500 or below
  teamEWLoses, // East-West at -500 or below
}
