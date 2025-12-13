import 'card.dart';

/// Test hand scenarios for debugging and testing
///
/// Each scenario defines a specific hand configuration for the human player
/// (South) to test various game situations.
class TestHandScenario {
  const TestHandScenario({
    required this.name,
    required this.description,
    required this.cards,
  });

  final String name;
  final String description;
  final List<PlayingCard> cards;
}

/// Constraint-based hand generation
class HandConstraint {
  const HandConstraint({
    required this.name,
    required this.description,
    this.minSuit,
    this.maxSuit,
    this.includeJoker = false,
    this.minHighCards = 0,
  });

  final String name;
  final String description;
  final Suit? minSuit; // Guarantee minimum cards of this suit
  final Suit? maxSuit; // Guarantee maximum cards of this suit
  final bool includeJoker;
  final int minHighCards; // Minimum Aces/Kings/Queens
}

/// Predefined test hand scenarios
class TestHands {
  static const List<TestHandScenario> scenarios = [
    // Perfect no-trump hand
    TestHandScenario(
      name: 'Perfect No-Trump',
      description: 'Strong balanced hand ideal for no-trump bid',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.ace, suit: Suit.diamonds),
        PlayingCard(rank: Rank.king, suit: Suit.diamonds),
        PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        PlayingCard(rank: Rank.king, suit: Suit.clubs),
        PlayingCard(rank: Rank.queen, suit: Suit.clubs),
        PlayingCard(rank: Rank.ten, suit: Suit.spades),
      ],
    ),

    // All spades (strong trump hand)
    TestHandScenario(
      name: 'Spades Powerhouse',
      description: 'Overwhelming spades for strong trump bid',
      cards: [
        PlayingCard(rank: Rank.joker, suit: Suit.spades),
        PlayingCard(rank: Rank.jack, suit: Suit.spades), // Right bower
        PlayingCard(rank: Rank.jack, suit: Suit.clubs), // Left bower
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
        PlayingCard(rank: Rank.ten, suit: Suit.spades),
        PlayingCard(rank: Rank.nine, suit: Suit.spades),
        PlayingCard(rank: Rank.eight, suit: Suit.spades),
        PlayingCard(rank: Rank.seven, suit: Suit.spades),
      ],
    ),

    // Minimal hand (weak)
    TestHandScenario(
      name: 'Weak Hand',
      description: 'Poor hand - should pass',
      cards: [
        PlayingCard(rank: Rank.four, suit: Suit.spades),
        PlayingCard(rank: Rank.five, suit: Suit.spades),
        PlayingCard(rank: Rank.six, suit: Suit.hearts),
        PlayingCard(rank: Rank.seven, suit: Suit.hearts),
        PlayingCard(rank: Rank.four, suit: Suit.diamonds),
        PlayingCard(rank: Rank.five, suit: Suit.diamonds),
        PlayingCard(rank: Rank.six, suit: Suit.clubs),
        PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        PlayingCard(rank: Rank.eight, suit: Suit.clubs),
        PlayingCard(rank: Rank.nine, suit: Suit.clubs),
      ],
    ),

    // Joker + mixed suits
    TestHandScenario(
      name: 'Joker Special',
      description: 'Test joker behavior with mixed hand',
      cards: [
        PlayingCard(rank: Rank.joker, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.nine, suit: Suit.spades),
        PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
        PlayingCard(rank: Rank.seven, suit: Suit.diamonds),
        PlayingCard(rank: Rank.six, suit: Suit.clubs),
        PlayingCard(rank: Rank.five, suit: Suit.clubs),
        PlayingCard(rank: Rank.four, suit: Suit.clubs),
      ],
    ),

    // Two-suited hand (hearts and diamonds)
    TestHandScenario(
      name: 'Two-Suited Red',
      description: 'Strong in hearts and diamonds',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.jack, suit: Suit.hearts),
        PlayingCard(rank: Rank.ten, suit: Suit.hearts),
        PlayingCard(rank: Rank.ace, suit: Suit.diamonds),
        PlayingCard(rank: Rank.king, suit: Suit.diamonds),
        PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
        PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
        PlayingCard(rank: Rank.ten, suit: Suit.diamonds),
      ],
    ),

    // Bowers test (both jacks of same color)
    TestHandScenario(
      name: 'Bower Test',
      description: 'Both jacks of same color for bower testing',
      cards: [
        PlayingCard(
          rank: Rank.jack,
          suit: Suit.spades,
        ), // Right bower in spades
        PlayingCard(rank: Rank.jack, suit: Suit.clubs), // Left bower in spades
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
        PlayingCard(rank: Rank.ten, suit: Suit.hearts),
        PlayingCard(rank: Rank.nine, suit: Suit.hearts),
        PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
        PlayingCard(rank: Rank.seven, suit: Suit.diamonds),
        PlayingCard(rank: Rank.six, suit: Suit.clubs),
      ],
    ),

    // 10-trick hand (slam potential)
    TestHandScenario(
      name: '10-Trick Slam',
      description: 'Powerful hand capable of winning all tricks',
      cards: [
        PlayingCard(rank: Rank.joker, suit: Suit.spades),
        PlayingCard(
          rank: Rank.jack,
          suit: Suit.hearts,
        ), // Right bower in hearts
        PlayingCard(
          rank: Rank.jack,
          suit: Suit.diamonds,
        ), // Left bower in hearts
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.ten, suit: Suit.hearts),
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.diamonds),
        PlayingCard(rank: Rank.ace, suit: Suit.clubs),
      ],
    ),

    // Void in one suit
    TestHandScenario(
      name: 'Void in Clubs',
      description: 'No clubs - test void suit behavior',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.ace, suit: Suit.diamonds),
        PlayingCard(rank: Rank.king, suit: Suit.diamonds),
        PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
        PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
      ],
    ),
  ];

  static const List<HandConstraint> constraints = [
    HandConstraint(
      name: '5+ Hearts',
      description: 'At least 5 hearts in hand',
      minSuit: Suit.hearts,
    ),
    HandConstraint(
      name: '5+ Spades',
      description: 'At least 5 spades in hand',
      minSuit: Suit.spades,
    ),
    HandConstraint(
      name: '5+ Diamonds',
      description: 'At least 5 diamonds in hand',
      minSuit: Suit.diamonds,
    ),
    HandConstraint(
      name: '5+ Clubs',
      description: 'At least 5 clubs in hand',
      minSuit: Suit.clubs,
    ),
    HandConstraint(
      name: 'With Joker',
      description: 'Random hand including the Joker',
      includeJoker: true,
    ),
    HandConstraint(
      name: 'High Cards (5+)',
      description: 'At least 5 Aces, Kings, or Queens',
      minHighCards: 5,
    ),
    HandConstraint(
      name: 'Balanced Hand',
      description: 'Roughly equal distribution across suits',
      // Special handling in generator
    ),
  ];
}
