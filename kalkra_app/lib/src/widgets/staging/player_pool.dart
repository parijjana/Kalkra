import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';
import 'player_list_item.dart';

/// A scrollable pool of unassigned players.
class PlayerPool extends StatelessWidget {
  final SessionManager session;
  final bool isHost;
  final ColorScheme colorScheme;
  final Function(String, int) onAssign;

  const PlayerPool({
    super.key,
    required this.session,
    required this.isHost,
    required this.colorScheme,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final unassigned = session.players.entries
        .where((e) => e.value.teamId == 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UNASSIGNED',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => isHost,
            onAcceptWithDetails: (details) => onAssign(details.data, 0),
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unassigned.length,
                  itemBuilder: (context, index) {
                    final player = unassigned[index];
                    return PlayerListItem(
                      id: player.key,
                      data: player.value,
                      isHost: isHost,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
