import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/game_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  void _showTooltip(BuildContext context, String title, String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(explanation, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final career = ref.watch(careerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('CAREER STATS'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Rank Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, const Color(0xFF5E35B1)],
                ),
                borderRadius: BorderRadius.circular(48),
              ),
              child: Column(
                children: [
                  const Text(
                    'CURRENT RANK',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${career.elo} ELO',
                    style: theme.textTheme.displayMedium?.copyWith(color: Colors.white, fontSize: 48),
                  ),
                  Text(
                    _getTier(career.elo),
                    style: TextStyle(color: colorScheme.tertiaryContainer, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _StatCard(
                  title: 'SPEED',
                  value: '${career.avgSpeedSeconds.toStringAsFixed(1)}s',
                  icon: Icons.bolt_rounded,
                  color: Colors.orange,
                  onInfo: () => _showTooltip(context, 'SPEED', 'Average number of seconds from the moment numbers appear to when you hit SUBMIT.'),
                ),
                _StatCard(
                  title: 'ACCURACY',
                  value: '±${career.avgAccuracy.toStringAsFixed(1)}',
                  icon: Icons.track_changes_rounded,
                  color: Colors.redAccent,
                  onInfo: () => _showTooltip(context, 'ACCURACY', 'The average difference between your mathematical result and the target number. Lower is better!'),
                ),
                _StatCard(
                  title: 'WINS',
                  value: '${career.matchesWon}',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber,
                  onInfo: () => _showTooltip(context, 'WINS', 'Total number of multiplayer sessions where you finished with the highest cumulative score.'),
                ),
                _StatCard(
                  title: 'BEST STREAK',
                  value: '${career.bestStreak}',
                  icon: Icons.whatshot_rounded,
                  color: Colors.deepOrange,
                  onInfo: () => _showTooltip(context, 'BEST STREAK', 'The highest number of consecutive rounds where you achieved an EXACT match to the target.'),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Recent Rivals
            Text(
              'RECENT RIVALS',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            if (career.rivals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No battle history yet!', style: TextStyle(color: Colors.black26)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: career.rivals.length,
                itemBuilder: (context, i) {
                  final rival = career.rivals[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.surface,
                        child: Text(rival.name.isNotEmpty ? rival.name[0] : '?'),
                      ),
                      title: Text(rival.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('MMM dd, HH:mm').format(rival.date)),
                      trailing: Text(
                        '${rival.eloShift > 0 ? "+" : ""}${rival.eloShift}',
                        style: TextStyle(
                          color: rival.eloShift >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getTier(int elo) {
    if (elo < 1000) return 'BRONZE TIER';
    if (elo < 1500) return 'SILVER TIER';
    if (elo < 2000) return 'GOLD TIER';
    return 'PLATINUM TIER';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onInfo;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              GestureDetector(
                onTap: onInfo,
                child: Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.2), size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
          ),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
