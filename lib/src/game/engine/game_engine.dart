import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import '../logic/deal_utils.dart';
import '../logic/bidding_engine.dart';
import '../logic/bidding_ai.dart';
import '../logic/trick_engine.dart';
import '../logic/play_ai.dart';
import '../logic/trump_rules.dart';
import '../logic/five_hundred_scorer.dart';
import '../../services/game_persistence.dart';
import 'game_state.dart';

/// Game engine for 500
///
/// Orchestrates the entire game flow:
/// 1. Setup & Deal
/// 2. Bidding (4-way auction)
/// 3. Kitty Exchange (contractor picks up and discards)
/// 4. Trick Play (10 tricks)
/// 5. Scoring
/// 6. Repeat or Game Over
class GameEngine extends ChangeNotifier {
  GameEngine({GamePersistence? persistence})
      : _persistence = persistence,
        _state = const GameState();

  // ignore: unused_field
  final GamePersistence? _persistence;
  GameState _state;

  GameState get state => _state;

  // Timers for AI delays
  Timer? _aiTimer;

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // GAME LIFECYCLE
  // ============================================================================

  /// Initialize game (load saved state if available)
  Future<void> initialize() async {
    // For now, just start fresh
    // TODO: Implement state persistence
    notifyListeners();
  }

  /// Start a new game
  void startNewGame() {
    _updateState(const GameState(
      gameStarted: true,
      currentPhase: GamePhase.setup,
      gameStatus: 'Tap Cut for Deal to determine dealer',
    ));
  }

  /// Perform cut for deal - each player draws a card, highest card deals
  void cutForDeal() {
    final deck = createDeck();

    // Each player cuts (draws) a random card from the deck
    final cutCards = <Position, PlayingCard>{};
    final usedIndices = <int>{};
    final random = Random();

    for (final position in Position.values) {
      int index;
      do {
        index = random.nextInt(deck.length);
      } while (usedIndices.contains(index));

      usedIndices.add(index);
      cutCards[position] = deck[index];
    }

    // Determine winner immediately
    Position? highestPosition;
    int highestRank = -1;
    int highestSuit = 999; // Lower is better (hearts=0 is best)

    // First check if anyone drew the Joker - Joker always wins
    for (final entry in cutCards.entries) {
      if (entry.value.isJoker) {
        highestPosition = entry.key;
        break;
      }
    }

    // If no Joker, find highest card
    if (highestPosition == null) {
      for (final entry in cutCards.entries) {
        final card = entry.value;
        final position = entry.key;

        final rank = card.rank.index;
        final suit = card.suit.index;

        // Compare: higher rank wins, or if same rank, lower suit index wins (hearts=0 best)
        if (rank > highestRank || (rank == highestRank && suit < highestSuit)) {
          highestRank = rank;
          highestSuit = suit;
          highestPosition = position;
        }
      }
    }

    // Set dealer and update status - show cut results on same screen
    if (highestPosition != null) {
      final winnerName = _state.getName(highestPosition);
      final winningCard = cutCards[highestPosition]!;
      _updateState(_state.copyWith(
        currentPhase: GamePhase.cutForDeal,
        cutCards: cutCards,
        dealer: highestPosition,
        gameStatus: '$winnerName wins with ${winningCard.label} and will deal. Tap Deal to start.',
      ));
    }
  }

  /// Deal cards
  void dealCards() {
    final deck = createDeck();
    final dealResult = dealHand(deck: deck, dealer: _state.dealer);

    // Sort player's hand by suit for easier viewing
    final sortedPlayerHand = sortHandBySuit(dealResult.hands[Position.north]!);

    _updateState(_state.copyWith(
      currentPhase: GamePhase.dealing,
      playerHand: sortedPlayerHand,
      partnerHand: dealResult.hands[Position.south],
      opponentEastHand: dealResult.hands[Position.east],
      opponentWestHand: dealResult.hands[Position.west],
      kitty: dealResult.kitty,
      handNumber: _state.handNumber + 1,
      cutCards: {}, // Clear cut cards after dealing
      gameStatus: 'Cards dealt',
    ));

    // Start bidding after brief delay
    Future.delayed(const Duration(milliseconds: 500), _startBidding);
  }

