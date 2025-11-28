import 'dart:math';

enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  joker, // Special card - suit is ignored for joker
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

class PlayingCard {
  const PlayingCard({required this.rank, required this.suit});

  final Rank rank;
  final Suit suit;

  // Relative card value (not used for scoring in 500, but useful for AI)
  int get value {
    switch (rank) {
      case Rank.joker:
        return 0; // Special card
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return 10;
      case Rank.ace:
        return 11;
    }
  }

  String get label {
    // Joker has no suit - it takes on the trump suit when trump is declared
    if (isJoker) return 'JOKER';
    return '${_rankLabel(rank)}${_suitLabel(suit)}';
  }

  // Helper methods for 500 trump logic
  bool get isJoker => rank == Rank.joker;
  bool get isJack => rank == Rank.jack;

  // Get the same-color suit (for left bower determination)
  // Hearts ↔ Diamonds (both red), Spades ↔ Clubs (both black)
  Suit getSameColorSuit() {
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

  String encode() => '${rank.index}|${suit.index}';

  static PlayingCard decode(String raw) {
    final parts = raw.split('|');
    final rankIndex = int.tryParse(parts[0]) ?? 0;
    final suitIndex = int.tryParse(parts[1]) ?? 0;
    return PlayingCard(
      rank: Rank.values[rankIndex.clamp(0, Rank.values.length - 1)],
      suit: Suit.values[suitIndex.clamp(0, Suit.values.length - 1)],
    );
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayingCard && other.rank == rank && other.suit == suit;
  }

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;
}

String _rankLabel(Rank rank) {
  switch (rank) {
    case Rank.joker:
      return 'JKR';
    case Rank.four:
      return '4';
    case Rank.five:
      return '5';
    case Rank.six:
      return '6';
    case Rank.seven:
      return '7';
    case Rank.eight:
      return '8';
    case Rank.nine:
      return '9';
    case Rank.ten:
      return '10';
    case Rank.jack:
      return 'J';
    case Rank.queen:
      return 'Q';
    case Rank.king:
      return 'K';
    case Rank.ace:
      return 'A';
  }
}

String _suitLabel(Suit suit) {
  switch (suit) {
    case Suit.spades:
      return '♠';
    case Suit.hearts:
      return '♥';
    case Suit.diamonds:
      return '♦';
    case Suit.clubs:
      return '♣';
  }
}

// Creates a 45-card deck for 500 (Joker + 4-Ace in all suits)
List<PlayingCard> createDeck({Random? random}) {
  final deck = <PlayingCard>[];

  // Add one joker (suit doesn't matter for joker, use spades by convention)
  deck.add(const PlayingCard(rank: Rank.joker, suit: Suit.spades));

  // Add 4-Ace for all suits (11 cards × 4 suits = 44 cards)
  for (final suit in Suit.values) {
    for (final rank in Rank.values) {
      if (rank != Rank.joker) {  // Skip joker (already added)
        deck.add(PlayingCard(rank: rank, suit: suit));
      }
    }
  }

  if (random != null) {
    deck.shuffle(random);
  } else {
    deck.shuffle();
  }
  return deck;
}

/// Sorts a hand of cards by suit and rank for display
///
/// If trumpSuit is null (before bidding):
///   Order: Joker first, then Spades, Hearts, Diamonds, Clubs
///   Within each suit: Ace (high) down to 4 (low)
///
/// If trumpSuit is set (after bidding):
///   Trump cards first (including left bower), sorted by trump rank:
///     Joker, Right bower, Left bower, A, K, Q, 10, 9, 8, 7, 6, 5, 4
///   Then non-trump suits: Spades, Hearts, Diamonds, Clubs
///   Within each non-trump suit: Ace (high) down to 4 (low)
///   Note: Left bower appears with trump cards, not in its natural suit
List<PlayingCard> sortHandBySuit(List<PlayingCard> hand, {Suit? trumpSuit}) {
  if (trumpSuit == null) {
    // Before bidding: simple suit sorting
    return _sortByNaturalSuit(hand);
  } else {
    // After bidding: trump-aware sorting
    return _sortWithTrump(hand, trumpSuit);
  }
}

/// Sort cards by natural suit (no trump consideration)
List<PlayingCard> _sortByNaturalSuit(List<PlayingCard> hand) {
  final sorted = List<PlayingCard>.from(hand);

  sorted.sort((a, b) {
    // Joker always comes first
    if (a.isJoker && !b.isJoker) return -1;
    if (!a.isJoker && b.isJoker) return 1;
    if (a.isJoker && b.isJoker) return 0;

    // Sort by suit (Spades, Hearts, Diamonds, Clubs)
    final suitOrder = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    final suitCompare = suitOrder.indexOf(a.suit).compareTo(suitOrder.indexOf(b.suit));
    if (suitCompare != 0) return suitCompare;

    // Within same suit, sort by rank (Ace high to 4 low)
    final rankOrder = [
      Rank.ace,
      Rank.king,
      Rank.queen,
      Rank.jack,
      Rank.ten,
      Rank.nine,
      Rank.eight,
      Rank.seven,
      Rank.six,
      Rank.five,
      Rank.four,
    ];
    return rankOrder.indexOf(a.rank).compareTo(rankOrder.indexOf(b.rank));
  });

  return sorted;
}

/// Sort cards with trump consideration (left bower appears with trump)
List<PlayingCard> _sortWithTrump(List<PlayingCard> hand, Suit trumpSuit) {
  final sorted = List<PlayingCard>.from(hand);

  // Helper: Get same-color suit
  Suit getOppositeColorSuit(Suit suit) {
    switch (suit) {
      case Suit.hearts: return Suit.diamonds;
      case Suit.diamonds: return Suit.hearts;
      case Suit.spades: return Suit.clubs;
      case Suit.clubs: return Suit.spades;
    }
  }

  // Helper: Check if card is left bower
  bool isLeftBower(PlayingCard card) {
    return card.rank == Rank.jack && card.suit == getOppositeColorSuit(trumpSuit);
  }

  // Helper: Check if card is right bower
  bool isRightBower(PlayingCard card) {
    return card.rank == Rank.jack && card.suit == trumpSuit;
  }

  // Helper: Check if card is trump
  bool isTrump(PlayingCard card) {
    if (card.isJoker) return true;
    if (card.suit == trumpSuit) return true;
    if (isLeftBower(card)) return true;
    return false;
  }

  // Helper: Get trump rank
  int getTrumpRank(PlayingCard card) {
    if (card.isJoker) return 100;
    if (isRightBower(card)) return 99;
    if (isLeftBower(card)) return 98;
    switch (card.rank) {
      case Rank.ace: return 14;
      case Rank.king: return 13;
      case Rank.queen: return 12;
      case Rank.ten: return 11;
      case Rank.nine: return 10;
      case Rank.eight: return 9;
      case Rank.seven: return 8;
      case Rank.six: return 7;
      case Rank.five: return 6;
      case Rank.four: return 5;
      default: return 0;
    }
  }

  sorted.sort((a, b) {
    final aTrump = isTrump(a);
    final bTrump = isTrump(b);

    // Trump cards come first
    if (aTrump && !bTrump) return -1;
    if (!aTrump && bTrump) return 1;

    // Both trump: sort by trump rank (high to low)
    if (aTrump && bTrump) {
      return getTrumpRank(b).compareTo(getTrumpRank(a));
    }

    // Both non-trump: sort by suit then rank
    final suitOrder = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    final suitCompare = suitOrder.indexOf(a.suit).compareTo(suitOrder.indexOf(b.suit));
    if (suitCompare != 0) return suitCompare;

    // Within same suit, sort by rank (Ace high to 4 low)
    final rankOrder = [
      Rank.ace,
      Rank.king,
      Rank.queen,
      Rank.jack,
      Rank.ten,
      Rank.nine,
      Rank.eight,
      Rank.seven,
      Rank.six,
      Rank.five,
      Rank.four,
    ];
    return rankOrder.indexOf(a.rank).compareTo(rankOrder.indexOf(b.rank));
  });

  return sorted;
}
