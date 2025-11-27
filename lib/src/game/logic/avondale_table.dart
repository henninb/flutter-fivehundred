import '../models/game_models.dart';

/// The Avondale Scoring Table for 500
///
/// This is the official scoring table used in the game of 500, introduced
/// by the US Playing Card Company in 1906 to remove bidding irregularities.
///
/// The table shows the point value for each possible bid (6-10 tricks in
/// each suit and no-trump). The suit order from lowest to highest is:
/// Spades < Clubs < Diamonds < Hearts < No Trump
class AvondaleTable {
  // Private constructor to prevent instantiation
  AvondaleTable._();

  /// The official Avondale scoring table
  static const Map<int, Map<BidSuit, int>> _bidValues = {
    6: {
      BidSuit.spades: 40,
      BidSuit.clubs: 60,
      BidSuit.diamonds: 80,
      BidSuit.hearts: 100,
      BidSuit.noTrump: 120,
    },
    7: {
      BidSuit.spades: 140,
      BidSuit.clubs: 160,
      BidSuit.diamonds: 180,
      BidSuit.hearts: 200,
      BidSuit.noTrump: 220,
    },
    8: {
      BidSuit.spades: 240,
      BidSuit.clubs: 260,
      BidSuit.diamonds: 280,
      BidSuit.hearts: 300,
      BidSuit.noTrump: 320,
    },
    9: {
      BidSuit.spades: 340,
      BidSuit.clubs: 360,
      BidSuit.diamonds: 380,
      BidSuit.hearts: 400,
      BidSuit.noTrump: 420,
    },
    10: {
      BidSuit.spades: 440,
      BidSuit.clubs: 460,
      BidSuit.diamonds: 480,
      BidSuit.hearts: 500,
      BidSuit.noTrump: 520,
    },
  };

  /// Get the point value for a bid
  ///
  /// Returns 0 if the bid is invalid (e.g., tricks < 6 or > 10)
  static int getBidValue(int tricks, BidSuit suit) {
    return _bidValues[tricks]?[suit] ?? 0;
  }

  /// Get the point value from a Bid object
  static int getBidValueFromBid(Bid bid) {
    return getBidValue(bid.tricks, bid.suit);
  }

  /// Check if a bid is valid (6-10 tricks)
  static bool isValidBid(int tricks) {
    return tricks >= 6 && tricks <= 10;
  }

  /// Get all valid bids in order of value
  static List<Bid> getAllBidsInOrder(Position bidder) {
    final bids = <Bid>[];
    for (int tricks = 6; tricks <= 10; tricks++) {
      for (final suit in BidSuit.values) {
        bids.add(Bid(tricks: tricks, suit: suit, bidder: bidder));
      }
    }
    // Sort by value
    bids.sort((a, b) => a.value.compareTo(b.value));
    return bids;
  }

  /// Get the minimum bid that beats a given bid
  static Bid? getMinimumBeatBid(Bid currentBid, Position bidder) {
    // Try higher suits at same trick level first
    for (int suitIndex = currentBid.suit.index + 1;
        suitIndex < BidSuit.values.length;
        suitIndex++) {
      final bid =
          Bid(tricks: currentBid.tricks, suit: BidSuit.values[suitIndex], bidder: bidder);
      if (bid.beats(currentBid)) return bid;
    }

    // Otherwise, need more tricks
    if (currentBid.tricks < 10) {
      return Bid(
        tricks: currentBid.tricks + 1,
        suit: BidSuit.spades, // Lowest suit at next level
        bidder: bidder,
      );
    }

    // No higher bid possible
    return null;
  }
}