  // ============================================================================
  // BIDDING PHASE
  // ============================================================================

  void _startBidding() {
    final biddingEngine = BiddingEngine(dealer: _state.dealer);
    final biddingOrder = biddingEngine.getBiddingOrder();

    _updateState(_state.copyWith(
      currentPhase: GamePhase.bidding,
      isBiddingPhase: true,
      bidHistory: [],
      currentBidder: biddingOrder.first,
      gameStatus: 'Bidding: ${_state.getName(biddingOrder.first)}',
      clearCurrentHighBid: true,
      clearWinningBid: true,
      clearContractor: true,
    ));

    // If first bidder is AI, trigger AI bidding
    if (biddingOrder.first != Position.north) {
      _scheduleAIBid();
    } else {
      _updateState(_state.copyWith(showBiddingDialog: true));
    }
  }

  /// Player submits a bid
  void submitPlayerBid(Bid? bid, {bool isInkle = false}) {
    if (_state.currentBidder != Position.north) return;

    final biddingEngine = BiddingEngine(dealer: _state.dealer);

    // Validate bid
    final validation = biddingEngine.validateBid(
      bidder: Position.north,
      proposedBid: bid,
      currentBids: _state.bidHistory,
      isInkle: isInkle,
    );

    if (!validation.isValid) {
      _updateState(_state.copyWith(
        gameStatus: validation.errorMessage ?? 'Invalid bid',
      ));
      return;
    }

    // Add bid to history
    final action = bid == null
        ? BidAction.pass
        : (isInkle ? BidAction.inkle : BidAction.bid);
    final entry = BidEntry(bidder: Position.north, action: action, bid: bid);

    _addBidEntry(entry);
    _updateState(_state.copyWith(showBiddingDialog: false));

    // Check if auction complete
    _checkAuctionComplete();
  }

