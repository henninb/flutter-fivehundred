import 'card.dart';
import '../logic/avondale_table.dart';

// Extends Suit enum to include no-trump for bidding
enum BidSuit { spades, clubs, diamonds, hearts, noTrump }

// Player positions around the table (South is human player)
enum Position { north, south, east, west }

// Teams in 500 (North-South vs East-West)
enum Team { northSouth, eastWest }

// Extension to get team from position
extension PositionExt on Position {
  Team get team {
    switch (this) {
      case Position.north:
      case Position.south:
        return Team.northSouth;
      case Position.east:
      case Position.west:
        return Team.eastWest;
    }
  }

  Position get partner {
    switch (this) {
      case Position.north:
        return Position.south;
      case Position.south:
        return Position.north;
      case Position.east:
        return Position.west;
      case Position.west:
        return Position.east;
    }
  }

  // Get next player clockwise
  Position get next {
    switch (this) {
      case Position.north:
        return Position.east;
      case Position.east:
        return Position.south;
      case Position.south:
        return Position.west;
      case Position.west:
        return Position.north;
    }
  }
}

// A bid in the auction
class Bid {
  const Bid({
    required this.tricks,
    required this.suit,
    required this.bidder,
  });

  final int tricks; // 6-10
  final BidSuit suit;
  final Position bidder;

  // Get bid value from Avondale table
  int get value => AvondaleTable.getBidValue(tricks, suit);

  // Check if this bid beats another bid
  bool beats(Bid other) {
    if (tricks > other.tricks) return true;
    if (tricks < other.tricks) return false;
    // Same trick count, compare suits
    return suit.index > other.suit.index;
  }

  @override
  String toString() => '$tricks${_suitLabel(suit)} by ${bidder.name}';

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bid &&
        other.tricks == tricks &&
        other.suit == suit &&
        other.bidder == bidder;
  }

  @override
  int get hashCode => tricks.hashCode ^ suit.hashCode ^ bidder.hashCode;
}

// A card played by a player in a trick
class CardPlay {
  const CardPlay({
    required this.card,
    required this.player,
  });

  final PlayingCard card;
  final Position player;

  @override
  String toString() => '$card by ${player.name}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardPlay && other.card == card && other.player == player;
  }

  @override
  int get hashCode => card.hashCode ^ player.hashCode;
}

// A trick (4 cards played)
class Trick {
  const Trick({
    required this.plays,
    required this.leader,
    this.trumpSuit,
  });

  final List<CardPlay> plays; // 0-4 cards
  final Position leader;
  final Suit? trumpSuit; // null for no-trump

  bool get isComplete => plays.length == 4;
  bool get isEmpty => plays.isEmpty;

  // Get the suit that was led (effective suit, considering bowers and joker)
  Suit? get ledSuit {
    if (plays.isEmpty) return null;
    final firstCard = plays.first.card;

    // Joker takes on the trump suit when trump is declared
    if (firstCard.isJoker) {
      return trumpSuit; // Returns trump suit, or null in no-trump
    }

    // Left bower's effective suit is trump, not its printed suit
    if (firstCard.rank == Rank.jack && trumpSuit != null) {
      // Check if this is the left bower
      final oppositeColorSuit = _getOppositeColorSuit(firstCard.suit);
      if (oppositeColorSuit == trumpSuit) {
        return trumpSuit; // This is the left bower, it leads trump
      }
    }

    return firstCard.suit;
  }

  // Helper: Get same-color suit for left bower check
  Suit _getOppositeColorSuit(Suit suit) {
    switch (suit) {
      case Suit.hearts:
        return Suit.diamonds;
      case Suit.diamonds:
        return Suit.hearts;
      case Suit.spades:
        return Suit.clubs;
      case Suit.clubs:
        return Suit.spades;
    }
  }

  // Get winner of trick (must be complete)
  // Note: Winner determination logic will be in TrickEngine
  Position? get winner => null; // Implemented in TrickEngine

  Trick copyWith({
    List<CardPlay>? plays,
    Position? leader,
    Suit? trumpSuit,
  }) {
    return Trick(
      plays: plays ?? this.plays,
      leader: leader ?? this.leader,
      trumpSuit: trumpSuit ?? this.trumpSuit,
    );
  }

  Trick addPlay(CardPlay play) {
    return copyWith(plays: [...plays, play]);
  }

  @override
  String toString() => 'Trick: ${plays.length}/4 cards, led by ${leader.name}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Trick) return false;
    if (plays.length != other.plays.length) return false;
    for (int i = 0; i < plays.length; i++) {
      if (plays[i] != other.plays[i]) return false;
    }
    return leader == other.leader && trumpSuit == other.trumpSuit;
  }

  @override
  int get hashCode => plays.hashCode ^ leader.hashCode ^ trumpSuit.hashCode;
}

// Bidding action
enum BidAction { pass, bid, inkle }

// An entry in the bidding history
class BidEntry {
  const BidEntry({
    required this.bidder,
    required this.action,
    this.bid,
  });

  final Position bidder;
  final BidAction action;
  final Bid? bid; // null if action is pass

  bool get isPass => action == BidAction.pass;
  bool get isBid => action == BidAction.bid;
  bool get isInkle => action == BidAction.inkle;

  @override
  String toString() {
    switch (action) {
      case BidAction.pass:
        return '${bidder.name}: Pass';
      case BidAction.bid:
        return '${bidder.name}: $bid';
      case BidAction.inkle:
        return '${bidder.name}: Inkle ($bid)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BidEntry &&
        other.bidder == bidder &&
        other.action == action &&
        other.bid == bid;
  }

  @override
  int get hashCode => bidder.hashCode ^ action.hashCode ^ bid.hashCode;
}
