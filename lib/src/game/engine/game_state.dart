import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import '../logic/five_hundred_scorer.dart';

/// Game phases for 500
enum GamePhase {
  setup, // Initial state
  cutForDeal, // Players cut deck to determine dealer
  dealing, // Dealing cards
  bidding, // Auction in progress
  kittyExchange, // Contractor exchanges kitty cards
  play, // Playing tricks
  scoring, // Scoring completed hand
  gameOver, // Game finished
}

/// Immutable game state for 500
@immutable
class GameState {
  const GameState({
    // Game setup
    this.gameStarted = false,
    this.currentPhase = GamePhase.setup,
    this.dealer = Position.west, // Default dealer (player is South, dealer rotates)
    this.handNumber = 0,
    // Cut for deal
    this.cutCards = const {},
    // Scores
    this.teamNorthSouthScore = 0,
    this.teamEastWestScore = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    // Player info
    this.playerName = 'You',
    this.partnerName = 'Partner',
    this.opponentWestName = 'West',
    this.opponentEastName = 'East',
    // Hands (10 cards each when dealt)
    this.playerHand = const [], // South (human player)
    this.partnerHand = const [], // North
    this.opponentWestHand = const [],
    this.opponentEastHand = const [],
    this.kitty = const [], // 5 cards
    // Bidding phase
    this.isBiddingPhase = false,
    this.bidHistory = const [],
    this.currentBidder,
    this.currentHighBid,
    this.winningBid,
    this.contractor,
    // Play phase
    this.isPlayPhase = false,
    this.trumpSuit, // null for no-trump
    this.currentTrick,
    this.completedTricks = const [],
    this.currentPlayer,
    this.tricksWonNS = 0,
    this.tricksWonEW = 0,
    // UI state
    this.selectedCardIndices = const {},
    this.gameStatus = '',
    this.showGameOverDialog = false,
    this.gameOverData,
    this.scoreAnimation,
    this.showBiddingDialog = false,
    this.pendingBidEntry,
    this.aiThinkingPosition, // Which AI is currently "thinking"
    this.showSuitNominationDialog = false,
    this.pendingCardIndex,
    this.nominatedSuit,
  });

  // Game setup
  final bool gameStarted;
  final GamePhase currentPhase;
  final Position dealer;
  final int handNumber;

  // Cut for deal
  final Map<Position, PlayingCard> cutCards; // Cards drawn during cut for deal

  // Scores
  final int teamNorthSouthScore;
  final int teamEastWestScore;
  final int gamesWon;
  final int gamesLost;

  // Player info
  final String playerName;
  final String partnerName;
  final String opponentWestName;
  final String opponentEastName;

  // Hands
  final List<PlayingCard> playerHand; // South (human)
  final List<PlayingCard> partnerHand; // North
  final List<PlayingCard> opponentWestHand; // West
  final List<PlayingCard> opponentEastHand; // East
  final List<PlayingCard> kitty;

  // Bidding phase
  final bool isBiddingPhase;
  final List<BidEntry> bidHistory;
  final Position? currentBidder;
  final Bid? currentHighBid;
  final Bid? winningBid;
  final Position? contractor;

  // Play phase
  final bool isPlayPhase;
  final Suit? trumpSuit;
  final Trick? currentTrick;
  final List<Trick> completedTricks;
  final Position? currentPlayer;
  final int tricksWonNS; // North-South team
  final int tricksWonEW; // East-West team

  // UI state
  final Set<int> selectedCardIndices; // For kitty discard - indices of selected cards
  final String gameStatus;
  final bool showGameOverDialog;
  final GameOverData? gameOverData;
  final ScoreAnimation? scoreAnimation;
  final bool showBiddingDialog;
  final BidEntry? pendingBidEntry; // Last bid that was made (for display)
  final Position? aiThinkingPosition; // Show "thinking" indicator
  final bool showSuitNominationDialog; // Show suit nomination dialog
  final int? pendingCardIndex; // Card index pending suit nomination
  final Suit? nominatedSuit; // Nominated suit for joker in no-trump

  /// Get hand for a specific position
  List<PlayingCard> getHand(Position position) {
    switch (position) {
      case Position.north:
        return partnerHand;
      case Position.south:
        return playerHand;
      case Position.east:
        return opponentEastHand;
      case Position.west:
        return opponentWestHand;
    }
  }

  /// Get name for a specific position
  String getName(Position position) {
    switch (position) {
      case Position.north:
        return partnerName;
      case Position.south:
        return playerName;
      case Position.east:
        return opponentEastName;
      case Position.west:
        return opponentWestName;
    }
  }

  /// Get tricks won for a team
  int getTricksWon(Team team) {
    switch (team) {
      case Team.northSouth:
        return tricksWonNS;
      case Team.eastWest:
        return tricksWonEW;
    }
  }

  /// Get score for a team
  int getScore(Team team) {
    switch (team) {
      case Team.northSouth:
        return teamNorthSouthScore;
      case Team.eastWest:
        return teamEastWestScore;
    }
  }

