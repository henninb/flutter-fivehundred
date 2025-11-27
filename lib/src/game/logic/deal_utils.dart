import '../models/card.dart';
import '../models/game_models.dart';

/// Result of dealing cards for 500
class DealResult {
  DealResult({
    required this.hands,
    required this.kitty,
  });

  final Map<Position, List<PlayingCard>> hands;
  final List<PlayingCard> kitty;
}

/// Deal cards for 500
///
/// Deal pattern: 3-3-4-4-3-3 with kitty dealt in the middle
/// - Round 1: 3 cards to each player (12 cards)
/// - Kitty: 3 cards to kitty (15 cards total)
/// - Round 2: 4 cards to each player (31 cards)
/// - Kitty: 2 more cards to kitty (33 cards total)
/// - Round 3: 3 cards to each player (45 cards total)
///
/// Result: Each player has 10 cards, kitty has 5 cards
DealResult dealHand({
  required List<PlayingCard> deck,
  required Position dealer,
}) {
  if (deck.length != 45) {
    throw ArgumentError('Deck must have exactly 45 cards (got ${deck.length})');
  }

  final drawDeck = List<PlayingCard>.from(deck);
  final hands = <Position, List<PlayingCard>>{
    Position.north: [],
    Position.south: [],
    Position.east: [],
    Position.west: [],
  };
  final kitty = <PlayingCard>[];

  // Get dealing order (starts with player to dealer's left, goes clockwise)
  final dealingOrder = _getDealingOrder(dealer);

  // Round 1: 3 cards to each player
  for (int i = 0; i < 3; i++) {
    for (final position in dealingOrder) {
      hands[position]!.add(drawDeck.removeAt(0));
    }
  }

  // Kitty: 3 cards
  for (int i = 0; i < 3; i++) {
    kitty.add(drawDeck.removeAt(0));
  }

  // Round 2: 4 cards to each player
  for (int i = 0; i < 4; i++) {
    for (final position in dealingOrder) {
      hands[position]!.add(drawDeck.removeAt(0));
    }
  }

  // Kitty: 2 more cards
  for (int i = 0; i < 2; i++) {
    kitty.add(drawDeck.removeAt(0));
  }

  // Round 3: 3 cards to each player
  for (int i = 0; i < 3; i++) {
    for (final position in dealingOrder) {
      hands[position]!.add(drawDeck.removeAt(0));
    }
  }

  // Verify
  assert(hands[Position.north]!.length == 10);
  assert(hands[Position.south]!.length == 10);
  assert(hands[Position.east]!.length == 10);
  assert(hands[Position.west]!.length == 10);
  assert(kitty.length == 5);
  assert(drawDeck.isEmpty);

  return DealResult(hands: hands, kitty: kitty);
}

/// Get dealing order starting from dealer's left
List<Position> _getDealingOrder(Position dealer) {
  final order = <Position>[];
  var current = dealer.next; // Start with player to dealer's left
  for (int i = 0; i < 4; i++) {
    order.add(current);
    current = current.next;
  }
  return order;
}

/// Get next dealer (rotates clockwise)
Position getNextDealer(Position currentDealer) {
  return currentDealer.next;
}
