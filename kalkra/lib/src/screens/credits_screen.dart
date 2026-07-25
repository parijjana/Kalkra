import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/vector_background.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'CREDITS & ATTRIBUTIONS',
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
              _buildSection(
                theme,
                'AUDIO ASSETS',
                'Sound effects and music used in Kalkra are sourced from public domain and open-licensed libraries.',
              ),
              const SizedBox(height: 24),
              _buildCreditItem(
                theme,
                'Kenney.nl',
                'Digital Audio, Impact Audio, and UI Audio packs (CC0 License).',
              ),
              _buildCreditItem(
                theme,
                'The Cynic Project',
                'Track: "003 Vaporware" (Pixelsphere.org / OpenGameArt.org).',
              ),
              _buildCreditItem(
                theme,
                'Yoiyami',
                'Track: "Starfield Romance" (OpenGameArt.org).',
              ),
              _buildCreditItem(
                theme,
                'Freesound.org',
                'Community-contributed sounds under Creative Commons 0.',
              ),
              _buildCreditItem(
                theme,
                'Pixabay',
                'Modern UI sounds and cinematic transitions (Pixabay License).',
              ),
              const Divider(height: 64),
              _buildSection(
                theme,
                'ENGINE & FRAMEWORK',
                'Kalkra is built with Flutter and powered by the Kalkra Math Engine.',
              ),
              const SizedBox(height: 24),
              _buildCreditItem(theme, 'Flutter SDK', 'Google & Contributors'),
              _buildCreditItem(theme, 'Riverpod', 'State management by Remi Rousselet'),
              _buildCreditItem(theme, 'Shelf', 'Web playtest infrastructure'),
              const Divider(height: 64),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final Uri url = Uri.parse('https://overengineeredhobbies.dev/projects/kalkra_privacy');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: const Text(
                    'VIEW PRIVACY POLICY',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'MADE WITH ❤️ BY THE KALKRA TEAM',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 4,
                    color: colorScheme.primary.withValues(alpha: 0.5),
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

  Widget _buildSection(ThemeData theme, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditItem(ThemeData theme, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