  GameState copyWith({
    bool? gameStarted,
    GamePhase? currentPhase,
    Position? dealer,
    int? handNumber,
    Map<Position, PlayingCard>? cutCards,
    int? teamNorthSouthScore,
    int? teamEastWestScore,
    int? gamesWon,
    int? gamesLost,
    String? playerName,
    String? partnerName,
    String? opponentWestName,
    String? opponentEastName,
    List<PlayingCard>? playerHand,
    List<PlayingCard>? partnerHand,
    List<PlayingCard>? opponentWestHand,
    List<PlayingCard>? opponentEastHand,
    List<PlayingCard>? kitty,
    bool? isBiddingPhase,
    List<BidEntry>? bidHistory,
    Position? currentBidder,
    Bid? currentHighBid,
    Bid? winningBid,
    Position? contractor,
    bool? isPlayPhase,
    Suit? trumpSuit,
    Trick? currentTrick,
    List<Trick>? completedTricks,
    Position? currentPlayer,
    int? tricksWonNS,
    int? tricksWonEW,
    Set<int>? selectedCardIndices,
    String? gameStatus,
    bool? showGameOverDialog,
    GameOverData? gameOverData,
    ScoreAnimation? scoreAnimation,
    bool? showBiddingDialog,
    BidEntry? pendingBidEntry,
    Position? aiThinkingPosition,
    bool? showSuitNominationDialog,
    int? pendingCardIndex,
    Suit? nominatedSuit,
    // Special handling for nullable fields
    bool clearCurrentBidder = false,
    bool clearCurrentHighBid = false,
    bool clearWinningBid = false,
    bool clearContractor = false,
    bool clearTrumpSuit = false,
    bool clearCurrentTrick = false,
    bool clearCurrentPlayer = false,
    bool clearSelectedCardIndices = false,
    bool clearGameOverData = false,
    bool clearScoreAnimation = false,
    bool clearPendingBidEntry = false,
    bool clearAiThinkingPosition = false,
    bool clearPendingCardIndex = false,
    bool clearNominatedSuit = false,
  }) {
    return GameState(
      gameStarted: gameStarted ?? this.gameStarted,
      currentPhase: currentPhase ?? this.currentPhase,
      dealer: dealer ?? this.dealer,
      handNumber: handNumber ?? this.handNumber,
      cutCards: cutCards ?? this.cutCards,
      teamNorthSouthScore: teamNorthSouthScore ?? this.teamNorthSouthScore,
      teamEastWestScore: teamEastWestScore ?? this.teamEastWestScore,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      playerName: playerName ?? this.playerName,
      partnerName: partnerName ?? this.partnerName,
      opponentWestName: opponentWestName ?? this.opponentWestName,
      opponentEastName: opponentEastName ?? this.opponentEastName,
      playerHand: playerHand ?? this.playerHand,
      partnerHand: partnerHand ?? this.partnerHand,
      opponentWestHand: opponentWestHand ?? this.opponentWestHand,
      opponentEastHand: opponentEastHand ?? this.opponentEastHand,
      kitty: kitty ?? this.kitty,
      isBiddingPhase: isBiddingPhase ?? this.isBiddingPhase,
      bidHistory: bidHistory ?? this.bidHistory,
      currentBidder: clearCurrentBidder ? null : (currentBidder ?? this.currentBidder),
      currentHighBid: clearCurrentHighBid ? null : (currentHighBid ?? this.currentHighBid),
      winningBid: clearWinningBid ? null : (winningBid ?? this.winningBid),
      contractor: clearContractor ? null : (contractor ?? this.contractor),
      isPlayPhase: isPlayPhase ?? this.isPlayPhase,
      trumpSuit: clearTrumpSuit ? null : (trumpSuit ?? this.trumpSuit),
      currentTrick: clearCurrentTrick ? null : (currentTrick ?? this.currentTrick),
      completedTricks: completedTricks ?? this.completedTricks,
      currentPlayer: clearCurrentPlayer ? null : (currentPlayer ?? this.currentPlayer),
      tricksWonNS: tricksWonNS ?? this.tricksWonNS,
      tricksWonEW: tricksWonEW ?? this.tricksWonEW,
      selectedCardIndices: clearSelectedCardIndices ? {} : (selectedCardIndices ?? this.selectedCardIndices),
      gameStatus: gameStatus ?? this.gameStatus,
      showGameOverDialog: showGameOverDialog ?? this.showGameOverDialog,
      gameOverData: clearGameOverData ? null : (gameOverData ?? this.gameOverData),
      scoreAnimation: clearScoreAnimation ? null : (scoreAnimation ?? this.scoreAnimation),
      showBiddingDialog: showBiddingDialog ?? this.showBiddingDialog,
      pendingBidEntry: clearPendingBidEntry ? null : (pendingBidEntry ?? this.pendingBidEntry),
      aiThinkingPosition: clearAiThinkingPosition ? null : (aiThinkingPosition ?? this.aiThinkingPosition),
      showSuitNominationDialog: showSuitNominationDialog ?? this.showSuitNominationDialog,
      pendingCardIndex: clearPendingCardIndex ? null : (pendingCardIndex ?? this.pendingCardIndex),
      nominatedSuit: clearNominatedSuit ? null : (nominatedSuit ?? this.nominatedSuit),
    );
  }
}

/// Data for game over dialog
@immutable
class GameOverData {
  const GameOverData({
    required this.winningTeam,
    required this.finalScoreNS,
    required this.finalScoreEW,
    required this.status,
    required this.gamesWon,
    required this.gamesLost,
  });

  final Team winningTeam;
  final int finalScoreNS;
  final int finalScoreEW;
  final GameOverStatus status;
  final int gamesWon;
  final int gamesLost;
}

/// Score animation for showing points scored
@immutable
class ScoreAnimation {
  const ScoreAnimation({
    required this.points,
    required this.team,
    required this.timestamp,
  });

  final int points;
  final Team team;
  final int timestamp;
}
