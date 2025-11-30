import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import 'trump_rules.dart';

/// Basic AI for bidding in 500
///
/// Strategy:
/// - Evaluate hand strength in each suit using advanced heuristics
/// - Count likely tricks based on high cards, trump length, and distribution
/// - Consider trump quality, side suit strength, and hand shape
/// - Bid conservatively (won't overbid)
/// - Considers position but doesn't model partner's hand
class BiddingAI {
  BiddingAI._();

  /// Decide what to bid given current hand and auction state
  static BidDecision chooseBid({
    required List<PlayingCard> hand,
    required List<BidEntry> currentBids,
    required Position position,
    required bool canInkle,
  }) {
    // Evaluate hand for each suit
    final evaluations = {
      BidSuit.spades: evaluateSuit(hand, Suit.spades),
      BidSuit.clubs: evaluateSuit(hand, Suit.clubs),
      BidSuit.diamonds: evaluateSuit(hand, Suit.diamonds),
      BidSuit.hearts: evaluateSuit(hand, Suit.hearts),
      BidSuit.noTrump: evaluateNoTrump(hand),
    };

    // Find best suit
    BidSuit bestSuit = BidSuit.spades;
    double bestStrength = evaluations[BidSuit.spades]!.estimatedTricks;

    for (final entry in evaluations.entries) {
      if (entry.value.estimatedTricks > bestStrength) {
        bestSuit = entry.key;
        bestStrength = entry.value.estimatedTricks;
      }
    }

    final bestEval = evaluations[bestSuit]!;
    final estimatedTricks = bestEval.estimatedTricks.round();

    // Get current high bid
    Bid? currentHighBid;
    for (final entry in currentBids) {
      if (entry.bid != null && !entry.isInkle) {
        if (currentHighBid == null || entry.bid!.beats(currentHighBid)) {
          currentHighBid = entry.bid;
        }
      }
    }

    // Decide whether to bid
    // More aggressive: bid with 5.5+ estimated tricks (accounts for partner's help)
    if (estimatedTricks < 5.5) {
      final decision = BidDecision.pass(reasoning: 'Hand too weak (estimated $estimatedTricks tricks)');
      if (kDebugMode) {
        debugPrint('[AI BIDDING] ${position.name}: PASS - ${decision.reasoning}');
      }
      return decision;
    }

    // Check if we should inkle
    if (canInkle && estimatedTricks >= 5.5 && estimatedTricks <= 6.5) {
      final inkleBid = Bid(tricks: 6, suit: bestSuit, bidder: position);
      final decision = BidDecision.inkle(
        bid: inkleBid,
        reasoning: 'Inkle with $bestSuit (estimated $estimatedTricks tricks)',
      );
      if (kDebugMode) {
        debugPrint('[AI BIDDING] ${position.name}: INKLE 6${_suitLabel(bestSuit)} - ${decision.reasoning}');
      }
      return decision;
    }

    // Can we beat current high bid?
    final ourBid = Bid(
      tricks: min(estimatedTricks, 10),
      suit: bestSuit,
      bidder: position,
    );

    if (currentHighBid != null && !ourBid.beats(currentHighBid)) {
      // Try to find a bid that beats it
      final minBeatingBid = _findMinimumBeatingBid(
        currentHighBid: currentHighBid,
        evaluations: evaluations,
        bidder: position,
      );

      if (minBeatingBid == null) {
        final decision = BidDecision.pass(
          reasoning: 'Cannot beat current bid of ${currentHighBid.tricks}${_suitLabel(currentHighBid.suit)}',
        );
        if (kDebugMode) {
          debugPrint('[AI BIDDING] ${position.name}: PASS - ${decision.reasoning}');
        }
        return decision;
      }

      final decision = BidDecision.bid(
        bid: minBeatingBid,
        reasoning: 'Bidding ${minBeatingBid.tricks}${_suitLabel(minBeatingBid.suit)} (estimated ${evaluations[minBeatingBid.suit]!.estimatedTricks.toStringAsFixed(1)} tricks)',
      );
      if (kDebugMode) {
        debugPrint('[AI BIDDING] ${position.name}: BID ${minBeatingBid.tricks}${_suitLabel(minBeatingBid.suit)} - ${decision.reasoning}');
      }
      return decision;
    }

    // No competition or we can beat it - bid our best
    final decision = BidDecision.bid(
      bid: ourBid,
      reasoning: 'Bidding $estimatedTricks$bestSuit (${bestEval.trumpCount} trumps)',
    );
    if (kDebugMode) {
      debugPrint('[AI BIDDING] ${position.name}: BID $estimatedTricks${_suitLabel(bestSuit)} - ${decision.reasoning}');
    }
    return decision;
  }

