import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/engine/game_state.dart';
import 'package:fivehundred/src/game/logic/five_hundred_scorer.dart';
import 'package:fivehundred/src/game/models/card.dart';
import 'package:fivehundred/src/game/models/game_models.dart';

void main() {
  group('GameState helpers', () {
    test('getHand and getName return position-specific data', () {
      const state = GameState(
        playerName: 'South',
        partnerName: 'North',
        opponentWestName: 'Westy',
        opponentEastName: 'Easty',
        playerHand: [PlayingCard(rank: Rank.ace, suit: Suit.spades)],
        partnerHand: [PlayingCard(rank: Rank.king, suit: Suit.hearts)],
        opponentWestHand: [PlayingCard(rank: Rank.queen, suit: Suit.clubs)],
        opponentEastHand: [PlayingCard(rank: Rank.jack, suit: Suit.diamonds)],
      );

      expect(state.getName(Position.south), 'South');
      expect(state.getName(Position.north), 'North');
      expect(state.getName(Position.west), 'Westy');
      expect(state.getName(Position.east), 'Easty');

      expect(state.getHand(Position.south).single.rank, Rank.ace);
      expect(state.getHand(Position.north).single.rank, Rank.king);
      expect(state.getHand(Position.west).single.rank, Rank.queen);
      expect(state.getHand(Position.east).single.rank, Rank.jack);
    });

    test('getTricksWon and getScore route to the correct fields', () {
      const state = GameState(
        tricksWonNS: 3,
        tricksWonEW: 7,
        teamNorthSouthScore: 120,
        teamEastWestScore: -50,
      );

      expect(state.getTricksWon(Team.northSouth), 3);
      expect(state.getTricksWon(Team.eastWest), 7);
      expect(state.getScore(Team.northSouth), 120);
      expect(state.getScore(Team.eastWest), -50);
    });
  });

  group('GameState.copyWith', () {
    final bid = Bid(tricks: 7, suit: BidSuit.hearts, bidder: Position.north);
    final trick = Trick(plays: const [], leader: Position.west);
    final base = GameState(
      currentBidder: Position.north,
      currentHighBid: bid,
      winningBid: bid,
      contractor: Position.north,
      trumpSuit: Suit.spades,
      currentTrick: trick,
      currentPlayer: Position.south,
      selectedCardIndices: const {0, 1},
      gameOverData: GameOverData(
        winningTeam: Team.northSouth,
        finalScoreNS: 510,
        finalScoreEW: 120,
        status: GameOverStatus.teamNSWins,
        gamesWon: 1,
        gamesLost: 0,
      ),
      scoreAnimation: const ScoreAnimation(
        points: 40,
        team: Team.northSouth,
        timestamp: 1,
      ),
      pendingBidEntry: BidEntry(bidder: Position.north, action: BidAction.bid, bid: bid),
      aiThinkingPosition: Position.east,
      pendingCardIndex: 3,
      nominatedSuit: Suit.clubs,
    );

    test('clear flags null out optional values', () {
      final cleared = base.copyWith(
        clearCurrentBidder: true,
        clearCurrentHighBid: true,
        clearWinningBid: true,
        clearContractor: true,
        clearTrumpSuit: true,
        clearCurrentTrick: true,
        clearCurrentPlayer: true,
        clearSelectedCardIndices: true,
        clearGameOverData: true,
        clearScoreAnimation: true,
        clearPendingBidEntry: true,
        clearAiThinkingPosition: true,
        clearPendingCardIndex: true,
        clearNominatedSuit: true,
      );

      expect(cleared.currentBidder, isNull);
      expect(cleared.currentHighBid, isNull);
      expect(cleared.winningBid, isNull);
      expect(cleared.contractor, isNull);
      expect(cleared.trumpSuit, isNull);
      expect(cleared.currentTrick, isNull);
      expect(cleared.currentPlayer, isNull);
      expect(cleared.selectedCardIndices, isEmpty);
      expect(cleared.gameOverData, isNull);
      expect(cleared.scoreAnimation, isNull);
      expect(cleared.pendingBidEntry, isNull);
      expect(cleared.aiThinkingPosition, isNull);
      expect(cleared.pendingCardIndex, isNull);
      expect(cleared.nominatedSuit, isNull);
    });

    test('copyWith updates provided fields while keeping others intact', () {
      final updated = base.copyWith(
        gameStarted: true,
        gameStatus: 'Updated',
        tricksWonNS: 4,
      );

      expect(updated.gameStarted, isTrue);
      expect(updated.gameStatus, 'Updated');
      expect(updated.tricksWonNS, 4);
      expect(updated.currentHighBid, same(bid));
      expect(updated.trumpSuit, Suit.spades);
    });
  });
}
