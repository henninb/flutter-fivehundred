import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import '../logic/five_hundred_scorer.dart';

/// Sentinel used by copyWith to distinguish "keep existing value" from "set to null".
const _absent = Object();

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
    this.dealer =
        Position.west, // Default dealer (player is South, dealer rotates)
    this.handNumber = 0,
    // Cut for deal
    this.cutDeck = const [],
    this.cutCards = const {},
    this.playerHasSelectedCutCard = false,
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
    this.bidHistory = const [],
    this.currentBidder,
    this.currentHighBid,
    this.winningBid,
    this.contractor,
    // Play phase
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
    this.canPlayerClaimRemainingTricks = false,
  });

  // Game setup
  final bool gameStarted;
  final GamePhase currentPhase;
  final Position dealer;
  final int handNumber;

  // Cut for deal
  final List<PlayingCard> cutDeck; // Spread deck shown to player for cutting
  final Map<Position, PlayingCard> cutCards; // Cards drawn during cut for deal
  final bool
      playerHasSelectedCutCard; // Whether player has tapped a card from spread deck

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
  final List<BidEntry> bidHistory;
  final Position? currentBidder;
  final Bid? currentHighBid;
  final Bid? winningBid;
  final Position? contractor;

  // Play phase
  final Suit? trumpSuit;
  final Trick? currentTrick;
  final List<Trick> completedTricks;
  final Position? currentPlayer;
  final int tricksWonNS; // North-South team
  final int tricksWonEW; // East-West team

  // UI state
  final Set<int>
      selectedCardIndices; // For kitty discard - indices of selected cards
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
  final bool
      canPlayerClaimRemainingTricks; // True if player can guarantee winning all remaining tricks

  // Computed phase checks (derived from currentPhase — no manual sync needed)
  bool get isBiddingPhase => currentPhase == GamePhase.bidding;
  bool get isPlayPhase => currentPhase == GamePhase.play;

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

  /// Returns a copy of this state with specified fields replaced.
  ///
  /// For nullable fields, pass [null] explicitly to clear them (e.g.,
  /// `copyWith(currentBidder: null)`). Omitting a nullable field keeps the
  /// existing value.
  GameState copyWith({
    bool? gameStarted,
    GamePhase? currentPhase,
    Position? dealer,
    int? handNumber,
    List<PlayingCard>? cutDeck,
    Map<Position, PlayingCard>? cutCards,
    bool? playerHasSelectedCutCard,
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
    List<BidEntry>? bidHistory,
    Object? currentBidder = _absent,
    Object? currentHighBid = _absent,
    Object? winningBid = _absent,
    Object? contractor = _absent,
    Object? trumpSuit = _absent,
    Object? currentTrick = _absent,
    List<Trick>? completedTricks,
    Object? currentPlayer = _absent,
    int? tricksWonNS,
    int? tricksWonEW,
    Set<int>? selectedCardIndices,
    String? gameStatus,
    bool? showGameOverDialog,
    Object? gameOverData = _absent,
    Object? scoreAnimation = _absent,
    bool? showBiddingDialog,
    Object? pendingBidEntry = _absent,
    Object? aiThinkingPosition = _absent,
    bool? showSuitNominationDialog,
    Object? pendingCardIndex = _absent,
    Object? nominatedSuit = _absent,
    bool? canPlayerClaimRemainingTricks,
  }) {
    return GameState(
      gameStarted: gameStarted ?? this.gameStarted,
      currentPhase: currentPhase ?? this.currentPhase,
      dealer: dealer ?? this.dealer,
      handNumber: handNumber ?? this.handNumber,
      cutDeck: cutDeck ?? this.cutDeck,
      cutCards: cutCards ?? this.cutCards,
      playerHasSelectedCutCard:
          playerHasSelectedCutCard ?? this.playerHasSelectedCutCard,
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
      bidHistory: bidHistory ?? this.bidHistory,
      currentBidder: currentBidder == _absent
          ? this.currentBidder
          : currentBidder as Position?,
      currentHighBid: currentHighBid == _absent
          ? this.currentHighBid
          : currentHighBid as Bid?,
      winningBid:
          winningBid == _absent ? this.winningBid : winningBid as Bid?,
      contractor:
          contractor == _absent ? this.contractor : contractor as Position?,
      trumpSuit: trumpSuit == _absent ? this.trumpSuit : trumpSuit as Suit?,
      currentTrick: currentTrick == _absent
          ? this.currentTrick
          : currentTrick as Trick?,
      completedTricks: completedTricks ?? this.completedTricks,
      currentPlayer: currentPlayer == _absent
          ? this.currentPlayer
          : currentPlayer as Position?,
      tricksWonNS: tricksWonNS ?? this.tricksWonNS,
      tricksWonEW: tricksWonEW ?? this.tricksWonEW,
      selectedCardIndices: selectedCardIndices ?? this.selectedCardIndices,
      gameStatus: gameStatus ?? this.gameStatus,
      showGameOverDialog: showGameOverDialog ?? this.showGameOverDialog,
      gameOverData: gameOverData == _absent
          ? this.gameOverData
          : gameOverData as GameOverData?,
      scoreAnimation: scoreAnimation == _absent
          ? this.scoreAnimation
          : scoreAnimation as ScoreAnimation?,
      showBiddingDialog: showBiddingDialog ?? this.showBiddingDialog,
      pendingBidEntry: pendingBidEntry == _absent
          ? this.pendingBidEntry
          : pendingBidEntry as BidEntry?,
      aiThinkingPosition: aiThinkingPosition == _absent
          ? this.aiThinkingPosition
          : aiThinkingPosition as Position?,
      showSuitNominationDialog:
          showSuitNominationDialog ?? this.showSuitNominationDialog,
      pendingCardIndex: pendingCardIndex == _absent
          ? this.pendingCardIndex
          : pendingCardIndex as int?,
      nominatedSuit:
          nominatedSuit == _absent ? this.nominatedSuit : nominatedSuit as Suit?,
      canPlayerClaimRemainingTricks:
          canPlayerClaimRemainingTricks ?? this.canPlayerClaimRemainingTricks,
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