  /// Find minimum bid that beats current high bid and we can make
  static Bid? _findMinimumBeatingBid({
    required Bid currentHighBid,
    required Map<BidSuit, SuitEvaluation> evaluations,
    required Position bidder,
  }) {
    // Try higher suits at same level first
    for (int suitIndex = currentHighBid.suit.index + 1;
        suitIndex < BidSuit.values.length;
        suitIndex++) {
      final suit = BidSuit.values[suitIndex];
      final eval = evaluations[suit]!;

      // More aggressive: allow bidding with 0.5 tricks less (partner will contribute)
      if (eval.estimatedTricks >= currentHighBid.tricks - 0.5) {
        return Bid(tricks: currentHighBid.tricks, suit: suit, bidder: bidder);
      }
    }

    // Need to bid higher level - check if we can make it
    for (int tricks = currentHighBid.tricks + 1; tricks <= 10; tricks++) {
      for (final suit in BidSuit.values) {
        final eval = evaluations[suit]!;
        // More aggressive: allow bidding with 0.5 tricks less
        if (eval.estimatedTricks >= tricks - 0.5) {
          return Bid(tricks: tricks, suit: suit, bidder: bidder);
        }
      }
    }

    return null; // Can't beat it
  }

  /// Evaluate hand strength for a specific trump suit
  static SuitEvaluation evaluateSuit(List<PlayingCard> hand, Suit trumpSuit) {
    final trumpRules = TrumpRules(trumpSuit: trumpSuit);
    final trumpCards = trumpRules.getTrumpCards(hand);
    final nonTrumpCards = trumpRules.getNonTrumpCards(hand);

    double trickCount = 0;

    // === TRUMP EVALUATION ===

    // Count top trump honors
    final hasJoker = trumpCards.any((c) => c.isJoker);
    final hasRightBower = trumpCards.any((c) => trumpRules.isRightBower(c));
    final hasLeftBower = trumpCards.any((c) => trumpRules.isLeftBower(c));

    // Individual trump honors (base value) - increased for aggression
    if (hasJoker) trickCount += 1.1;
    if (hasRightBower) trickCount += 1.0;
    if (hasLeftBower) trickCount += 0.9;

    // Trump honor combination bonuses (these combinations are very powerful)
    if (hasJoker && hasRightBower) {
      trickCount += 0.4; // Top two trumps guarantee 2 tricks
    }
    if (hasJoker && hasRightBower && hasLeftBower) {
      trickCount += 0.5; // Top three trumps is devastating
    }

    // Trump ace/king/queen (adjusted for context)
    final trumpAces = trumpCards.where((c) => c.rank == Rank.ace && !trumpRules.isRightBower(c) && !trumpRules.isLeftBower(c)).length;
    final trumpKings = trumpCards.where((c) => c.rank == Rank.king && !trumpRules.isRightBower(c) && !trumpRules.isLeftBower(c)).length;
    final trumpQueens = trumpCards.where((c) => c.rank == Rank.queen && !trumpRules.isRightBower(c) && !trumpRules.isLeftBower(c)).length;

    // Trump ace value depends on whether we have top honors
    if (trumpAces > 0) {
      if (hasJoker || hasRightBower || hasLeftBower) {
        trickCount += trumpAces * 0.7; // Protected by higher trumps
      } else {
        trickCount += trumpAces * 0.5; // Might get trumped
      }
    }

    // Trump king/queen are less valuable without support
    if (trumpKings > 0) {
      if ((hasJoker ? 1 : 0) + (hasRightBower ? 1 : 0) + (hasLeftBower ? 1 : 0) + trumpAces >= 2) {
        trickCount += trumpKings * 0.4; // Well protected
      } else {
        trickCount += trumpKings * 0.2;
      }
    }

    trickCount += trumpQueens * 0.15; // Queens rarely take tricks

    // Trump length evaluation (more aggressive)
    final trumpLength = trumpCards.length;
    if (trumpLength >= 7) {
      trickCount += 1.5; // Extremely long trumps
    } else if (trumpLength >= 6) {
      trickCount += 1.0; // Very long trumps
    } else if (trumpLength >= 5) {
      trickCount += 0.7; // Good trump length
    } else if (trumpLength >= 4) {
      trickCount += 0.3; // Adequate trumps
    } else if (trumpLength <= 2) {
      trickCount -= 0.2; // Less penalty for short trumps
    }

    // === SIDE SUIT EVALUATION ===

    // Analyze each side suit
    final suitDistribution = <Suit, List<PlayingCard>>{};
    for (final suit in Suit.values) {
      suitDistribution[suit] = nonTrumpCards.where((c) => c.suit == suit).toList();
    }

    // Count voids and singletons (valuable with trumps)
    final voids = suitDistribution.values.where((cards) => cards.isEmpty).length;
    final singletons = suitDistribution.values.where((cards) => cards.length == 1).length;

    if (trumpLength >= 4) {
      trickCount += voids * 0.8; // Can ruff multiple times
      trickCount += singletons * 0.4; // Can ruff after one round
    }

    // Evaluate side suit winners
    for (final entry in suitDistribution.entries) {
      final suitCards = entry.value;

      if (suitCards.isEmpty) continue;

      final hasAce = suitCards.any((c) => c.rank == Rank.ace);
      final hasKing = suitCards.any((c) => c.rank == Rank.king);
      final hasQueen = suitCards.any((c) => c.rank == Rank.queen);
      final suitLength = suitCards.length;

      // Ace evaluation
      if (hasAce) {
        if (suitLength >= 3) {
          trickCount += 0.85; // Likely winner with length
        } else if (suitLength == 2) {
          trickCount += 0.75; // Probably a winner
        } else {
          trickCount += 0.6; // Singleton ace, might get trumped
        }
      }

      // King evaluation (more nuanced)
      if (hasKing) {
        if (hasAce && suitLength >= 3) {
          trickCount += 0.7; // AK combination in long suit
        } else if (hasAce) {
          trickCount += 0.5; // AK in short suit
        } else if (suitLength >= 4) {
          trickCount += 0.4; // King in long suit without ace
        } else {
          trickCount += 0.15; // Unprotected king
        }
      }

      // Queen evaluation (mostly useful in sequences)
      if (hasQueen) {
        if (hasAce && hasKing && suitLength >= 3) {
          trickCount += 0.5; // AKQ sequence
        } else if ((hasAce || hasKing) && suitLength >= 4) {
          trickCount += 0.25; // Might promote in long suit
        }
        // Otherwise queen is unlikely to take a trick
      }

      // Long suit potential (small cards in long suits can become winners)
      if (suitLength >= 5 && (hasAce || hasKing)) {
        trickCount += 0.3; // Long suit establishment potential
      }
    }

    return SuitEvaluation(
      suit: trumpSuit,
      trumpCount: trumpCards.length,
      estimatedTricks: trickCount,
      hasJoker: hasJoker,
      hasRightBower: hasRightBower,
      hasLeftBower: hasLeftBower,
    );
  }

