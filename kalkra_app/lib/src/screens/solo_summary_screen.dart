import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../widgets/vector_background.dart';
import '../widgets/global_drawer.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/top_nav_bar.dart';
import 'main_screen.dart';

class SoloSummaryScreen extends ConsumerWidget {
  const SoloSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('SoloSummaryScreen');
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final myScore = session.getPlayerScore('solo');
    final match = ref.read(matchProvider).value;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: isDesktop ? const TopNavBar(activeId: 'SoloSummaryScreen', showMenu: false) : null,
      body: VectorBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: isDesktop ? 100 : 60),
              Text('SOLO MATCH COMPLETE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: colorScheme.primary.withValues(alpha: 0.5), fontSize: isDesktop ? 14 : 12)),
              const SizedBox(height: 16),
              Text('MATCH SUMMARY', style: (isDesktop ? theme.textTheme.displayLarge : theme.textTheme.displayMedium)?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
              
              SizedBox(height: isDesktop ? 120 : 80),
              
              // Score Display
              Column(
                children: [
                  Text(
                    '$myScore',
                    style: TextStyle(fontSize: isDesktop ? 180 : 120, fontWeight: FontWeight.w900, color: colorScheme.primary, height: 1),
                  ),
                  Text('TOTAL POINTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 10, color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: isDesktop ? 18 : 14)),
                ],
              ),

              SizedBox(height: isDesktop ? 100 : 60),

              // Match Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatTile(label: 'ROUNDS', value: '${match?.totalRounds ?? 0}', isDesktop: isDesktop),
                    _StatTile(label: 'MODE', value: match?.gameMode.name.toUpperCase() ?? 'PRACTICE', isDesktop: isDesktop),
                  ],
                ),
              ),

              const Spacer(),

              // Navigation
              Padding(
                padding: EdgeInsets.only(bottom: isDesktop ? 100 : 60),
                child: SizedBox(
                  width: isDesktop ? 400 : 300,
                  height: isDesktop ? 80 : 64,
                  child: ElevatedButton(
                    onPressed: () {
                      session.resetScores();
                      ref.read(matchProvider).value = null;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MainScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.onSurface,
                      foregroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    ),
                    child: Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: isDesktop ? 20 : 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDesktop;

  const _StatTile({required this.label, required this.value, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: isDesktop ? 32 : 24)),
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: isDesktop ? 12 : 10, letterSpacing: 2, color: colorScheme.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }
}
