import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

/// A draggable player item in the lobby.
class PlayerListItem extends StatelessWidget {
  final String id;
  final PlayerSessionData data;
  final bool isHost;
  final Color? teamColor;

  const PlayerListItem({
    super.key,
    required this.id,
    required this.data,
    required this.isHost,
    this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.isReady ? Colors.green : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: (teamColor ?? Colors.blue).withValues(alpha: 0.1),
            child: Text(
              data.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: teamColor ?? Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (data.isReady)
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 16,
            ),
        ],
      ),
    );

    if (!isHost) return content;

    return Draggable<String>(
      data: id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 200, child: content),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: content),
      child: content,
    );
  }
}
