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
    final careerAsync = ref.watch(careerProvider);

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
                      const SizedBox(height: 24),
                    ],

                    // 2. Profile Quick-View
                    careerAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Center(child: Icon(Icons.error_outline, color: Colors.red)),
                      data: (career) => _SidebarSection(
                        title: 'IDENTITY',
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary,
                              child: Text(career.playerName[0].toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(career.playerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  Text('${career.elo} ELO', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Attempt History
                    if (widget.attemptHistory != null && widget.attemptHistory!.isNotEmpty)
                      _SidebarSection(
                        title: 'RECENT LOG',
                        child: Column(
                          children: widget.attemptHistory!.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 12, color: colorScheme.primary.withValues(alpha: 0.5)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(a, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    
                    const SizedBox(height: 48),

                    // 4. Resign Action
                    if (widget.onResign != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onResign,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('RESIGN MATCH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
