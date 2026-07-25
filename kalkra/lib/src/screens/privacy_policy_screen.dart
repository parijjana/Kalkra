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
                'Kalkra is a fully offline, single-player game. It makes no network connections, collects no data, and contains no accounts, advertisements, or tracking of any kind.',
              ),
              const SizedBox(height: 24),
              _buildHeader('1. DATA COLLECTION'),
              _buildBody(
                'Kalkra does NOT collect, transmit, or sell any personal information. All game progress — including your "Callsign", statistics, achievements, and match history — is stored exclusively on your device and never leaves it.',
              ),
              const SizedBox(height: 24),
              _buildHeader('2. LOCAL DATA'),
              _buildBody(
                'Your game progress is stored locally on your device and never leaves it. Kalkra has no servers and transmits nothing.',
              ),
              const SizedBox(height: 24),
              _buildHeader('3. NETWORK ACCESS'),
              _buildBody(
                'Kalkra requires no network access to play. The only network activity the app can initiate is opening a link in your web browser (for example, a credits or license link) when you explicitly tap it.',
              ),
              const SizedBox(height: 24),
              _buildHeader('4. MULTIPLAYER (COMING SOON)'),
              _buildBody(
                'Kalkra is currently single-player only. If local multiplayer is introduced in a future update, this policy will be updated first to describe exactly what is shared with other players (such as your Callsign on your local network) before any such feature is enabled.',
              ),
              const SizedBox(height: 24),
              _buildHeader('5. ANALYTICS & TRACKING'),
              _buildBody(
                'Kalkra contains no third-party trackers, advertisements, or analytics SDKs. We do not track your location, contacts, identity, or app usage. Fonts and all other assets are bundled with the app — nothing is fetched from external servers at runtime.',
              ),
              const SizedBox(height: 24),
              _buildHeader('6. CHILDREN\'S PRIVACY'),
              _buildBody(
                'Because Kalkra collects no data from anyone, it collects no data from children. There are no chat features, no user-generated content shared with others, and no external links a child can be directed to during gameplay.',
              ),
              const SizedBox(height: 24),
              _buildHeader('7. THIRD-PARTY SOFTWARE'),
              _buildBody(
                'Kalkra is built with the Flutter SDK and open-source libraries. These run entirely on your device. Attributions and licenses are listed on the Credits screen in the app.',
              ),
              const SizedBox(height: 24),
              _buildHeader('8. CONTACT'),
              _buildBody(
                'Questions about this policy: overengineeredhobbies@gmail.com',
              ),
              const SizedBox(height: 40),
              Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Column(
                    children: [
                      Text(
                        'LAST UPDATED: JULY 25, 2026',
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
