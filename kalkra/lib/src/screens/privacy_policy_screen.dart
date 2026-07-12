import 'package:flutter/material.dart';
import '../widgets/vector_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'PRIVACY POLICY',
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
              _buildHeader('🛡️ YOUR DATA IS YOURS'),
              _buildBody(
                'Kalkra is designed with a "Local-First" philosophy. We believe your gaming data, stats, and achievements should remain on your device.',
              ),
              const SizedBox(height: 24),
              _buildHeader('1. DATA COLLECTION'),
              _buildBody(
                'Kalkra does NOT collect, transmit, or sell any personal information. All game progress, including your "Callsign", Elo rating, and match history, is stored exclusively on your device.',
              ),
              const SizedBox(height: 24),
              _buildHeader('2. HARDWARE SECURITY'),
              _buildBody(
                'To prevent unauthorized tampering, Kalkra uses hardware-backed encryption (Android Keystore / iOS Keychain). This ensures your save data is tied to your physical device and protected by your system security.',
              ),
              const SizedBox(height: 24),
              _buildHeader('3. MULTIPLAYER (COMING SOON)'),
              _buildBody(
                'Kalkra is currently a fully offline, single-player game. When local multiplayer is introduced in a future update, this policy will be updated to describe exactly what is shared with other players before the feature is enabled.',
              ),
              const SizedBox(height: 24),
              _buildHeader('4. ANALYTICS & TRACKING'),
              _buildBody(
                'Kalkra contains no third-party trackers, advertisements, or analytics SDKs. We do not track your location, contacts, or app usage.',
              ),
              const SizedBox(height: 24),
              _buildHeader('5. THIRD-PARTY SERVICES'),
              _buildBody(
                'Kalkra uses the official Flutter SDK and various open-source libraries. For more details on these, see the Credits & Attributions screen.',
              ),
              const SizedBox(height: 40),
              Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Column(
                    children: [
                      Text(
                        'LAST UPDATED: MAY 2026',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'KALKRA PROJECT • OPEN SOURCE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
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
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBody(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
    );
  }
}
