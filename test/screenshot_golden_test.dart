import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fivehundred/src/game/engine/game_engine.dart';
import 'package:fivehundred/src/game/engine/game_state.dart';
import 'package:fivehundred/src/game/logic/trick_engine.dart';
import 'package:fivehundred/src/game/logic/trump_rules.dart';
import 'package:fivehundred/src/game/models/card.dart';
import 'package:fivehundred/src/game/models/game_models.dart';
import 'package:fivehundred/src/models/game_settings.dart';
import 'package:fivehundred/src/models/theme_models.dart';
import 'package:fivehundred/src/ui/screens/game_screen.dart';
import 'package:fivehundred/src/ui/theme/theme_definitions.dart';

class PreviewGameEngine extends GameEngine {
  PreviewGameEngine(this.previewState) : super(persistence: null);

  GameState previewState;

  @override
  GameState get state => previewState;

  @override
  Position? getCurrentTrickWinner() {
    final trick = previewState.currentTrick;
    if (trick == null || trick.isEmpty) {
      return null;
    }
    final rules = TrumpRules(trumpSuit: previewState.trumpSuit);
    return TrickEngine(trumpRules: rules).getCurrentWinner(trick);
  }
}

Future<void> _pumpGolden({
  required WidgetTester tester,
  required GameState state,
  required FiveHundredTheme theme,
  required String goldenName,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = GameSettings(selectedTheme: theme.type);
  final engine = PreviewGameEngine(state);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.toThemeData(),
      home: GameScreen(
        engine: engine,
        currentTheme: theme,
        onThemeChange: (_) {},
        currentSettings: settings,
        onSettingsChange: (_) {},
      ),
    ),
  );

  await tester.pumpAndSettle();
  await expectLater(
    find.byType(GameScreen),
    matchesGoldenFile('goldens/$goldenName.png'),
  );
}

void main() {
  testWidgets('App Store welcome screenshot', (tester) async {
    const state = GameState(
      gameStatus:
          'Classic trick-taking with crisp bidding, smart AI, and seasonal themes.',
    );

    await _pumpGolden(
      tester: tester,
      state: state,
      theme: ThemeDefinitions.summer,
      goldenName: 'screenshot_welcome',
    );
  });

  testWidgets('App Store in-play screenshot', (tester) async {
    final hand = sortHandBySuit(
      const [
        PlayingCard(rank: Rank.joker, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.ten, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.clubs),
        PlayingCard(rank: Rank.nine, suit: Suit.diamonds),
        PlayingCard(rank: Rank.eight, suit: Suit.clubs),
      ],
      trumpSuit: Suit.hearts,
    );

    final trick = Trick(
      plays: const [
        CardPlay(
          card: PlayingCard(rank: Rank.ace, suit: Suit.hearts),
          player: Position.west,
        ),
        CardPlay(
          card: PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
          player: Position.north,
        ),
        CardPlay(
          card: PlayingCard(rank: Rank.king, suit: Suit.hearts),
          player: Position.east,
        ),
      ],
      leader: Position.west,
      trumpSuit: Suit.hearts,
    );

    final state = GameState(
      gameStarted: true,
      currentPhase: GamePhase.play,
      isPlayPhase: true,
      dealer: Position.west,
      handNumber: 4,
      teamNorthSouthScore: 320,
      teamEastWestScore: 160,
      tricksWonNS: 3,
      tricksWonEW: 1,
      currentPlayer: Position.south,
      trumpSuit: Suit.hearts,
      winningBid: Bid(
        tricks: 8,
        suit: BidSuit.hearts,
        bidder: Position.south,
      ),
      contractor: Position.south,
      gameStatus: 'Trick 4 • Hearts trump — your move to capture the lead.',
      playerHand: hand,
      partnerHand: const [
        PlayingCard(rank: Rank.ten, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.diamonds),
      ],
      opponentEastHand: const [
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
      ],
      opponentWestHand: const [
        PlayingCard(rank: Rank.ten, suit: Suit.clubs),
      ],
      currentTrick: trick,
    );

    await _pumpGolden(
      tester: tester,
      state: state,
      theme: ThemeDefinitions.fall,
      goldenName: 'screenshot_in_play',
    );
  });
}
