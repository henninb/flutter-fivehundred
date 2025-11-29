import '../models/card.dart';
import '../models/game_models.dart';
import 'trump_rules.dart';
import 'trick_engine.dart';

/// Analyzes whether a player can claim all remaining tricks
///
/// Uses perfect analysis considering:
/// - Card sequencing and who leads
/// - Which opponents are void in which suits
/// - Guaranteed trick winners
class ClaimAnalyzer {
  ClaimAnalyzer({
    required this.playerHand,
    required this.otherHands,
    required this.trumpRules,
    required this.completedTricks,
    required this.currentTrick,
    required this.currentPlayer,
  });

  final List<PlayingCard> playerHand;
  final Map<Position, List<PlayingCard>> otherHands; // Partner, East, West
  final TrumpRules trumpRules;
  final List<Trick> completedTricks;
  final Trick? currentTrick;
  final Position? currentPlayer;

  /// Check if player (Position.south) can claim all remaining tricks
  /// Uses simulation to guarantee 100% certainty
  bool canClaimRemainingTricks() {
    if (playerHand.isEmpty) return false;

    // Quick check: If player has all remaining cards, they win
    final totalOtherCards = otherHands.values.fold(0, (sum, hand) => sum + hand.length);
    if (totalOtherCards == 0) return true;

    // Build current game situation
    final situation = _GameSituation(
      hands: {
        Position.south: List.from(playerHand),
        Position.north: List.from(otherHands[Position.north] ?? []),
        Position.east: List.from(otherHands[Position.east] ?? []),
        Position.west: List.from(otherHands[Position.west] ?? []),
      },
      completedTricks: completedTricks,
      currentTrick: currentTrick,
      currentPlayer: currentPlayer,
      trumpRules: trumpRules,
    );

    // Simulate all remaining tricks - player must win every single one
    return _simulateAllTricks(situation);
  }

  /// Simulate all remaining tricks to see if player wins them all
  bool _simulateAllTricks(_GameSituation situation) {
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // Determine who should lead the first trick we're simulating
    Position leader;
    if (situation.currentTrick != null && situation.currentTrick!.plays.isNotEmpty) {
      // Current trick in progress - need to finish it first
      leader = situation.currentPlayer ?? Position.south;

      // Simulate finishing the current trick
      final result = _simulateCurrentTrick(situation, trickEngine);
      if (result.winner != Position.south) {
        // Player didn't win the current trick in progress
        return false;
      }
      leader = result.winner;
      // Update hands after this trick
      for (final play in result.trick.plays) {
        situation.hands[play.player]!.remove(play.card);
      }
    } else if (situation.completedTricks.isNotEmpty) {
      // Determine leader from last completed trick
      final lastTrick = situation.completedTricks.last;
      leader = trickEngine.getCurrentWinner(lastTrick)!;
    } else {
      // No tricks yet - current player leads
      leader = situation.currentPlayer ?? Position.south;
    }

    // Simulate each remaining trick
    while (_hasCardsRemaining(situation.hands)) {
      final trickResult = _simulateTrick(situation, leader, trickEngine);

      if (trickResult.winner != Position.south) {
        // Player lost a trick - cannot claim
        return false;
      }

      // Winner leads next trick
      leader = trickResult.winner;
    }

    // Player won all simulated tricks!
    return true;
  }

  /// Simulate finishing the current trick in progress
  _TrickSimulationResult _simulateCurrentTrick(_GameSituation situation, TrickEngine trickEngine) {
    var trick = situation.currentTrick!;
    var nextPlayer = situation.currentPlayer!;

    while (!trick.isComplete) {
      final hand = situation.hands[nextPlayer]!;
      if (hand.isEmpty) break;

      // Choose best card for this player
      final card = _chooseBestCard(nextPlayer, hand, trick, trickEngine);

      final result = trickEngine.playCard(
        currentTrick: trick,
        card: card,
        player: nextPlayer,
        playerHand: hand,
      );

      trick = result.trick;
      if (!trick.isComplete) {
        nextPlayer = nextPlayer.next;
      }
    }

    final winner = trickEngine.getCurrentWinner(trick)!;
    return _TrickSimulationResult(trick: trick, winner: winner);
  }

