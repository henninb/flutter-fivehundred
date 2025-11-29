import '../models/card.dart';
import '../models/game_models.dart';
import 'trump_rules.dart';

/// Analyzes whether a player can claim all remaining tricks
///
/// This is VERY CONSERVATIVE - only returns true when absolutely certain
/// the player will win all remaining tricks.
class ClaimAnalyzer {
  ClaimAnalyzer({
    required this.playerHand,
    required this.trumpRules,
    required this.completedTricks,
    required this.currentTrick,
  });

  final List<PlayingCard> playerHand;
  final TrumpRules trumpRules;
  final List<Trick> completedTricks;
  final Trick? currentTrick;

  /// Check if player can claim all remaining tricks
  /// Very conservative - only returns true when 100% certain
  bool canClaimRemainingTricks() {
    if (playerHand.isEmpty) return false;

    // Get all cards that have been played
    final playedCards = _getAllPlayedCards();

    // Strategy 1: Player has all the highest trumps
    if (_hasAllTopTrumps(playedCards)) {
      return true;
    }

    // Strategy 2: Player has Joker and all remaining cards are trump
    if (_hasJokerAndAllTrump()) {
      return true;
    }

    // Strategy 3: Player has master cards in all remaining suits
    if (_hasMasterCardsInAllSuits(playedCards)) {
      return true;
    }

    return false;
  }

  /// Get all cards that have been played so far
  List<PlayingCard> _getAllPlayedCards() {
    final played = <PlayingCard>[];

    // Add cards from completed tricks
    for (final trick in completedTricks) {
      for (final play in trick.plays) {
        played.add(play.card);
      }
    }

    // Add cards from current trick
    if (currentTrick != null) {
      for (final play in currentTrick!.plays) {
        played.add(play.card);
      }
    }

    return played;
  }

  /// Check if player has all the top trump cards
  bool _hasAllTopTrumps(List<PlayingCard> playedCards) {
    // Get trump cards in hand
    final trumpsInHand = trumpRules.getTrumpCards(playerHand);
    if (trumpsInHand.isEmpty) return false;

    // Player must have the Joker (highest trump)
    if (!trumpsInHand.any((c) => c.isJoker)) return false;

    // Count total cards remaining (in all hands)
    final totalCardsPlayed = playedCards.length;
    final totalCardsRemaining = 40 - totalCardsPlayed; // 40 cards in play (after kitty exchange)

    // If player has all remaining cards, they win
    if (playerHand.length == totalCardsRemaining) {
      return true;
    }

    // Check if all remaining trump cards are in player's hand
    // and player has enough high cards to win all remaining tricks
    final allTrumpCards = _getAllPossibleTrumpCards();
    final trumpsNotPlayed = allTrumpCards
        .where((card) => !playedCards.any((p) => p == card))
        .toList();

    // Check if player has all unplayed trumps
    final hasAllTrumps = trumpsNotPlayed.every((trump) =>
      trumpsInHand.any((h) => h == trump)
    );

    // If player has all remaining trumps and enough cards to cover remaining tricks,
    // they can claim
    if (hasAllTrumps && trumpsInHand.length >= totalCardsRemaining / 4) {
      return true;
    }

    return false;
  }

  /// Check if player has joker and all their cards are trump
  bool _hasJokerAndAllTrump() {
    if (!playerHand.any((c) => c.isJoker)) return false;

    // Check if ALL cards in hand are trump
    return playerHand.every((card) => trumpRules.isTrump(card));
  }

  /// Check if player has the master (highest unplayed) card in every remaining suit
  bool _hasMasterCardsInAllSuits(List<PlayingCard> playedCards) {
    // Get all suits that still have cards in play
    final remainingSuits = <Suit>{};

    // Check player's hand for suits
    for (final card in playerHand) {
      if (!card.isJoker) {
        final effectiveSuit = trumpRules.getEffectiveSuit(card);
        remainingSuits.add(effectiveSuit);
      }
    }

    // For each suit in hand, check if player has the highest unplayed card
    for (final suit in remainingSuits) {
      if (!_hasHighestCardInSuit(suit, playedCards)) {
        return false;
      }
    }

    // Also need to ensure player has enough cards to cover all remaining tricks
    final totalCardsPlayed = playedCards.length;
    final totalCardsRemaining = 40 - totalCardsPlayed;
    final remainingTricks = (totalCardsRemaining / 4).ceil();

    return playerHand.length >= remainingTricks;
  }

  /// Check if player has the highest card in a specific suit
  bool _hasHighestCardInSuit(Suit suit, List<PlayingCard> playedCards) {
    // Get all possible cards in this suit
    final allCardsInSuit = _getAllCardsInSuit(suit);

    // Find highest unplayed card in this suit
    PlayingCard? highestUnplayed;
    for (final card in allCardsInSuit) {
      // Skip if already played
      if (playedCards.any((p) => p == card)) continue;

      // Check if this is higher than current highest
      if (highestUnplayed == null ||
          trumpRules.compare(card, highestUnplayed) > 0) {
        highestUnplayed = card;
      }
    }

    // Check if player has this highest card
    if (highestUnplayed == null) return false;
    return playerHand.any((c) => c == highestUnplayed);
  }

  /// Get all possible cards in a suit (from a full deck)
  List<PlayingCard> _getAllCardsInSuit(Suit suit) {
    final cards = <PlayingCard>[];

    // Handle trump suit specially (includes left bower)
    if (trumpRules.trumpSuit == suit) {
      // Add joker
      cards.add(const PlayingCard(rank: Rank.joker, suit: Suit.spades));

      // Add all trump suit cards
      for (final rank in Rank.values) {
        if (rank != Rank.joker) {
          cards.add(PlayingCard(rank: rank, suit: suit));
        }
      }

      // Add left bower (jack of same color)
      final oppositeColorSuit = _getOppositeColorSuit(suit);
      cards.add(PlayingCard(rank: Rank.jack, suit: oppositeColorSuit));
    } else {
      // Regular suit - add all cards except left bower if it would be in this suit
      for (final rank in Rank.values) {
        if (rank != Rank.joker) {
          final card = PlayingCard(rank: rank, suit: suit);
          // Don't add if this is the left bower (it belongs to trump)
          if (trumpRules.trumpSuit != null &&
              rank == Rank.jack &&
              suit == _getOppositeColorSuit(trumpRules.trumpSuit!)) {
            continue;
          }
          cards.add(card);
        }
      }
    }

    return cards;
  }

  /// Get all possible trump cards
  List<PlayingCard> _getAllPossibleTrumpCards() {
    if (trumpRules.trumpSuit == null) {
      // No trump - only joker
      return [const PlayingCard(rank: Rank.joker, suit: Suit.spades)];
    }

    return _getAllCardsInSuit(trumpRules.trumpSuit!);
  }

  /// Get the same-color suit (for left bower determination)
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
}
