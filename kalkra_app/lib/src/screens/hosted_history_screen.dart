import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../providers/hosted_session_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/global_drawer.dart';

class HostedHistoryScreen extends ConsumerWidget {
  const HostedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(currentScreenIdProvider.notifier)
          .setScreenId('HostedHistoryScreen');
    });

    final history = ref.watch(hostedSessionProvider);
    final sessionManager = ref.read(hostedSessionProvider.notifier);
    final bannedIds = sessionManager.getBannedDeviceIds();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: isDesktop
          ? const TopNavBar(activeId: 'HostedHistoryScreen')
          : AppBar(
              title: const Text('HOSTED SESSIONS'),
              backgroundColor: colorScheme.secondary,
              foregroundColor: Colors.white,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
      body: VectorBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SectionHeader(title: 'BANNED PLAYERS (${bannedIds.length})'),
            const SizedBox(height: 16),
            if (bannedIds.isEmpty)
              _EmptyCard(message: 'NO ACTIVE BANS', icon: Icons.gavel_rounded)
            else
              ...bannedIds.map(
                (id) => _BanCard(
                  deviceId: id,
                  onUnban: () => sessionManager.unbanDevice(id),
                ),
              ),

            const SizedBox(height: 48),
            _SectionHeader(title: 'SESSION LOGS'),
            const SizedBox(height: 16),
            if (history.isEmpty)
              _EmptyCard(
                message: 'NO HOSTED SESSIONS YET',
                icon: Icons.history_rounded,
              )
            else
              ...history.map(
                (record) => _SessionRecordCard(
                  record: record,
                  bannedIds: bannedIds,
                  onBan: (id) => sessionManager.banDevice(id),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        fontSize: 12,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyCard({required this.message, required this.icon});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BanCard extends StatelessWidget {
  final String deviceId;
  final VoidCallback onUnban;
  const _BanCard({required this.deviceId, required this.onUnban});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.block_rounded, color: Colors.red),
        title: Text(
          deviceId,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        trailing: TextButton(onPressed: onUnban, child: const Text('UNBAN')),
      ),
    );
  }
}

class _SessionRecordCard extends StatelessWidget {
  final HostedSessionRecord record;
  final List<String> bannedIds;
  final Function(String) onBan;
  const _SessionRecordCard({
    required this.record,
    required this.bannedIds,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(record.date),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${record.participants.length} PLAYERS • ${record.difficulty.toUpperCase()} • ${record.rounds} ROUNDS',
            ),
            trailing: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: record.participants.map((p) {
                final isBanned = bannedIds.contains(p.deviceId);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.secondary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          p.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${p.score} PTS',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!isBanned)
                        IconButton(
                          onPressed: () => onBan(p.deviceId),
                          icon: const Icon(
                            Icons.gavel_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'BAN PLAYER',
                        )
                      else
                        const Icon(
                          Icons.block_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
