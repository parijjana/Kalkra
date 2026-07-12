import 'package:flutter/material.dart';
import '../widgets/vector_background.dart';
import 'privacy_policy_screen.dart';

class PlayersGuideScreen extends StatelessWidget {
  const PlayersGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'PLAYER\'S GUIDE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: VectorBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('🕹️ CORE GAMEPLAY'),
              _buildBody('Use 6 token numbers and basic operators (+, -, ×, ÷) to reach the Target Number. Each token can be used only once.'),
              const SizedBox(height: 32),
              
              _buildHeader('🏆 MISSION TYPES'),
              _buildModeItem(context, 'TRIPLE THREAT', '3x3 grid with only 3 solvable targets. High points for largest target.'),
              _buildModeItem(context, 'DOUBLE DANGER', '2x2 grid with 2 solvable targets. Fast-paced elimination.'),
              _buildModeItem(context, 'TUNNEL VISION', 'The same target persists across rounds.'),
              _buildModeItem(context, 'PROGRESSIVE', 'Survive the climbing ladder of difficulty.'),
              _buildModeItem(context, 'ENDLESS', '3 lives. Survive as long as you can.'),
              const SizedBox(height: 32),

              _buildHeader('⚡ WILDCARD MODES'),
              _buildWildcardItem(context, 'SPEED DEMON', 'Timer is reduced by 50%. Focus on speed!', Icons.bolt_rounded),
              _buildWildcardItem(context, 'OPERATOR LOCKOUT', 'One random operator is BANNED.', Icons.block_rounded),
              _buildWildcardItem(context, 'DOUBLE OR NOTHING', 'Exact match = 20pts. Anything else = 0pts.', Icons.star_outline_rounded),
              const SizedBox(height: 32),

              _buildHeader('📊 SCORING'),
              _buildBody('• Exact Match: 10pts\n• Off by 1: 7pts\n• Off by 2: 5pts\n• Off by 3-5: 3pts\n• Off by 6-10: 1pt'),
              const SizedBox(height: 48),
              
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  ),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: const Text(
                    'PRIVACY POLICY',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    'VERSION 1.0.0 • PRODUCTION READY',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBody(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.5),
    );
  }

  Widget _buildModeItem(BuildContext context, String title, String desc) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWildcardItem(BuildContext context, String title, String desc, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.tertiary.withValues(alpha: 0.1),
        child: Icon(icon, color: colorScheme.tertiary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
    );
  }
}