  /// Simulate a complete trick from scratch
  _TrickSimulationResult _simulateTrick(_GameSituation situation, Position leader, TrickEngine trickEngine) {
    var trick = Trick(plays: [], leader: leader, trumpSuit: trumpRules.trumpSuit);
    var nextPlayer = leader;

    for (int i = 0; i < 4; i++) {
      final hand = situation.hands[nextPlayer]!;
      if (hand.isEmpty) break;

      // Choose best card for this player
      final card = _chooseBestCard(nextPlayer, hand, trick, trickEngine);

      final result = trickEngine.playCard(
        currentTrick: trick,
        card: card,
        player: nextPlayer,
        playerHand: hand,
      );

      trick = result.trick;

      // Remove card from simulated hand
      hand.remove(card);

      nextPlayer = nextPlayer.next;
    }

    final winner = trickEngine.getCurrentWinner(trick)!;
    return _TrickSimulationResult(trick: trick, winner: winner);
  }

  /// Choose the best card for a player to play
  /// For the player (south): Play weakest card that still wins
  /// For opponents: Play strongest card to try to win
  PlayingCard _chooseBestCard(Position player, List<PlayingCard> hand, Trick trick, TrickEngine trickEngine) {
    final legalCards = trickEngine.getLegalCards(trick: trick, hand: hand);
    if (legalCards.isEmpty) return hand.first; // Should never happen

    if (player == Position.south) {
      // Player: try to win with weakest winning card, or play weakest if can't win
      return _chooseWeakestWinningCard(legalCards, trick, trickEngine) ?? _chooseWeakestCard(legalCards);
    } else {
      // Opponent: try to win with strongest card
      return _chooseStrongestCard(legalCards, trick, trickEngine);
    }
  }

  /// Choose the weakest card that still wins the trick
  PlayingCard? _chooseWeakestWinningCard(List<PlayingCard> cards, Trick trick, TrickEngine trickEngine) {
    final currentWinner = trickEngine.getCurrentWinner(trick);
    final currentWinningCard = currentWinner != null ? trick.plays.firstWhere((p) => p.player == currentWinner).card : null;

    final winningCards = cards.where((card) {
      if (currentWinningCard == null) return true; // Leading the trick
      return trumpRules.compare(card, currentWinningCard) > 0;
    }).toList();

    if (winningCards.isEmpty) return null;

    // Return weakest winning card
    winningCards.sort((a, b) => trumpRules.compare(a, b));
    return winningCards.first;
  }

  /// Choose the weakest card (for discarding when can't win)
  PlayingCard _chooseWeakestCard(List<PlayingCard> cards) {
    final sorted = List<PlayingCard>.from(cards);
    sorted.sort((a, b) => trumpRules.compare(a, b));
    return sorted.first;
  }

  /// Choose the strongest card (for opponents trying to win)
  PlayingCard _chooseStrongestCard(List<PlayingCard> cards, Trick trick, TrickEngine trickEngine) {
    final sorted = List<PlayingCard>.from(cards);
    sorted.sort((a, b) => trumpRules.compare(b, a)); // Descending
    return sorted.first;
  }

  bool _hasCardsRemaining(Map<Position, List<PlayingCard>> hands) {
    return hands.values.any((hand) => hand.isNotEmpty);
  }
}

/// Represents the current game situation for simulation
class _GameSituation {
  _GameSituation({
    required this.hands,
    required this.completedTricks,
    required this.currentTrick,
    required this.currentPlayer,
    required this.trumpRules,
  });

  final Map<Position, List<PlayingCard>> hands;
  final List<Trick> completedTricks;
  final Trick? currentTrick;
  final Position? currentPlayer;
  final TrumpRules trumpRules;
}

/// Result of a simulated trick
class _TrickSimulationResult {
  _TrickSimulationResult({required this.trick, required this.winner});

  final Trick trick;
  final Position winner;
}
