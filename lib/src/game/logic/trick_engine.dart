import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import 'trump_rules.dart';

/// Manages trick-taking logic for 500
///
/// Handles:
/// - Legal play validation (must follow suit)
/// - Trick winner determination
/// - Joker special rules
/// - Trump suit handling
class TrickEngine {
  TrickEngine({required this.trumpRules});

  final TrumpRules trumpRules;

  /// Play a card to the current trick
  TrickResult playCard({
    required Trick currentTrick,
    required PlayingCard card,
    required Position player,
    required List<PlayingCard> playerHand,
    Suit? nominatedSuit, // Required when leading with joker
  }) {
    // Validate play is legal
    final validation = validatePlay(
      trick: currentTrick,
      card: card,
      hand: playerHand,
      nominatedSuit: nominatedSuit,
    );

    if (!validation.isValid) {
      // Log illegal card play attempt
      if (kDebugMode) {
        debugPrint('\n[TRICK PLAY VALIDATION FAILED]');
        debugPrint('Player: ${player.name}');
        debugPrint('Attempted card: ${card.label}');
        debugPrint('Led suit: ${currentTrick.ledSuit?.name ?? 'none (leading)'}');
        debugPrint('Nominated suit: ${nominatedSuit?.name ?? 'none'}');
        debugPrint('Trump suit: ${trumpRules.trumpSuit?.name ?? 'no trump'}');
        debugPrint('Hand size: ${playerHand.length}');
        debugPrint('Cards in trick: ${currentTrick.plays.length}');
        debugPrint('Reason: ${validation.errorMessage}');
      }
      return TrickResult.error(validation.errorMessage!);
    }

    // Add card to trick
    final play = CardPlay(card: card, player: player);
    final updatedTrick = currentTrick.addPlay(play);

    // Check if trick is complete
    if (updatedTrick.isComplete) {
      final winner = _determineTrickWinner(updatedTrick);
      return TrickResult.trickComplete(
        trick: updatedTrick,
        winner: winner,
        message: '${winner.name} wins the trick',
      );
    }

    // Trick continues
    return TrickResult.success(
      trick: updatedTrick,
      message: '${player.name} played $card',
    );
  }

  /// Validate if a card can be legally played
  PlayValidation validatePlay({
    required Trick trick,
    required PlayingCard card,
    required List<PlayingCard> hand,
    Suit? nominatedSuit,
  }) {
    // Must have the card in hand
    if (!hand.contains(card)) {
      return PlayValidation.invalid('Card not in hand');
    }

    // If leading (first card), any card is valid except joker restrictions
    if (trick.isEmpty) {
      // Leading with joker in no-trump requires nominating a suit
      if (card.isJoker && trumpRules.trumpSuit == null && nominatedSuit == null) {
        return PlayValidation.invalid(
          'Must nominate a suit when leading with joker in no-trump',
        );
      }
      return PlayValidation.valid();
    }

    // Following: must follow suit if able
    final ledSuit = trick.ledSuit;

    // Special case: joker was led in no-trump with nominated suit
    if (ledSuit == null && nominatedSuit != null) {
      // Must follow nominated suit if able
      final hasNominatedSuit = hand.any(
        (c) => !c.isJoker && trumpRules.getEffectiveSuit(c) == nominatedSuit,
      );
      if (hasNominatedSuit && trumpRules.getEffectiveSuit(card) != nominatedSuit && !card.isJoker) {
        return PlayValidation.invalid('Must follow nominated suit $nominatedSuit');
      }
      return PlayValidation.valid();
    }

    // Normal case: must follow led suit if able
    if (ledSuit != null) {
      // Special case for Joker in no-trump: Joker can ALWAYS be played voluntarily
      // It's the highest card but playing it is optional - you can discard any suit
      if (card.isJoker && trumpRules.trumpSuit == null) {
        if (kDebugMode) {
          debugPrint('[TRICK ENGINE] Joker played in no-trump - always legal (voluntary play)');
        }
        return PlayValidation.valid();
      }

      final cardEffectiveSuit = trumpRules.getEffectiveSuit(card);
      final hasLedSuit = hand.any((c) => !c.isJoker && trumpRules.getEffectiveSuit(c) == ledSuit);

      if (hasLedSuit && cardEffectiveSuit != ledSuit) {
        if (kDebugMode) {
          debugPrint('[TRICK ENGINE] Must follow suit ${_suitLabel(ledSuit)} - player has led suit');
        }
        return PlayValidation.invalid('Must follow suit ${_suitLabel(ledSuit)}');
      }
    }

    return PlayValidation.valid();
  }

  /// Get all legal cards that can be played from hand
  List<PlayingCard> getLegalCards({
    required Trick trick,
    required List<PlayingCard> hand,
    Suit? nominatedSuit,
  }) {
    return hand.where((card) {
      final validation = validatePlay(
        trick: trick,
        card: card,
        hand: hand,
        nominatedSuit: nominatedSuit,
      );
      return validation.isValid;
    }).toList();
  }

