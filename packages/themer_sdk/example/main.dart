import 'package:flutter/material.dart';
import 'package:themer_flutter/themer_flutter.dart';

/// SAMPLE CODE: How to initialize an app with a .themer file.
void main() {
  // 1. A sample JSON string representing a .themer file content.
  // In a real app, this would be loaded via rootBundle.loadString() or an API call.
  const String sampleThemerJson = '''
  {
    "version": "1.0.0",
    "name": "Midnight Tech",
    "colors": {
      "primary": "#6366F1",
      "onPrimary": "#FFFFFF",
      "secondary": "#10B981",
      "surface": "#18181B",
      "onSurface": "#FFFFFF",
      "background": "#09090B",
      "error": "#EF4444",
      "onError": "#FFFFFF"
    },
    "typography": {
      "fontFamily": "Inter"
    },
    "effects": {
      "roundness": 8.0,
      "elevation": 2.0
    }
  }
  ''';

  // 2. Parse the JSON into a model
  final themeModel = ThemerParser.parse(sampleThemerJson);

  // 3. Run the app wrapped in ThemerProvider
  runApp(
    ThemerProvider(
      theme: themeModel,
      child: const ThemedApp(),
    ),
  );
}

class ThemedApp extends StatelessWidget {
  const ThemedApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemerProvider internally compiles tokens into native ThemeData
    // and provides it to the Flutter engine. Standard widgets below
    // will now automatically use the theme colors and shapes.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Themed Application',
      home: Scaffold(
        appBar: AppBar(title: const Text('Theme Applied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('This card uses the Surface token.'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Primary Action'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
