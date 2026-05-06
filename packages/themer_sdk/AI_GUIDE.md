# AI Agent Guide: Automated Theming with Themer SDK

This guide provides instructions for AI agents to automatically apply design systems to Flutter applications using the `themer_flutter` SDK and `.themer` files.

## 1. Environment Setup
Agents must ensure the SDK is linked in the project's `pubspec.yaml`:

```yaml
dependencies:
  themer_flutter:
    path: path/to/themer_flutter  # Replace with actual absolute or relative path
```

## 2. Universal Theming Routine
When asked to build or update a Flutter app, the agent should:
1. **Load:** Read the content of a `.themer` file (JSON format).
2. **Parse:** Use `ThemerParser.parse(jsonString)` to create a `ThemerModel`.
3. **Provide:** Wrap the `MaterialApp` with `ThemerProvider(theme: model, child: ...)`.
4. **Standardize:** Use standard Material 3 widgets (`ElevatedButton`, `Card`, `TextField`). The SDK will style them automatically using the tokens.

## 3. High-Fidelity Token Mapping
The following mappings are enforced by the SDK:
- **primary**: Background for main buttons and primary containers.
- **onPrimary**: Text/Icon color inside primary buttons.
- **secondary**: Background for Chips, Toggles, and secondary actions.
- **surface**: Background for Cards and Input Fields.
- **onSurface**: Main body text and headline colors.
- **error**: Validation error text and destructive button backgrounds.

## 4. Automation Example (Entry Point)
```dart
import 'package:themer_flutter/themer_flutter.dart';

void applyTheme(String themerJson) {
  final themeModel = ThemerParser.parse(themerJson);
  runApp(
    ThemerProvider(
      theme: themeModel,
      child: MaterialApp(...)
    )
  );
}
```
