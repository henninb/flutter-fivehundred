import '../models/card.dart';
import '../models/game_models.dart';
import 'trump_rules.dart';
import 'trick_engine.dart';

/// Basic AI for card play in 500
///
/// Strategy:
/// - When leading: Play highest card from longest suit (or trump if strong)
/// - When partner is winning: Play lowest legal card (don't overtrump partner)
/// - When opponent is winning: Try to win with lowest winning card
/// - When void: Play trump if able, otherwise discard lowest card
/// - Minimal partnership coordination (just knows who partner is)
class PlayAI {
  PlayAI._();

  /// Choose which card to play
  static PlayingCard chooseCard({
    required List<PlayingCard> hand,
    required Trick currentTrick,
    required TrumpRules trumpRules,
    required Position position,
    required Position partner,
    required TrickEngine trickEngine,
  }) {
    // Get legal cards
    final legalCards = trickEngine.getLegalCards(
      trick: currentTrick,
      hand: hand,
    );

    if (legalCards.isEmpty) {
      throw StateError('No legal cards to play');
    }

    if (legalCards.length == 1) {
      return legalCards.first; // Only one choice
    }

    // Leading (first card)
    if (currentTrick.isEmpty) {
      return _chooseLeadCard(
        legalCards: legalCards,
        hand: hand,
        trumpRules: trumpRules,
      );
    }

    // Following
    return _chooseFollowCard(
      legalCards: legalCards,
      currentTrick: currentTrick,
      trumpRules: trumpRules,
      partner: partner,
    );
  }

  /// Choose card to lead
  static PlayingCard _chooseLeadCard({
    required List<PlayingCard> legalCards,
    required List<PlayingCard> hand,
    required TrumpRules trumpRules,
  }) {
    // If we have strong trumps, lead highest trump
    final trumps = legalCards.where(trumpRules.isTrump).toList();
    if (trumps.length >= 3) {
      final highestTrump = trumpRules.getHighestCard(trumps);
      if (highestTrump != null) return highestTrump;
    }

    // Otherwise, lead from longest suit (non-trump)
    final nonTrumps = legalCards.where((c) => !trumpRules.isTrump(c)).toList();

    if (nonTrumps.isNotEmpty) {
      // Group by suit
      final suitCounts = <Suit, List<PlayingCard>>{};
      for (final card in nonTrumps) {
        suitCounts.putIfAbsent(card.suit, () => []).add(card);
      }

      // Find longest suit
      var longestSuit = suitCounts.entries.first;
      for (final entry in suitCounts.entries) {
        if (entry.value.length > longestSuit.value.length) {
          longestSuit = entry;
        }
      }

      // Lead highest card from longest suit
      return trumpRules.getHighestCard(longestSuit.value) ?? longestSuit.value.first;
    }

    // All trumps - lead highest
    return trumpRules.getHighestCard(legalCards) ?? legalCards.first;
  }

  /// Choose card to follow
  static PlayingCard _chooseFollowCard({
    required List<PlayingCard> legalCards,
    required Trick currentTrick,
    required TrumpRules trumpRules,
    required Position partner,
  }) {
    // Determine who's currently winning
    final currentWinner = _getCurrentWinner(currentTrick, trumpRules);
    final partnerIsWinning = currentWinner == partner;

    if (partnerIsWinning) {
      // Partner is winning - play lowest card (don't waste high cards)
      return trumpRules.getLowestCard(legalCards) ?? legalCards.first;
    }

    // Opponent is winning - try to win with lowest winning card
    final winningCard = _getWinningCard(currentTrick, trumpRules);
    final cardsWeCanWinWith = legalCards.where((c) {
      return trumpRules.compare(c, winningCard) > 0;
    }).toList();

    if (cardsWeCanWinWith.isNotEmpty) {
      // Win with lowest winning card
      return trumpRules.getLowestCard(cardsWeCanWinWith) ?? cardsWeCanWinWith.first;
    }

    // Can't win - play lowest card
    return trumpRules.getLowestCard(legalCards) ?? legalCards.first;
  }

  /// Get the card that's currently winning the trick
  static PlayingCard _getWinningCard(Trick trick, TrumpRules trumpRules) {
    if (trick.plays.isEmpty) {
      throw StateError('Cannot get winning card from empty trick');
    }

    PlayingCard winningCard = trick.plays.first.card;

    for (int i = 1; i < trick.plays.length; i++) {
      final currentCard = trick.plays[i].card;

      // Trump beats non-trump
      if (trumpRules.isTrump(currentCard) && !trumpRules.isTrump(winningCard)) {
        winningCard = currentCard;
      } else if (trumpRules.isTrump(currentCard) && trumpRules.isTrump(winningCard)) {
        // Both trump - higher wins
        if (trumpRules.compare(currentCard, winningCard) > 0) {
          winningCard = currentCard;
        }
      } else if (!trumpRules.isTrump(currentCard) && !trumpRules.isTrump(winningCard)) {
        // Both non-trump - same suit comparison
        if (trumpRules.getEffectiveSuit(currentCard) == trick.ledSuit) {
          if (trumpRules.getEffectiveSuit(winningCard) != trick.ledSuit ||
              trumpRules.compare(currentCard, winningCard) > 0) {
            winningCard = currentCard;
          }
        }
      }
    }

    return winningCard;
  }

  /// Get the position currently winning the trick
  static Position _getCurrentWinner(Trick trick, TrumpRules trumpRules) {
    if (trick.plays.isEmpty) {
      return trick.leader; // No one has played yet
    }

    final winningCard = _getWinningCard(trick, trumpRules);

    for (final play in trick.plays) {
      if (play.card == winningCard) {
        return play.player;
      }
    }

    return trick.leader; // Fallback (shouldn't happen)
  }
}
