import '../models/card.dart';

/// Handles all trump-related logic for the game of 500
///
/// This includes:
/// - Card comparison in the context of trump suit
/// - Determining if a card is trump
/// - Identifying right bower (Jack of trump suit)
/// - Identifying left bower (Jack of same color as trump)
/// - Getting effective suit (left bower counts as trump suit)
class TrumpRules {
  const TrumpRules({this.trumpSuit});

  final Suit? trumpSuit; // null for no-trump

  /// Check if a card is trump
  bool isTrump(PlayingCard card) {
    if (card.isJoker) return true; // Joker is always trump
    if (trumpSuit == null) return false; // No trump in no-trump (except joker)
    if (card.suit == trumpSuit) return true; // Trump suit
    if (isLeftBower(card)) return true; // Left bower is trump
    return false;
  }

  /// Check if a card is the right bower (Jack of trump suit)
  bool isRightBower(PlayingCard card) {
    if (trumpSuit == null) return false;
    return card.rank == Rank.jack && card.suit == trumpSuit;
  }

  /// Check if a card is the left bower (Jack of same color as trump)
  bool isLeftBower(PlayingCard card) {
    if (trumpSuit == null) return false;
    if (card.rank != Rank.jack) return false;
    return card.suit == _getOppositeColorSuit(trumpSuit!);
  }

  /// Get the effective suit of a card (for following suit)
  /// - Joker's effective suit is the trump suit (e.g., if Hearts is trump, Joker is effectively a Heart)
  /// - Left bower's effective suit is the trump suit, not its printed suit
  Suit getEffectiveSuit(PlayingCard card) {
    if (card.isJoker) {
      // Joker takes on the trump suit when trump is declared
      // In no-trump, return arbitrary suit (Joker is still playable as only trump)
      return trumpSuit ?? Suit.spades;
    }
    if (isLeftBower(card)) {
      return trumpSuit!; // Left bower counts as trump suit
    }
    return card.suit;
  }

  /// Compare two cards in the context of trump
  ///
  /// Returns:
  ///  - Positive number if card1 is higher
  ///  - Negative number if card2 is higher
  ///  - Zero if equal (shouldn't happen in practice)
  int compare(PlayingCard card1, PlayingCard card2) {
    final card1Trump = isTrump(card1);
    final card2Trump = isTrump(card2);

    // Trump always beats non-trump
    if (card1Trump && !card2Trump) return 1;
    if (!card1Trump && card2Trump) return -1;

    // Both trump: compare trump ranks
    if (card1Trump && card2Trump) {
      return _compareTrumpCards(card1, card2);
    }

    // Both non-trump: compare by rank (same suit assumed, caller should check)
    return _compareNonTrumpCards(card1, card2);
  }

  /// Compare two trump cards
  int _compareTrumpCards(PlayingCard card1, PlayingCard card2) {
    final rank1 = _getTrumpRank(card1);
    final rank2 = _getTrumpRank(card2);
    return rank1.compareTo(rank2);
  }

  /// Get trump rank (higher number = higher card)
  int _getTrumpRank(PlayingCard card) {
    // Joker is always highest
    if (card.isJoker) return 100;

    // Right bower (J of trump suit)
    if (isRightBower(card)) return 99;

    // Left bower (J of same color)
    if (isLeftBower(card)) return 98;

    // Regular trump cards
    switch (card.rank) {
      case Rank.ace:
        return 14;
      case Rank.king:
        return 13;
      case Rank.queen:
        return 12;
      case Rank.ten:
        return 11;
      case Rank.nine:
        return 10;
      case Rank.eight:
        return 9;
      case Rank.seven:
        return 8;
      case Rank.six:
        return 7;
      case Rank.five:
        return 6;
      case Rank.four:
        return 5;
      default:
        return 0; // Shouldn't happen
    }
  }

  /// Compare two non-trump cards (assumed to be same suit)
  int _compareNonTrumpCards(PlayingCard card1, PlayingCard card2) {
    final rank1 = _getNonTrumpRank(card1);
    final rank2 = _getNonTrumpRank(card2);
    return rank1.compareTo(rank2);
  }

  /// Get non-trump rank (higher number = higher card)
  /// In non-trump suits: A, K, Q, (J), 10, 9, 8, 7, 6, 5, 4
  int _getNonTrumpRank(PlayingCard card) {
    switch (card.rank) {
      case Rank.ace:
        return 14;
      case Rank.king:
        return 13;
      case Rank.queen:
        return 12;
      case Rank.jack:
        return 11;
      case Rank.ten:
        return 10;
      case Rank.nine:
        return 9;
      case Rank.eight:
        return 8;
      case Rank.seven:
        return 7;
      case Rank.six:
        return 6;
      case Rank.five:
        return 5;
      case Rank.four:
        return 4;
      default:
        return 0; // Shouldn't happen
    }
  }

  /// Get the same-color suit (for left bower determination)
  /// Hearts ↔ Diamonds (both red), Spades ↔ Clubs (both black)
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

  /// Get all trump cards from a list of cards
  List<PlayingCard> getTrumpCards(List<PlayingCard> cards) {
    return cards.where(isTrump).toList();
  }

  /// Get all non-trump cards from a list of cards
  List<PlayingCard> getNonTrumpCards(List<PlayingCard> cards) {
    return cards.where((card) => !isTrump(card)).toList();
  }

  /// Count trump cards in a hand
  int countTrump(List<PlayingCard> cards) {
    return cards.where(isTrump).length;
  }

  /// Get highest card from a list (in context of trump)
  PlayingCard? getHighestCard(List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    return cards.reduce((a, b) => compare(a, b) > 0 ? a : b);
  }

  /// Get lowest card from a list (in context of trump)
  PlayingCard? getLowestCard(List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    return cards.reduce((a, b) => compare(a, b) < 0 ? a : b);
  }

  @override
  String toString() {
    if (trumpSuit == null) return 'TrumpRules(No Trump)';
    return 'TrumpRules(${_suitLabel(trumpSuit!)})';
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
}
