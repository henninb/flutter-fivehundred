import 'dart:math';

import 'package:flutter/foundation.dart';

enum Suit { hearts, diamonds, clubs, spades }

extension SuitX on Suit {
  /// Returns the same-colour partner suit (hearts↔diamonds, spades↔clubs).
  Suit get sameColorSuit {
    switch (this) {
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
}

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

@immutable
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

  /// Encodes the card as a stable string using enum names.
  String encode() => '${rank.name}|${suit.name}';

  /// Decodes a card previously encoded with [encode].
  ///
  /// Throws [FormatException] for any invalid input.
  static PlayingCard decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) {
      throw FormatException(
        'Invalid card encoding: expected "rank|suit" format, got "$raw"',
      );
    }
    try {
      final rank = Rank.values.byName(parts[0]);
      final suit = Suit.values.byName(parts[1]);
      return PlayingCard(rank: rank, suit: suit);
    } on ArgumentError {
      throw FormatException(
        'Invalid card encoding: unknown rank or suit in "$raw"',
      );
    }
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
      if (rank != Rank.joker) {
        // Skip joker (already added)
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
