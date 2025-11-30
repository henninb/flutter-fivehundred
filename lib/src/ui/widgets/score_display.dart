import 'package:flutter/material.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';

/// Modern score display for 500
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
  });

  final int scoreNS;
  final int scoreEW;
  final int tricksNS;
  final int tricksEW;
  final Suit? trumpSuit;
  final Bid? winningBid;
  final Position? dealer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surface,
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildTeamScore(
                context,
                'N-S',
                scoreNS,
                tricksNS,
                Team.northSouth,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            _buildCenterInfo(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            Expanded(
              child: _buildTeamScore(
                context,
                'W-E',
                scoreEW,
                tricksEW,
                Team.eastWest,
              ),
            ),
          ],
        ),
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
    final isContractor = winningBid?.bidder.team == team;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isContractor
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            teamName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isContractor
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          score.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Tricks: $tricks',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterInfo(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dealer indicator
          if (dealer != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.casino_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Dealer',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _positionLabel(dealer!),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
          // Spacing between dealer and bid
          if (dealer != null && winningBid != null) const SizedBox(height: 12),
          // Bid info
          if (winningBid != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gavel,
                  size: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _positionLabel(winningBid!.bidder),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.secondaryContainer,
                    Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _bidLabel(winningBid!),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ],
        ],
      ),
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
}
