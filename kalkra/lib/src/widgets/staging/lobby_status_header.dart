import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

/// A header displaying the current lobby status (players, assigned, ready).
class LobbyStatusHeader extends StatelessWidget {
  final ColorScheme colorScheme;
  final SessionManager session;
  final bool isHost;

  const LobbyStatusHeader({
    super.key,
    required this.colorScheme,
    required this.session,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final assignedCount = session.players.values
        .where((p) => p.teamId > 0)
        .length;
    final readyCount = session.players.values
        .where((p) => p.teamId > 0 && p.isReady)
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetric('PLAYERS', '${session.players.length}'),
          _buildDivider(),
          _buildMetric('ASSIGNED', '$assignedCount'),
          _buildDivider(),
          _buildMetric(
            'READY',
            '$readyCount/$assignedCount',
            color: readyCount == assignedCount && assignedCount > 0
                ? Colors.green
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }
}
