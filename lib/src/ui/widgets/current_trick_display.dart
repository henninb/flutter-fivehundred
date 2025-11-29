import 'package:flutter/material.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';

/// Displays the current trick information: led suit and winning team
class CurrentTrickDisplay extends StatelessWidget {
  const CurrentTrickDisplay({
    super.key,
    required this.trick,
    this.currentWinner,
  });

  final Trick? trick;
  final Position? currentWinner;

  @override
  Widget build(BuildContext context) {
    // Don't show if no trick in progress
    if (trick == null || trick!.isEmpty) {
      return const SizedBox.shrink();
    }

    final ledSuit = trick!.ledSuit;
    final winningTeam = currentWinner?.team;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(128),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Led suit indicator
          if (ledSuit != null) ...[
            Text(
              'Led:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 6),
            Text(
              _suitLabel(ledSuit),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    height: 1.0,
                  ),
            ),
          ],
          // Separator
          if (ledSuit != null && winningTeam != null) ...[
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 20,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(width: 16),
          ],
          // Winning team indicator
          if (winningTeam != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getTeamColor(context, winningTeam),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_teamLabel(winningTeam)} winning',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTeamTextColor(context, winningTeam),
                    ),
              ),
            ),
          ],
        ],
      ),
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

  String _teamLabel(Team team) {
    switch (team) {
      case Team.northSouth:
        return 'N-S';
      case Team.eastWest:
        return 'W-E';
    }
  }

  Color _getTeamColor(BuildContext context, Team team) {
    switch (team) {
      case Team.northSouth:
        return Theme.of(context).colorScheme.primaryContainer;
      case Team.eastWest:
        return Theme.of(context).colorScheme.tertiaryContainer;
    }
  }

  Color _getTeamTextColor(BuildContext context, Team team) {
    switch (team) {
      case Team.northSouth:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case Team.eastWest:
        return Theme.of(context).colorScheme.onTertiaryContainer;
    }
  }
}
