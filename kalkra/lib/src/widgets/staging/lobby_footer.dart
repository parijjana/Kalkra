import 'package:flutter/material.dart';

/// Footer controls for the lobby (Ready, Start Match, Shuffle).
class LobbyFooter extends StatelessWidget {
  final bool isHost;
  final bool isReady;
  final bool canStart;
  final ColorScheme colorScheme;
  final VoidCallback onToggleReady;
  final VoidCallback onStartMatch;
  final VoidCallback onShuffle;

  const LobbyFooter({
    super.key,
    required this.isHost,
    required this.isReady,
    required this.canStart,
    required this.colorScheme,
    required this.onToggleReady,
    required this.onStartMatch,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24), // Slightly reduced padding
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool useColumn = isHost && constraints.maxWidth < 450;

          if (useColumn) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isHost) ...[
                      IconButton(
                        onPressed: onShuffle,
                        icon: const Icon(Icons.shuffle_rounded),
                        tooltip: 'Randomize Teams',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _buildReadyButton(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildStartButton(),
                ),
              ],
            );
          }

          return Row(
            children: [
              if (isHost) ...[
                IconButton(
                  onPressed: onShuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  tooltip: 'Randomize Teams',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _buildReadyButton(),
              ),
              if (isHost) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStartButton(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadyButton() {
    return ElevatedButton.icon(
      onPressed: onToggleReady,
      icon: Icon(
        isReady
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
      ),
      label: FittedBox(child: Text(isReady ? 'READY' : 'MARK READY')),
      style: ElevatedButton.styleFrom(
        backgroundColor: isReady ? Colors.green : colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed: canStart ? onStartMatch : null,
      icon: const Icon(Icons.play_arrow_rounded),
      label: const FittedBox(child: Text('START MATCH')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}
