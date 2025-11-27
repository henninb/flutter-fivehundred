import 'dart:math';
import '../models/card.dart';
import '../models/game_models.dart';
import 'trump_rules.dart';

/// Basic AI for bidding in 500
///
/// Strategy:
/// - Evaluate hand strength in each suit
/// - Count likely tricks based on high cards and trump length
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
      BidSuit.spades: _evaluateSuit(hand, Suit.spades),
      BidSuit.clubs: _evaluateSuit(hand, Suit.clubs),
      BidSuit.diamonds: _evaluateSuit(hand, Suit.diamonds),
      BidSuit.hearts: _evaluateSuit(hand, Suit.hearts),
      BidSuit.noTrump: _evaluateNoTrump(hand),
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
    // Conservative: only bid if we estimate at least 1 trick above minimum
    if (estimatedTricks < 6) {
      return BidDecision.pass(reasoning: 'Hand too weak (estimated $estimatedTricks tricks)');
    }

    // Check if we should inkle
    if (canInkle && estimatedTricks == 6) {
      final inkleBid = Bid(tricks: 6, suit: bestSuit, bidder: position);
      return BidDecision.inkle(
        bid: inkleBid,
        reasoning: 'Inkle with $bestSuit (estimated $estimatedTricks tricks)',
      );
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
        return BidDecision.pass(
          reasoning: 'Cannot beat current bid of ${currentHighBid.tricks}${_suitLabel(currentHighBid.suit)}',
        );
      }

      return BidDecision.bid(
        bid: minBeatingBid,
        reasoning: 'Bidding ${minBeatingBid.tricks}${_suitLabel(minBeatingBid.suit)} (estimated ${evaluations[minBeatingBid.suit]!.estimatedTricks.toStringAsFixed(1)} tricks)',
      );
    }

    // No competition or we can beat it - bid our best
    return BidDecision.bid(
      bid: ourBid,
      reasoning: 'Bidding $estimatedTricks$bestSuit (${bestEval.trumpCount} trumps)',
    );
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

      // Can we make this bid? (conservative: need to estimate at least that many tricks)
      if (eval.estimatedTricks >= currentHighBid.tricks) {
        return Bid(tricks: currentHighBid.tricks, suit: suit, bidder: bidder);
      }
    }

    // Need to bid higher level - check if we can make it
    for (int tricks = currentHighBid.tricks + 1; tricks <= 10; tricks++) {
      for (final suit in BidSuit.values) {
        final eval = evaluations[suit]!;
        if (eval.estimatedTricks >= tricks) {
          return Bid(tricks: tricks, suit: suit, bidder: bidder);
        }
      }
    }

    return null; // Can't beat it
  }

  /// Evaluate hand strength for a specific trump suit
  static SuitEvaluation _evaluateSuit(List<PlayingCard> hand, Suit trumpSuit) {
    final trumpRules = TrumpRules(trumpSuit: trumpSuit);
    final trumpCards = trumpRules.getTrumpCards(hand);
    final nonTrumpCards = trumpRules.getNonTrumpCards(hand);

    double trickCount = 0;

    // Count trump tricks
    // Joker = 1 trick
    if (trumpCards.any((c) => c.isJoker)) {
      trickCount += 1.0;
    }

    // Right bower = 0.9 tricks
    if (trumpCards.any((c) => trumpRules.isRightBower(c))) {
      trickCount += 0.9;
    }

    // Left bower = 0.8 tricks
    if (trumpCards.any((c) => trumpRules.isLeftBower(c))) {
      trickCount += 0.8;
    }

    // Trump ace/king/queen
    final trumpAces = trumpCards.where((c) => c.rank == Rank.ace).length;
    final trumpKings = trumpCards.where((c) => c.rank == Rank.king).length;
    final trumpQueens = trumpCards.where((c) => c.rank == Rank.queen).length;

    trickCount += trumpAces * 0.8;
    trickCount += trumpKings * 0.5;
    trickCount += trumpQueens * 0.3;

    // Trump length bonus (more trumps = more control)
    if (trumpCards.length >= 5) {
      trickCount += 0.5;
    } else if (trumpCards.length >= 7) {
      trickCount += 1.0;
    }

    // Side suit winners (aces and kings in non-trump suits)
    for (final suit in Suit.values) {
      if (suit == trumpSuit) continue;

      final suitCards = nonTrumpCards.where((c) => c.suit == suit).toList();
      if (suitCards.isEmpty) continue;

      // Ace is likely a winner
      if (suitCards.any((c) => c.rank == Rank.ace)) {
        trickCount += 0.7;
      }

      // King might be a winner
      if (suitCards.any((c) => c.rank == Rank.king)) {
        trickCount += 0.3;
      }
    }

    return SuitEvaluation(
      suit: trumpSuit,
      trumpCount: trumpCards.length,
      estimatedTricks: trickCount,
      hasJoker: trumpCards.any((c) => c.isJoker),
      hasRightBower: trumpCards.any((c) => trumpRules.isRightBower(c)),
      hasLeftBower: trumpCards.any((c) => trumpRules.isLeftBower(c)),
    );
  }

  /// Evaluate hand for no-trump
  static SuitEvaluation _evaluateNoTrump(List<PlayingCard> hand) {
    double trickCount = 0;

    // Joker = 1 trick (always highest)
    if (hand.any((c) => c.isJoker)) {
      trickCount += 1.0;
    }

    // Count high cards in each suit
    for (final suit in Suit.values) {
      final suitCards = hand.where((c) => c.suit == suit && !c.isJoker).toList();
      if (suitCards.isEmpty) continue;

      // Aces are winners
      final aces = suitCards.where((c) => c.rank == Rank.ace).length;
      trickCount += aces * 0.9;

      // Kings likely winners if we have length
      final kings = suitCards.where((c) => c.rank == Rank.king).length;
      if (suitCards.length >= 3) {
        trickCount += kings * 0.6;
      } else {
        trickCount += kings * 0.3;
      }

      // Queens in long suits
      final queens = suitCards.where((c) => c.rank == Rank.queen).length;
      if (suitCards.length >= 4) {
        trickCount += queens * 0.4;
      }
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
