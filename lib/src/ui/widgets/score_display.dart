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
    this.winningBid,
    this.dealer,
    this.ledSuit,
    this.currentWinner,
  });

  final int scoreNS;
  final int scoreEW;
  final int tricksNS;
  final int tricksEW;
  final Suit? trumpSuit;
  final Bid? winningBid;
  final Position? dealer;
  final Suit? ledSuit;
  final Position? currentWinner;

  @override
  Widget build(BuildContext context) {
    final showTrickInfo = ledSuit != null || currentWinner != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top section: Scores and center info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamScore(
                context,
                'N-S',
                scoreNS,
                tricksNS,
                Team.northSouth,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _buildCenterInfo(context),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _buildTeamScore(
                context,
                'W-E',
                scoreEW,
                tricksEW,
                Team.eastWest,
              ),
            ],
          ),
          // Bottom section: Led suit and winning team
          if (showTrickInfo) ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 8),
            _buildTrickInfo(context),
          ],
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
        ),
      ],
    );
  }

  Widget _buildCenterInfo(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dealer indicator
        if (dealer != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.style,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  _positionLabel(dealer!),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        // Bid info
        if (winningBid != null) ...[
          Text(
            'Bid',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            _bidLabel(winningBid!),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ],
    );
  }

  String _positionLabel(Position position) {
    switch (position) {
      case Position.north:
        return 'North';
      case Position.south:
        return 'South';
      case Position.east:
        return 'East';
      case Position.west:
        return 'West';
    }
  }

  String _bidLabel(Bid bid) {
    final tricks = bid.tricks;
    if (bid.suit == BidSuit.noTrump) {
      return '$tricks NT';
    }

    final suitSymbol = _suitLabelFromBidSuit(bid.suit);
    return '$tricks $suitSymbol';
  }

  String _suitLabelFromBidSuit(BidSuit bidSuit) {
    switch (bidSuit) {
      case BidSuit.spades:
        return '♠';
      case BidSuit.hearts:
        return '♥';
      case BidSuit.diamonds:
        return '♦';
      case BidSuit.clubs:
        return '♣';
      case BidSuit.noTrump:
        return 'NT';
    }
  }

  Widget _buildTrickInfo(BuildContext context) {
    final winningTeam = currentWinner?.team;

    return Row(
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
            _suitLabel(ledSuit!),
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