  /// AI makes a bid
  void _scheduleAIBid() {
    if (_state.currentBidder == null) return;
    if (_state.currentBidder == Position.north) return;

    _updateState(_state.copyWith(
      aiThinkingPosition: _state.currentBidder,
    ));

    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 800), () {
      _executeAIBid();
    });
  }

  void _executeAIBid() {
    final position = _state.currentBidder;
    if (position == null || position == Position.north) return;

    final hand = _state.getHand(position);
    final biddingEngine = BiddingEngine(dealer: _state.dealer);

    // Get AI decision
    final decision = BiddingAI.chooseBid(
      hand: hand,
      currentBids: _state.bidHistory,
      position: position,
      canInkle: biddingEngine.canInkle(position, _state.bidHistory),
    );

    // Add bid to history
    final entry = BidEntry(
      bidder: position,
      action: decision.action,
      bid: decision.bid,
    );

    _addBidEntry(entry);

    // Check if auction complete
    _checkAuctionComplete();
  }

  void _addBidEntry(BidEntry entry) {
    final newHistory = [..._state.bidHistory, entry];

    // Update high bid if this is a real bid (not pass, not inkle)
    Bid? newHighBid = _state.currentHighBid;
    if (entry.bid != null && entry.action == BidAction.bid) {
      if (newHighBid == null || entry.bid!.beats(newHighBid)) {
        newHighBid = entry.bid;
      }
    }

    _updateState(_state.copyWith(
      bidHistory: newHistory,
      currentHighBid: newHighBid,
      pendingBidEntry: entry,
      gameStatus: entry.toString(),
      clearAiThinkingPosition: true,
    ));
  }

  void _checkAuctionComplete() {
    final biddingEngine = BiddingEngine(dealer: _state.dealer);

    if (!biddingEngine.isComplete(_state.bidHistory)) {
      // More bids needed - advance to next bidder
      final nextBidder = biddingEngine.getNextBidder(_state.bidHistory);
      _updateState(_state.copyWith(
        currentBidder: nextBidder,
        gameStatus: nextBidder != null
            ? 'Bidding: ${_state.getName(nextBidder)}'
            : 'Auction complete',
      ));

      if (nextBidder != null && nextBidder != Position.north) {
        _scheduleAIBid();
      } else if (nextBidder == Position.north) {
        _updateState(_state.copyWith(showBiddingDialog: true));
      }
      return;
    }

    // Auction complete - determine result
    final result = biddingEngine.determineWinner(_state.bidHistory);

    switch (result.status) {
      case AuctionStatus.won:
        _updateState(_state.copyWith(
          isBiddingPhase: false,
          winningBid: result.winningBid,
          contractor: result.winner,
          gameStatus: result.message,
          clearCurrentBidder: true,
        ));
        // Start kitty exchange
        Future.delayed(const Duration(milliseconds: 1000), _startKittyExchange);
        break;

      case AuctionStatus.redeal:
        _updateState(_state.copyWith(
          isBiddingPhase: false,
          gameStatus: result.message,
          clearCurrentBidder: true,
        ));
        // Redeal after delay
        Future.delayed(const Duration(milliseconds: 2000), dealCards);
        break;

      case AuctionStatus.incomplete:
        // Shouldn't happen, but just in case
        break;
    }
  }

  // ============================================================================
  // KITTY EXCHANGE
  // ============================================================================

  void _startKittyExchange() {
    final contractor = _state.contractor;
    if (contractor == null) return;

    _updateState(_state.copyWith(
      currentPhase: GamePhase.kittyExchange,
      gameStatus: '${_state.getName(contractor)} exchanges kitty',
    ));

    if (contractor == Position.north) {
      // Player picks up kitty
      final newHand = [..._state.playerHand, ..._state.kitty];

      // Sort hand with trump consideration (we know trump from winning bid)
      final trumpSuit = _getBidSuitAsTrumpSuit();
      final sortedHand = sortHandBySuit(newHand, trumpSuit: trumpSuit);

      _updateState(_state.copyWith(
        playerHand: sortedHand,
        kitty: [],
        gameStatus: 'Select 5 cards to discard',
      ));
    } else {
      // AI picks up kitty and discards
      Future.delayed(const Duration(milliseconds: 1000), _executeAIKittyExchange);
    }
  }

  void _executeAIKittyExchange() {
    final contractor = _state.contractor;
    if (contractor == null || contractor == Position.north) return;

    var hand = _state.getHand(contractor);
    hand = [...hand, ..._state.kitty];

    // AI strategy: Keep highest cards (simple for now)
    // TODO: Improve AI to keep trump and high cards in trump suit
    final trumpRules = TrumpRules(trumpSuit: _getBidSuitAsTrumpSuit());
    hand.sort((a, b) => trumpRules.compare(b, a)); // Sort high to low

    final kept = hand.take(10).toList();

    // Update hand
    switch (contractor) {
      case Position.south:
        _updateState(_state.copyWith(partnerHand: kept));
        break;
      case Position.east:
        _updateState(_state.copyWith(opponentEastHand: kept));
        break;
      case Position.west:
        _updateState(_state.copyWith(opponentWestHand: kept));
        break;
      case Position.north:
        break; // Already handled
    }

    _startPlay();
  }

  /// Player confirms kitty exchange (discards selected 5 cards)
  void confirmKittyExchange() {
    if (_state.contractor != Position.north) return;

    // Must have exactly 5 cards selected
    if (_state.selectedCardIndices.length != 5) {
      _updateState(_state.copyWith(
        gameStatus: 'Must select exactly 5 cards to discard',
      ));
      return;
    }

    // Remove selected cards from hand
    final newHand = <PlayingCard>[];
    for (int i = 0; i < _state.playerHand.length; i++) {
      if (!_state.selectedCardIndices.contains(i)) {
        newHand.add(_state.playerHand[i]);
      }
    }

    // Should have exactly 10 cards remaining
    if (newHand.length != 10) {
      _updateState(_state.copyWith(
        gameStatus: 'Error: Wrong number of cards after discard',
      ));
      return;
    }

    // Update state and start play
    _updateState(_state.copyWith(
      playerHand: newHand,
      clearSelectedCardIndices: true,
      gameStatus: 'Discarded 5 cards',
    ));

    _startPlay();
  }

  /// Player toggles card selection for kitty exchange
  void toggleCardSelection(int index) {
    if (_state.currentPhase != GamePhase.kittyExchange) return;
    if (_state.contractor != Position.north) return;

    final selectedIndices = Set<int>.from(_state.selectedCardIndices);

    // Toggle: if already selected, deselect; otherwise select
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      // Only allow selecting up to 5 cards
      if (selectedIndices.length < 5) {
        selectedIndices.add(index);
      }
    }

    final remaining = 5 - selectedIndices.length;
    final statusMessage = remaining == 0
        ? 'Click Discard to continue'
        : 'Select $remaining more card(s) to discard';

    _updateState(_state.copyWith(
      selectedCardIndices: selectedIndices,
      gameStatus: statusMessage,
    ));
  }

  Suit? _getBidSuitAsTrumpSuit() {
    if (_state.winningBid == null) return null;
    switch (_state.winningBid!.suit) {
      case BidSuit.spades:
        return Suit.spades;
      case BidSuit.clubs:
        return Suit.clubs;
      case BidSuit.diamonds:
        return Suit.diamonds;
      case BidSuit.hearts:
        return Suit.hearts;
      case BidSuit.noTrump:
        return null;
    }
  }

  // ============================================================================
  // PLAY PHASE
  // ============================================================================

  void _startPlay() {
    final trumpSuit = _getBidSuitAsTrumpSuit();
    final leader = _state.contractor!; // Contractor leads

    // Re-sort player's hand with trump consideration
    // (In case player wasn't contractor and hand still sorted by natural suits)
    final sortedPlayerHand = sortHandBySuit(_state.playerHand, trumpSuit: trumpSuit);

    _updateState(_state.copyWith(
      currentPhase: GamePhase.play,
      isPlayPhase: true,
      trumpSuit: trumpSuit,
      playerHand: sortedPlayerHand,
      currentTrick: Trick(plays: [], leader: leader, trumpSuit: trumpSuit),
      completedTricks: [],
      tricksWonNS: 0,
      tricksWonEW: 0,
      currentPlayer: leader,
      gameStatus: '${_state.getName(leader)} leads',
      clearSelectedCardIndices: true,
    ));

    // If AI leads, schedule AI play
    if (leader != Position.north) {
      _scheduleAIPlay();
    }
  }

  /// Player plays a card
  void playCard(int cardIndex) {
    if (_state.currentPlayer != Position.north) return;
    if (_state.currentTrick == null) return;

    final card = _state.playerHand[cardIndex];
    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // Play the card
    final result = trickEngine.playCard(
      currentTrick: _state.currentTrick!,
      card: card,
      player: Position.north,
      playerHand: _state.playerHand,
    );

    if (result.status == TrickStatus.error) {
      _updateState(_state.copyWith(gameStatus: result.message));
      return;
    }

    // Remove card from hand
    final newHand = List<PlayingCard>.from(_state.playerHand);
    newHand.removeAt(cardIndex);

    _updateState(_state.copyWith(
      playerHand: newHand,
      currentTrick: result.trick,
      gameStatus: result.message,
      clearSelectedCardIndices: true,
    ));

    if (result.status == TrickStatus.complete) {
      _handleTrickComplete(result.trick, result.winner!);
    } else {
      // Advance to next player
      _advanceToNextPlayer();
    }
  }

  void _advanceToNextPlayer() {
    final nextPlayer = _state.currentPlayer!.next;
    _updateState(_state.copyWith(
      currentPlayer: nextPlayer,
      gameStatus: '${_state.getName(nextPlayer)}\'s turn',
    ));

    if (nextPlayer != Position.north) {
      _scheduleAIPlay();
    }
  }

  void _scheduleAIPlay() {
    _updateState(_state.copyWith(aiThinkingPosition: _state.currentPlayer));

    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 600), _executeAIPlay);
  }

  void _executeAIPlay() {
    final position = _state.currentPlayer;
    if (position == null || position == Position.north) return;
    if (_state.currentTrick == null) return;

    final hand = _state.getHand(position);
    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // AI chooses card
    final card = PlayAI.chooseCard(
      hand: hand,
      currentTrick: _state.currentTrick!,
      trumpRules: trumpRules,
      position: position,
      partner: position.partner,
      trickEngine: trickEngine,
    );

    // Play the card
    final result = trickEngine.playCard(
      currentTrick: _state.currentTrick!,
      card: card,
      player: position,
      playerHand: hand,
    );

    // Remove card from hand
    final newHand = List<PlayingCard>.from(hand);
    newHand.remove(card);

    switch (position) {
      case Position.south:
        _updateState(_state.copyWith(partnerHand: newHand));
        break;
      case Position.east:
        _updateState(_state.copyWith(opponentEastHand: newHand));
        break;
      case Position.west:
        _updateState(_state.copyWith(opponentWestHand: newHand));
        break;
      case Position.north:
        break;
    }

    _updateState(_state.copyWith(
      currentTrick: result.trick,
      gameStatus: result.message,
      clearAiThinkingPosition: true,
    ));

    if (result.status == TrickStatus.complete) {
      _handleTrickComplete(result.trick, result.winner!);
    } else {
      _advanceToNextPlayer();
    }
  }

  void _handleTrickComplete(Trick trick, Position winner) {
    // Add trick to completed tricks
    final newCompleted = [..._state.completedTricks, trick];

    // Update tricks won
    final winnerTeam = winner.team;
    var newTricksNS = _state.tricksWonNS;
    var newTricksEW = _state.tricksWonEW;

    if (winnerTeam == Team.northSouth) {
      newTricksNS++;
    } else {
      newTricksEW++;
    }

    _updateState(_state.copyWith(
      completedTricks: newCompleted,
      tricksWonNS: newTricksNS,
      tricksWonEW: newTricksEW,
      gameStatus: '${_state.getName(winner)} wins trick',
    ));

    // Check if all tricks played
    if (newCompleted.length == 10) {
      // Last trick - give extra time to see the cards before scoring
      Future.delayed(const Duration(milliseconds: 3000), _scoreHand);
    } else {
      // Start next trick with winner leading
      Future.delayed(const Duration(milliseconds: 2500), () {
        _startNextTrick(winner);
      });
    }
  }

  void _startNextTrick(Position leader) {
    _updateState(_state.copyWith(
      currentTrick: Trick(
        plays: [],
        leader: leader,
        trumpSuit: _state.trumpSuit,
      ),
      currentPlayer: leader,
      gameStatus: '${_state.getName(leader)} leads',
      clearSelectedCardIndices: true,
    ));

    if (leader != Position.north) {
      _scheduleAIPlay();
    }
  }

  // ============================================================================
  // SCORING
  // ============================================================================

  void _scoreHand() {
    if (_state.winningBid == null || _state.contractor == null) return;

    final contractorTeam = _state.contractor!.team;
    final contractorTricks = _state.getTricksWon(contractorTeam);
    final opponentTricks = _state.getTricksWon(
      contractorTeam == Team.northSouth ? Team.eastWest : Team.northSouth,
    );

    final handScore = FiveHundredScorer.scoreHand(
      contract: _state.winningBid!,
      contractorTricks: contractorTricks,
      opponentTricks: opponentTricks,
    );

    // Apply scores
    var newScoreNS = _state.teamNorthSouthScore;
    var newScoreEW = _state.teamEastWestScore;

    if (contractorTeam == Team.northSouth) {
      newScoreNS += handScore.contractorPoints;
      newScoreEW += handScore.opponentPoints;
    } else {
      newScoreEW += handScore.contractorPoints;
      newScoreNS += handScore.opponentPoints;
    }

    _updateState(_state.copyWith(
      currentPhase: GamePhase.scoring,
      isPlayPhase: false,
      teamNorthSouthScore: newScoreNS,
      teamEastWestScore: newScoreEW,
      gameStatus: FiveHundredScorer.getHandResultDescription(
        contract: _state.winningBid!,
        score: handScore,
        contractorTeam: contractorTeam,
      ),
    ));

    // Show score animation
    if (handScore.contractorPoints != 0) {
      _updateState(_state.copyWith(
        scoreAnimation: ScoreAnimation(
          points: handScore.contractorPoints,
          team: contractorTeam,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      ));

      Timer(const Duration(seconds: 2), () {
        _updateState(_state.copyWith(clearScoreAnimation: true));
      });
    }

    // Check game over
    final gameOverStatus = FiveHundredScorer.checkGameOver(
      teamNSScore: newScoreNS,
      teamEWScore: newScoreEW,
    );

    if (gameOverStatus != null) {
      // Delay before showing game over to let user see final trick and score
      Future.delayed(const Duration(milliseconds: 3000), () {
        _handleGameOver(gameOverStatus, newScoreNS, newScoreEW);
      });
    }
    // Otherwise, stay in scoring phase - user must click "Next Hand" to continue
  }

  /// Start the next hand (public for UI button)
  void startNextHand() {
    final nextDealer = getNextDealer(_state.dealer);

    _updateState(_state.copyWith(
      currentPhase: GamePhase.setup,
      dealer: nextDealer,
      playerHand: [],
      partnerHand: [],
      opponentEastHand: [],
      opponentWestHand: [],
      kitty: [],
      bidHistory: [],
      completedTricks: [],
      tricksWonNS: 0,
      tricksWonEW: 0,
      gameStatus: 'Tap Deal for next hand',
      clearCurrentBidder: true,
      clearCurrentHighBid: true,
      clearWinningBid: true,
      clearContractor: true,
      clearTrumpSuit: true,
      clearCurrentTrick: true,
      clearCurrentPlayer: true,
      clearPendingBidEntry: true,
    ));
  }

  void _handleGameOver(
    GameOverStatus status,
    int finalScoreNS,
    int finalScoreEW,
  ) {
    final winningTeam = (status == GameOverStatus.teamNSWins ||
            status == GameOverStatus.teamEWLoses)
        ? Team.northSouth
        : Team.eastWest;

    final playerWon = winningTeam == Team.northSouth;

    _updateState(_state.copyWith(
      currentPhase: GamePhase.gameOver,
      showGameOverDialog: true,
      gameOverData: GameOverData(
        winningTeam: winningTeam,
        finalScoreNS: finalScoreNS,
        finalScoreEW: finalScoreEW,
        status: status,
        gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
        gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
      ),
      gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
      gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
      gameStatus: FiveHundredScorer.getGameOverMessage(
        status,
        finalScoreNS,
        finalScoreEW,
      ),
    ));
  }

  /// Dismiss game over dialog and reset for new game
  void dismissGameOverDialog() {
    _updateState(_state.copyWith(
      showGameOverDialog: false,
      clearGameOverData: true,
    ));

    // Reset to setup
    _updateState(GameState(
      gameStarted: true,
      currentPhase: GamePhase.setup,
      dealer: Position.west,
      gamesWon: _state.gamesWon,
      gamesLost: _state.gamesLost,
      gameStatus: 'Tap Deal to start',
    ));
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void _updateState(GameState newState) {
    _state = newState;
    notifyListeners();
  }
}
