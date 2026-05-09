import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../services/playtest_service.dart';
import '../widgets/vector_background.dart';
import 'match_setup_screen.dart';

class PlaytestLoginScreen extends ConsumerStatefulWidget {
  const PlaytestLoginScreen({super.key});

  @override
  ConsumerState<PlaytestLoginScreen> createState() => _PlaytestLoginScreenState();
}

class _PlaytestLoginScreenState extends ConsumerState<PlaytestLoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    // Wait for playtest service to initialize
    await ref.read(playtestServiceProvider.future);
    final existingName = ref.read(playtestServiceProvider.notifier).playerName;
    
    if (existingName != null && mounted) {
      _navigateToSetup();
    } else {
      setState(() => _loading = false);
    }
  }

  void _navigateToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MatchSetupScreen(mode: MatchSetupMode.solo)),
    );
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    await ref.read(playtestServiceProvider.notifier).setPlayerName(name);
    
    // Also update career profile for local use
    await ref.read(careerProvider.notifier).updateProfile(playerName: name);

    if (mounted) {
      _navigateToSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: VectorBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KALKRA PLAYTEST',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'ENTER YOUR NAME TO START',
                    style: TextStyle(
                      color: colorScheme.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'YOUR NAME',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('BEGIN SESSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
