import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';
import 'player_list_item.dart';

/// A zone representing a team and its players.
class TeamZone extends StatelessWidget {
  final int teamId;
  final SessionManager session;
  final bool isHost;
  final ColorScheme colorScheme;
  final Function(String, int) onAssign;
  final Function(int, String) onRename;
  final double minHeight;

  const TeamZone({
    super.key,
    required this.teamId,
    required this.session,
    required this.isHost,
    required this.colorScheme,
    required this.onAssign,
    required this.onRename,
    this.minHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    final teamPlayers = session.players.entries
        .where((e) => e.value.teamId == teamId)
        .toList();
    final teamColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    final color = teamColors[(teamId - 1) % 4];
    final teamName = session.teamNames[teamId] ?? 'Team $teamId';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(teamName, color, context),
        const SizedBox(height: 8),
        _buildDragTarget(teamPlayers, color),
      ],
    );
  }

  Widget _buildTitle(String name, Color color, BuildContext context) {
    return GestureDetector(
      onTap: isHost ? () => _showRenameDialog(context, name) : null,
      child: Row(
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 12,
              color: color,
            ),
          ),
          if (isHost)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.edit_rounded,
                size: 12,
                color: color.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDragTarget(
    List<MapEntry<String, PlayerSessionData>> players,
    Color color,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => isHost,
        onAcceptWithDetails: (details) => onAssign(details.data, teamId),
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? color.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? color
                    : color.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: players.isEmpty
                ? _buildEmpty(color)
                : _buildList(players, color),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(Color color) {
    return Container(
      height: minHeight,
      alignment: Alignment.center,
      child: Icon(
        Icons.add_circle_outline_rounded,
        color: color.withValues(alpha: 0.2),
        size: 32,
      ),
    );
  }

  Widget _buildList(
    List<MapEntry<String, PlayerSessionData>> players,
    Color color,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return PlayerListItem(
          id: player.key,
          data: player.value,
          isHost: isHost,
          teamColor: color,
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final textController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'RENAME TEAM',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter team name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty)
                onRename(teamId, textController.text.trim());
              Navigator.pop(context);
            },
            child: const Text(
              'RENAME',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
