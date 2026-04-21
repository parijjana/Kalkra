import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/vector_background.dart';

import '../widgets/global_drawer.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('HistoryScreen');
    });
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final career = ref.watch(careerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: GlobalDrawer(),
      appBar: ResponsiveLayout.isDesktop(context) ? const TopNavBar(activeId: 'HistoryScreen') : AppBar(
        title: const Text('BATTLE HISTORY'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: VectorBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BATTLE HISTORY', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text('RECORDS OF YOUR PREVIOUS ENGAGEMENTS', style: TextStyle(letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w900, fontSize: 10)),
                  
                  const SizedBox(height: 48),

                  if (career.rivals.isEmpty)
                    _buildEmptyState(colorScheme)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: career.rivals.length,
                      itemBuilder: (context, i) {
                        final rival = career.rivals[i];
                        return _buildHistoryCard(rival, colorScheme);
                      },
                    ),
                  
                  const SizedBox(height: 60),
                  _buildNewsSection(colorScheme, theme),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 24),
            Text('NO RECENT ACTIVITY RECORDED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.onSurface.withValues(alpha: 0.2))),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(dynamic rival, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: rival.wasSolo ? colorScheme.tertiary.withValues(alpha: 0.1) : colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(rival.wasSolo ? Icons.person_outline_rounded : Icons.bolt_rounded, color: rival.wasSolo ? colorScheme.tertiary : colorScheme.primary),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rival.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(DateFormat('MMMM dd, yyyy • HH:mm').format(rival.date), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${rival.eloShift >= 0 ? "+" : ""}${rival.eloShift}',
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 28, 
                  color: rival.eloShift >= 0 ? Colors.green : Colors.redAccent,
                  letterSpacing: -1,
                ),
              ),
              const Text('ELO SHIFT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 2, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primaryContainer]),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.newspaper_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Text('GLOBAL NEWS FEED', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 32),
          _NewsItem(title: 'VERSION 1.2.0 DEPLOYED', desc: 'Unified Top Navigation Bar implemented. Sidebar architecture deprecated for maximized analytical density.'),
          _NewsItem(title: 'NEW THEMES: MIDNIGHT & RETRO', desc: 'High-contrast Cyber and classic Arcade palettes are now available in Account Preferences.'),
        ],
      ),
    );
  }
}

class _NewsItem extends StatelessWidget {
  final String title;
  final String desc;
  const _NewsItem({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}