  /// Determine the current winner of a trick (works on incomplete tricks)
  /// Returns null if trick is empty
  Position? getCurrentWinner(Trick trick) {
    if (trick.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TRICK ENGINE] getCurrentWinner called on empty trick');
      }
      return null;
    }

    final plays = trick.plays;
    final ledSuit = trick.ledSuit;

    if (kDebugMode) {
      debugPrint('[TRICK ENGINE] Determining winner of ${plays.length}-card trick');
      debugPrint('  Led suit: ${ledSuit?.name ?? 'none (joker in no-trump)'}');
      debugPrint('  Trump suit: ${trumpRules.trumpSuit?.name ?? 'no trump'}');
    }

    // Find the highest card so far
    CardPlay winningPlay = plays.first;
    PlayingCard winningCard = plays.first.card;

    for (int i = 1; i < plays.length; i++) {
      final currentCard = plays[i].card;

      // Trump always beats non-trump
      final winningIsTrump = trumpRules.isTrump(winningCard);
      final currentIsTrump = trumpRules.isTrump(currentCard);

      if (currentIsTrump && !winningIsTrump) {
        if (kDebugMode) {
          debugPrint('  ${plays[i].player.name}\'s ${currentCard.label} (trump) beats ${winningPlay.player.name}\'s ${winningCard.label}');
        }
        winningPlay = plays[i];
        winningCard = currentCard;
      } else if (!currentIsTrump && winningIsTrump) {
        // Keep current winner
      } else if (currentIsTrump && winningIsTrump) {
        // Both trump: compare trump ranks
        if (trumpRules.compare(currentCard, winningCard) > 0) {
          if (kDebugMode) {
            debugPrint('  ${plays[i].player.name}\'s ${currentCard.label} (higher trump) beats ${winningPlay.player.name}\'s ${winningCard.label}');
          }
          winningPlay = plays[i];
          winningCard = currentCard;
        }
      } else {
        // Both non-trump: only matters if same suit as led suit
        final currentSuit = trumpRules.getEffectiveSuit(currentCard);
        final winningSuit = trumpRules.getEffectiveSuit(winningCard);

        if (currentSuit == ledSuit && winningSuit != ledSuit) {
          if (kDebugMode) {
            debugPrint('  ${plays[i].player.name}\'s ${currentCard.label} (follows led suit) beats ${winningPlay.player.name}\'s ${winningCard.label}');
          }
          winningPlay = plays[i];
          winningCard = currentCard;
        } else if (currentSuit == ledSuit && winningSuit == ledSuit) {
          if (trumpRules.compare(currentCard, winningCard) > 0) {
            if (kDebugMode) {
              debugPrint('  ${plays[i].player.name}\'s ${currentCard.label} (higher rank) beats ${winningPlay.player.name}\'s ${winningCard.label}');
            }
            winningPlay = plays[i];
            winningCard = currentCard;
          }
        }
      }
    }

    if (kDebugMode) {
      debugPrint('  Winner: ${winningPlay.player.name} with ${winningCard.label}');
    }

    return winningPlay.player;
  }

  /// Determine the winner of a complete trick
  Position _determineTrickWinner(Trick trick) {
    if (!trick.isComplete) {
      throw StateError('Cannot determine winner of incomplete trick');
    }

    // Use the getCurrentWinner method since the logic is identical
    return getCurrentWinner(trick)!;
  }

  /// Check if a player has any legal plays
  bool hasLegalPlay({
    required Trick trick,
    required List<PlayingCard> hand,
  }) {
    return getLegalCards(trick: trick, hand: hand).isNotEmpty;
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

/// Result of playing a card
class TrickResult {
  const TrickResult._({
    required this.status,
    required this.trick,
    this.winner,
    required this.message,
  });

  final TrickStatus status;
  final Trick trick;
  final Position? winner;
  final String message;

  factory TrickResult.success({
    required Trick trick,
    required String message,
  }) =>
      TrickResult._(
        status: TrickStatus.inProgress,
        trick: trick,
        message: message,
      );

  factory TrickResult.trickComplete({
    required Trick trick,
    required Position winner,
    required String message,
  }) =>
      TrickResult._(
        status: TrickStatus.complete,
        trick: trick,
        winner: winner,
        message: message,
      );

  factory TrickResult.error(String message) => TrickResult._(
        status: TrickStatus.error,
        trick: const Trick(plays: [], leader: Position.north),
        message: message,
      );
}

enum TrickStatus {
  inProgress, // Trick still being played
  complete, // Trick complete, winner determined
  error, // Invalid play
}

/// Result of play validation
class PlayValidation {
  const PlayValidation._({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;

  factory PlayValidation.valid() => const PlayValidation._(isValid: true);
  factory PlayValidation.invalid(String message) =>
      PlayValidation._(isValid: false, errorMessage: message);
}
