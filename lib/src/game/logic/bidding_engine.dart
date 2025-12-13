import 'package:flutter/foundation.dart';

import '../models/game_models.dart';

/// Manages the bidding auction for 500 (American variant)
///
/// American variant rules:
/// - One round of bidding only (each player bids once)
/// - First two players (dealer's left and partner) can bid 6 (inkle)
/// - Inkle cannot win auction (auction must reach level 7)
/// - If no one bids 7+, cards are reshuffled and redealt
/// - Bidding order: dealer's left, then clockwise
class BiddingEngine {
  BiddingEngine({required this.dealer});

  final Position dealer;

  /// Get the bidding order starting from dealer's left
  List<Position> getBiddingOrder() {
    final order = <Position>[];
    var current = dealer.next; // Start with player to dealer's left
    for (int i = 0; i < 4; i++) {
      order.add(current);
      current = current.next;
    }
    return order;
  }

  /// Check if a player can inkle (bid 6)
  /// Only the first two players in bidding order can inkle
  bool canInkle(Position bidder, List<BidEntry> currentBids) {
    final biddingOrder = getBiddingOrder();
    final bidderIndex = biddingOrder.indexOf(bidder);

    // Only first two bidders can inkle
    if (bidderIndex > 1) return false;

    // Can only inkle if this is their first bid
    final alreadyBid = currentBids.any((entry) => entry.bidder == bidder);
    return !alreadyBid;
  }

  /// Check if a bid is valid given the current state
  BidValidation validateBid({
    required Position bidder,
    required Bid? proposedBid,
    required List<BidEntry> currentBids,
    required bool isInkle,
  }) {
    // Pass is always valid
    if (proposedBid == null) {
      return BidValidation.valid();
    }

    // Check if already bid
    final alreadyBid = currentBids.any((entry) => entry.bidder == bidder);
    if (alreadyBid) {
      return BidValidation.invalid('You have already bid this round');
    }

    // Check if inkle is allowed
    if (isInkle) {
      if (!canInkle(bidder, currentBids)) {
        return BidValidation.invalid('Only the first two players can inkle');
      }
      if (proposedBid.tricks != 6) {
        return BidValidation.invalid('Inkle must be a bid of 6');
      }
      return BidValidation.valid();
    }

    // Check if bid is high enough
    final currentHighBid = getHighestBid(currentBids);
    if (currentHighBid != null && !proposedBid.beats(currentHighBid)) {
      return BidValidation.invalid(
        'Bid must beat current high bid of ${currentHighBid.tricks}${_suitLabel(currentHighBid.suit)}',
      );
    }

    return BidValidation.valid();
  }

  /// Get the highest bid so far (excluding inkles)
  Bid? getHighestBid(List<BidEntry> bids) {
    Bid? highest;
    for (final entry in bids) {
      if (entry.bid != null && !entry.isInkle) {
        if (highest == null || entry.bid!.beats(highest)) {
          highest = entry.bid;
        }
      }
    }
    return highest;
  }

  /// Get the highest inkle bid (if any)
  Bid? getHighestInkle(List<BidEntry> bids) {
    Bid? highest;
    for (final entry in bids) {
      if (entry.bid != null && entry.isInkle) {
        if (highest == null || entry.bid!.beats(highest)) {
          highest = entry.bid;
        }
      }
    }
    return highest;
  }

  /// Determine auction result after all players have bid
  AuctionResult determineWinner(List<BidEntry> bids) {
    if (kDebugMode) {
      debugPrint('\n[BIDDING ENGINE] Determining auction winner');
      debugPrint('  Total bids received: ${bids.length}');
    }

    // Must have 4 bids (one per player)
    if (bids.length != 4) {
      final message = 'Waiting for ${4 - bids.length} more bid(s)';
      if (kDebugMode) {
        debugPrint('  Result: INCOMPLETE - $message');
      }
      return AuctionResult.incomplete(message: message);
    }

    final highestBid = getHighestBid(bids);
    final highestInkle = getHighestInkle(bids);

    if (kDebugMode) {
      debugPrint(
        '  Highest bid: ${highestBid != null ? '${highestBid.tricks}${_suitLabel(highestBid.suit)} by ${highestBid.bidder.name}' : 'none'}',
      );
      debugPrint(
        '  Highest inkle: ${highestInkle != null ? '${highestInkle.tricks}${_suitLabel(highestInkle.suit)} by ${highestInkle.bidder.name}' : 'none'}',
      );
    }

    // If there's a valid bid (7+), that wins
    if (highestBid != null && highestBid.tricks >= 7) {
      final message =
          '${highestBid.bidder.name} wins with ${highestBid.tricks}${_suitLabel(highestBid.suit)}';
      if (kDebugMode) {
        debugPrint('  Result: WON - $message');
      }
      return AuctionResult.winner(
        winningBid: highestBid,
        message: message,
      );
    }

    // Only inkles (no bid 7+) - need to redeal
    if (highestInkle != null && highestBid == null) {
      const message = 'Only inkles bid - redeal required';
      if (kDebugMode) {
        debugPrint('  Result: REDEAL - $message');
      }
      return AuctionResult.redeal(message: message);
    }

    // No bids at all - redeal
    if (highestBid == null && highestInkle == null) {
      const message = 'No bids - redeal required';
      if (kDebugMode) {
        debugPrint('  Result: REDEAL - $message');
      }
      return AuctionResult.redeal(message: message);
    }

    // Highest bid is 6 but not inkle - redeal
    if (highestBid != null && highestBid.tricks == 6) {
      const message = 'Auction must reach level 7 - redeal required';
      if (kDebugMode) {
        debugPrint('  Result: REDEAL - $message');
      }
      return AuctionResult.redeal(message: message);
    }

    // Should not reach here, but just in case
    const message = 'Invalid auction state - redeal required';
    if (kDebugMode) {
      debugPrint('  Result: REDEAL (UNEXPECTED) - $message');
      debugPrint('  ⚠️  WARNING: Reached unexpected auction state!');
    }
    return AuctionResult.redeal(message: message);
  }

  /// Check if auction is complete (all 4 players have bid)
  bool isComplete(List<BidEntry> bids) {
    return bids.length == 4;
  }

  /// Get next bidder in order
  Position? getNextBidder(List<BidEntry> bids) {
    if (isComplete(bids)) return null;

    final biddingOrder = getBiddingOrder();
    return biddingOrder[bids.length];
  }

  String _suitLabel(BidSuit suit) {
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

/// Result of bid validation
class BidValidation {
  const BidValidation._({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;

  factory BidValidation.valid() => const BidValidation._(isValid: true);
  factory BidValidation.invalid(String message) =>
      BidValidation._(isValid: false, errorMessage: message);
}

/// Result of the auction
class AuctionResult {
  const AuctionResult._({
    required this.status,
    this.winningBid,
    required this.message,
  });

  final AuctionStatus status;
  final Bid? winningBid;
  final String message;

  Position? get winner => winningBid?.bidder;

  factory AuctionResult.winner({
    required Bid winningBid,
    required String message,
  }) =>
      AuctionResult._(
        status: AuctionStatus.won,
        winningBid: winningBid,
        message: message,
      );

  factory AuctionResult.redeal({required String message}) => AuctionResult._(
        status: AuctionStatus.redeal,
        message: message,
      );

  factory AuctionResult.incomplete({required String message}) =>
      AuctionResult._(
        status: AuctionStatus.incomplete,
        message: message,
      );
}

enum AuctionStatus {
  incomplete, // Still waiting for bids
  won, // Someone won the auction
  redeal, // Need to redeal
}