  /// Evaluate hand for no-trump
  static SuitEvaluation evaluateNoTrump(List<PlayingCard> hand) {
    double trickCount = 0;

    // Joker = 1 trick (always highest)
    if (hand.any((c) => c.isJoker)) {
      trickCount += 1.0;
    }

    // Count high cards in each suit
    for (final suit in Suit.values) {
      final suitCards = hand.where((c) => c.suit == suit && !c.isJoker).toList()
        ..sort((a, b) => b.rank.index.compareTo(a.rank.index)); // Sort high to low

      if (suitCards.isEmpty) continue;

      final suitLength = suitCards.length;
      final hasAce = suitCards.any((c) => c.rank == Rank.ace);
      final hasKing = suitCards.any((c) => c.rank == Rank.king);
      final hasQueen = suitCards.any((c) => c.rank == Rank.queen);
      final hasJack = suitCards.any((c) => c.rank == Rank.jack);

      // Aces are strong winners in NT
      if (hasAce) {
        trickCount += 0.95;
      }

      // Kings are good if suit has length
      if (hasKing) {
        if (hasAce && suitLength >= 3) {
          trickCount += 0.8; // AK in decent suit
        } else if (hasAce) {
          trickCount += 0.6; // AK doubleton
        } else if (suitLength >= 4) {
          trickCount += 0.5; // King in long suit
        } else {
          trickCount += 0.25; // Unprotected king
        }
      }

      // Queens need support
      if (hasQueen) {
        if (hasAce && hasKing) {
          trickCount += 0.6; // AKQ sequence
        } else if ((hasAce || hasKing) && suitLength >= 4) {
          trickCount += 0.35; // Queen in long suit with one high honor
        } else if (suitLength >= 5) {
          trickCount += 0.2; // Might promote in very long suit
        }
      }

      // Jacks in strong sequences
      if (hasJack && hasAce && hasKing && hasQueen && suitLength >= 4) {
        trickCount += 0.3; // AKQJ is very strong
      }

      // Long suit tricks (5th and 6th cards can become winners in NT)
      if (suitLength >= 5 && (hasAce || hasKing)) {
        trickCount += 0.4 * (suitLength - 4); // Each extra card adds value
      }
    }

    // Balanced hand bonus for NT (prefer 4-3-3-3 or 4-4-3-2 distributions)
    final suitLengths = Suit.values
        .map((s) => hand.where((c) => c.suit == s && !c.isJoker).length)
        .toList()
      ..sort();

    // Penalty for very unbalanced hands (singletons/voids are bad in NT)
    if (suitLengths[0] == 0) {
      trickCount -= 1.0; // Void is very bad in NT
    } else if (suitLengths[0] == 1) {
      trickCount -= 0.5; // Singleton is risky in NT
    }

    // Small bonus for balanced distribution
    if (suitLengths[0] >= 2 && suitLengths[3] <= 5) {
      trickCount += 0.3; // Balanced hand
    }

    return SuitEvaluation(
      suit: null, // No trump
      trumpCount: hand.any((c) => c.isJoker) ? 1 : 0,
      estimatedTricks: trickCount,
      hasJoker: hand.any((c) => c.isJoker),
      hasRightBower: false,
      hasLeftBower: false,
    );
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

/// Result of hand evaluation for a suit
class SuitEvaluation {
  const SuitEvaluation({
    required this.suit,
    required this.trumpCount,
    required this.estimatedTricks,
    required this.hasJoker,
    required this.hasRightBower,
    required this.hasLeftBower,
  });

  final Suit? suit; // null for no-trump
  final int trumpCount;
  final double estimatedTricks;
  final bool hasJoker;
  final bool hasRightBower;
  final bool hasLeftBower;
}

/// AI's bidding decision
class BidDecision {
  const BidDecision._({
    required this.action,
    this.bid,
    required this.reasoning,
  });

  final BidAction action;
  final Bid? bid;
  final String reasoning;

  factory BidDecision.pass({required String reasoning}) =>
      BidDecision._(action: BidAction.pass, reasoning: reasoning);

  factory BidDecision.bid({required Bid bid, required String reasoning}) =>
      BidDecision._(action: BidAction.bid, bid: bid, reasoning: reasoning);

  factory BidDecision.inkle({required Bid bid, required String reasoning}) =>
      BidDecision._(action: BidAction.inkle, bid: bid, reasoning: reasoning);
}
