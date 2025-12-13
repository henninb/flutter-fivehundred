import 'package:flutter/material.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/models/game_models.dart';

/// Game over modal with polished design showing the winner and final scores.
///
/// Displays a full-screen overlay with the winning team, final score, and
/// overall game statistics. The modal uses a gradient background (green for
/// player win, red for loss) and can be dismissed by tapping anywhere.
class GameOverModal extends StatelessWidget {
  const GameOverModal({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  final GameOverData data;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final playerWon = data.winningTeam == Team.northSouth;
    final winnerName = playerWon ? 'North-South' : 'East-West';

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Theme.of(context).colorScheme.surface.withAlpha(242),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: GestureDetector(
                onTap: onDismiss,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          playerWon
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                          playerWon
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trophy/Crown Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(77)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withAlpha(77),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              playerWon ? Icons.emoji_events : Icons.close,
                              size: 40,
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Winner Name
                          Text(
                            '$winnerName Won!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: playerWon
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Final Score
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(77)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withAlpha(77),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Final Score',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data.finalScoreNS} - ${data.finalScoreEW}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Statistics Grid
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(51)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Statistics',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _StatRow(
                                  label: 'Record',
                                  value: '${data.gamesWon} - ${data.gamesLost}',
                                  icon: Icons.sports_score,
                                  isPlayerWin: playerWon,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tap anywhere instruction
                          Text(
                            'Tap anywhere to continue',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: playerWon
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withAlpha(204)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer
                                          .withAlpha(204),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat row widget for statistics display
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isPlayerWin,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isPlayerWin;

  @override
  Widget build(BuildContext context) {
    final textColor = isPlayerWin
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;

    return Row(
      children: [
        Icon(
          icon,
          color: textColor.withAlpha(179),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withAlpha(204),
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
