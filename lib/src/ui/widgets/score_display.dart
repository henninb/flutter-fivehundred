import 'package:flutter/material.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';

/// Simple score display for 500
class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({
    super.key,
    required this.scoreNS,
    required this.scoreEW,
    required this.tricksNS,
    required this.tricksEW,
    this.trumpSuit,
    this.contract,
  });

  final int scoreNS;
  final int scoreEW;
  final int tricksNS;
  final int tricksEW;
  final Suit? trumpSuit;
  final String? contract;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTeamScore(
            context,
            'N-S',
            scoreNS,
            tricksNS,
            Team.northSouth,
          ),
          if (trumpSuit != null || contract != null) ...[
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _buildGameInfo(context),
          ],
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          _buildTeamScore(
            context,
            'E-W',
            scoreEW,
            tricksEW,
            Team.eastWest,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScore(
    BuildContext context,
    String teamName,
    int score,
    int tricks,
    Team team,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          teamName,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tricks: $tricks',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildGameInfo(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trumpSuit != null) ...[
          Text(
            'Trump',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _suitLabel(trumpSuit!),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ] else if (contract != null) ...[
          Text(
            'No Trump',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ],
    );
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
