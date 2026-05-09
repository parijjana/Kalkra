import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/vector_background.dart';
import 'calibration_screen.dart';
import '../widgets/global_drawer.dart';
import 'main_screen.dart';

enum MatchSetupMode { solo, host }

class MatchSetupScreen extends ConsumerStatefulWidget {
  final MatchSetupMode mode;
  const MatchSetupScreen({super.key, required this.mode});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  Difficulty _difficulty = Difficulty.medium;
  int _rounds = 5;
  bool _jeopardyEnabled = true;
  GameMode _gameMode = GameMode.practice;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('MatchSetupScreen');
    });

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        drawer: const GlobalDrawer(),
        appBar: isDesktop ? const TopNavBar(activeId: 'MainScreen') : _buildMobileAppBar(),
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        floatingActionButton: !isDesktop ? _buildFAB() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar _buildMobileAppBar() {
    return AppBar(
      title: const Text('MISSION CONTROL'),
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('CHOOSE MISSION'),
          const SizedBox(height: 16),
          _buildModeSelector(isDesktop: false),
          const SizedBox(height: 32),
          _buildSectionHeader('PARAMETERS'),
          const SizedBox(height: 16),
          if (_gameMode != GameMode.progressive) ...[
            _buildDifficultyDial(),
            const SizedBox(height: 24),
          ],
          if (_shouldShowRoundSelector) ...[
            _buildRoundSelector(),
            const SizedBox(height: 24),
          ],
          if (_gameMode != GameMode.progressive) _buildJeopardyToggle(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return VectorBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MISSION CONTROL', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
                Text('SYSTEM CALIBRATION AND VECTOR SELECTION', style: TextStyle(letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w900, fontSize: 11)),
                const SizedBox(height: 60),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pane 1: Modes
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('SELECT MISSION TYPE'),
                            const SizedBox(height: 24),
                            Expanded(child: SingleChildScrollView(child: _buildModeSelector(isDesktop: true))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 60),
                      // Pane 2: Parameters
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('CALIBRATION'),
                            const SizedBox(height: 24),
                            if (_gameMode != GameMode.progressive) ...[
                              _buildDifficultyDial(),
                              const SizedBox(height: 32),
                            ],
                            if (_shouldShowRoundSelector) ...[
                              _buildRoundSelector(),
                              const SizedBox(height: 32),
                            ],
                            if (_gameMode != GameMode.progressive) _buildJeopardyToggle(),
                            const Spacer(),
                            _buildStartButton(context, isLarge: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _shouldShowRoundSelector =>
      _gameMode == GameMode.practice ||
      _gameMode == GameMode.permutations ||
      _gameMode == GameMode.tunnelVision ||
      _gameMode == GameMode.powersOf2 ||
      _gameMode == GameMode.powersOf3;

  Widget _buildFAB() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FloatingActionButton.extended(
        onPressed: _startMatch,
        label: Text(widget.mode == MatchSetupMode.solo ? 'INITIATE SOLO MISSION' : 'OPEN MULTIPLAYER ARENA', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        icon: const Icon(Icons.play_arrow_rounded),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)));
  }

  Widget _buildModeSelector({required bool isDesktop}) {
    final colorScheme = Theme.of(context).colorScheme;
    final modes = [
      (mode: GameMode.practice, label: 'CLASSIC', desc: 'Standard rules.', icon: Icons.model_training_rounded),
      if (widget.mode == MatchSetupMode.solo)
        (mode: GameMode.endless, label: 'ENDLESS', desc: 'Survive the scaling.', icon: Icons.loop_rounded),
      (mode: GameMode.progressive, label: 'PROGRESSIVE', desc: 'Tiered challenges.', icon: Icons.trending_up_rounded),
      (mode: GameMode.tunnelVision, label: 'TUNNEL', desc: 'Persistent target.', icon: Icons.filter_center_focus_rounded),
      (mode: GameMode.powersOf2, label: "2'S POWERS", desc: 'Powers of 2 only.', icon: Icons.filter_2_rounded),
      (mode: GameMode.powersOf3, label: "3'S POWERS", desc: 'Powers of 3 only.', icon: Icons.filter_3_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: isDesktop ? const NeverScrollableScrollPhysics() : const ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.6 : 1.1,
      ),
      itemCount: modes.length,
      itemBuilder: (context, index) {
        final m = modes[index];
        final isSelected = _gameMode == m.mode;
        return GestureDetector(
          onTap: () => setState(() => _gameMode = m.mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: isSelected ? Border.all(color: Colors.white24, width: 2) : null,
              boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m.icon, color: isSelected ? Colors.white : colorScheme.primary, size: isDesktop ? 32 : 24),
                const SizedBox(height: 12),
                Text(m.label, style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.white : colorScheme.onSurface, fontSize: 10, letterSpacing: 1)),
                if (isDesktop) ...[
                  const SizedBox(height: 4),
                  Text(m.desc, style: TextStyle(fontSize: 8, color: (isSelected ? Colors.white : colorScheme.onSurface).withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyDial() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(40)),
      child: Row(children: Difficulty.values.map((d) {
          final isSelected = _difficulty == d;
          return Expanded(child: GestureDetector(
              onTap: () => setState(() => _difficulty = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: isSelected ? _getDifficultyColor(d) : Colors.transparent, borderRadius: BorderRadius.circular(34)),
                alignment: Alignment.center,
                child: Text(d.name.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
              ),
          ));
      }).toList()),
    );
  }

  Widget _buildRoundSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final roundOptions = [3, 5, 10];
    return Row(children: roundOptions.map((r) {
        final isSelected = _rounds == r;
        return Expanded(child: Padding(
            padding: EdgeInsets.only(right: r == 10 ? 0 : 12),
            child: GestureDetector(
              onTap: () => setState(() => _rounds = r),
              child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: isSelected ? colorScheme.secondary : colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)), alignment: Alignment.center, child: Column(children: [Text('$r', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : colorScheme.onSurface)), Text('ROUNDS', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1, color: isSelected ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.4)))]))),
        ));
    }).toList());
  }

  Widget _buildJeopardyToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
          Icon(Icons.bolt_rounded, color: colorScheme.tertiary, size: 20),
          const SizedBox(width: 16),
          const Expanded(child: Text('JEOPARDY MODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12))),
          Switch(value: _jeopardyEnabled, onChanged: (v) => setState(() => _jeopardyEnabled = v), activeTrackColor: colorScheme.tertiary),
      ]),
    );
  }

  Widget _buildStartButton(BuildContext context, {bool isLarge = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: _startMatch,
        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
        child: Text(widget.mode == MatchSetupMode.solo ? 'START MISSION' : 'START ARENA', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty d) {
    switch (d) { 
      case Difficulty.easy: return Colors.green; 
      case Difficulty.medium: return Colors.orange; 
      case Difficulty.hard: return Colors.redAccent; 
    }
  }

  Future<void> _startMatch() async {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => CalibrationScreen(
        totalRounds: (_gameMode == GameMode.progressive) ? 10 : (_gameMode == GameMode.endless ? 100 : _rounds),
        jeopardyEnabled: (_gameMode == GameMode.progressive || _gameMode == GameMode.endless) ? true : _jeopardyEnabled,
        gameMode: _gameMode,
        difficulty: _difficulty,
        setupMode: widget.mode,
      ),
    ));
  }
}
