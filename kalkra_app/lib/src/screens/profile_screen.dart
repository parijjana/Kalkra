import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final career = ref.read(careerProvider);
    _nameController = TextEditingController(text: career.playerName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      ref.read(careerProvider.notifier).setPlayerName(newName);
      
      // Also update settings for the current session
      final settingsNotifier = ref.read(settingsProvider);
      settingsNotifier.value = settingsNotifier.value.copyWith(playerName: newName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity Saved!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('PLAYER PROFILE'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Geometric Avatar Placeholder
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.face_retouching_natural_rounded, size: 80, color: colorScheme.onSecondaryContainer),
            ),

            const SizedBox(height: 48),

            // Name Entry Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENTER YOUR NAME',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g. MathWizard',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Collision Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARENA IDENTITY',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _nameController,
                          builder: (context, value, child) {
                            final name = value.text.isEmpty ? 'Player' : value.text;
                            return Text(
                              '$name #2', // Example of collision
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            );
                          },
                        ),
                        const Text(
                          'This is how you appear if your name is taken.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'SAVE IDENTITY',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
