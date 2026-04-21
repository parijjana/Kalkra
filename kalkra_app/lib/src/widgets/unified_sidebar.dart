import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import 'package:intl/intl.dart';
import 'package:game_engine/game_engine.dart';

class UnifiedSidebar extends ConsumerStatefulWidget {
  final bool isCollapsible;
  final int? matchScore;
  final int? secondsLeft;
  final String? roundText;
  final JeopardyType? jeopardy;
  final List<String>? attemptHistory;
  final VoidCallback? onResign;

  const UnifiedSidebar({
    super.key,
    this.isCollapsible = true,
    this.matchScore,
    this.secondsLeft,
    this.roundText,
    this.jeopardy,
    this.attemptHistory,
    this.onResign,
  });

  @override
  ConsumerState<UnifiedSidebar> createState() => _UnifiedSidebarState();
}

class _UnifiedSidebarState extends ConsumerState<UnifiedSidebar> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final career = ref.watch(careerProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? 380 : 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          if (widget.isCollapsible)
            Align(
              alignment: _isExpanded ? Alignment.centerLeft : Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(_isExpanded ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
                ),
              ),
            ),

          if (_isExpanded)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Live Match Intel (If applicable)
                    if (widget.secondsLeft != null) ...[
                      _SidebarSection(
                        title: 'LIVE INTEL',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.roundText ?? '', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10)),
                            const SizedBox(height: 4),
                            Text('${widget.secondsLeft}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 48, color: widget.secondsLeft! < 10 ? Colors.redAccent : colorScheme.onSurface)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MATCH SCORE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1, color: Colors.grey)),
                                    Text('${widget.matchScore ?? 0}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: colorScheme.primary)),
                                  ],
                                ),
                                if (widget.jeopardy != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                                    child: Text(widget.jeopardy!.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.black)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // 2. Leaderboard
                    _SidebarSection(
                      title: 'LEADERBOARD',
                      child: _buildLeaderboard(session, colorScheme),
                    ),
                    const SizedBox(height: 32),

                    // 3. Attempt History (Specific to current round)
                    if (widget.attemptHistory != null && widget.attemptHistory!.isNotEmpty) ...[
                      _SidebarSection(
                        title: 'RECENT ATTEMPTS',
                        child: Column(
                          children: widget.attemptHistory!.take(3).map((h) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                            child: Text(h, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // 4. Battle History (Career)
                    _SidebarSection(
                      title: 'BATTLE HISTORY',
                      child: _buildHistory(career, colorScheme),
                    ),
                    const SizedBox(height: 32),

                    // 5. Global News
                    _SidebarSection(
                      title: 'GLOBAL NEWS',
                      child: _buildNews(colorScheme),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _CollapsedIcon(icon: Icons.leaderboard_rounded, color: colorScheme.primary),
                  _CollapsedIcon(icon: Icons.history_rounded, color: colorScheme.secondary),
                  _CollapsedIcon(icon: Icons.newspaper_rounded, color: colorScheme.tertiary),
                ],
              ),
            ),
          
          if (_isExpanded && widget.onResign != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onResign,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                  child: const Text('RESIGN MATCH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(SessionManager session, ColorScheme colorScheme) {
    if (session.players.isEmpty) {
      return const Text('SOLO TRAINING IN PROGRESS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold));
    }

    final sortedPlayers = session.players.entries.toList()
      ..sort((a, b) => b.value.cumulativeScore.compareTo(a.value.cumulativeScore));

    return Column(
      children: sortedPlayers.take(5).map((entry) {
        final p = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Text(p.name[0], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(p.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))),
              Text('${p.cumulativeScore}', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.secondary, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistory(CareerManager career, ColorScheme colorScheme) {
    if (career.rivals.isEmpty) {
      return const Text('NO RECENT ACTIVITY', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold));
    }

    return Column(
      children: career.rivals.take(3).map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(r.wasSolo ? Icons.person_outline_rounded : Icons.bolt_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    Text(DateFormat('MMM dd').format(r.date), style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                '${r.eloShift >= 0 ? "+" : ""}${r.eloShift}',
                style: TextStyle(fontWeight: FontWeight.w900, color: r.eloShift >= 0 ? Colors.green : Colors.red, fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNews(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VER 1.2.0', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            'New themes added: Midnight Cyber & Retro Arcade.',
            style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CollapsedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CollapsedIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Icon(icon, color: color.withValues(alpha: 0.3), size: 24),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SidebarSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
