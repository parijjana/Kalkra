# themer_flutter

`themer_flutter` is a small Flutter theming SDK for turning `.themer` JSON design tokens into Material 3 `ThemeData`.

## What It Provides

The public export `themer_flutter.dart` includes:

- `ThemerModel`, `ThemerColors`, `ThemerTypography`, and `ThemerEffects`.
- `ThemerParser` for parsing JSON strings into a model.
- `ThemerCompiler` for compiling the model into Flutter `ThemeData`.
- `ThemerProvider` for applying the compiled theme to a Flutter subtree.

## Token Shape

A `.themer` JSON payload is expected to include:

```json
{
  "version": "1",
  "name": "Example",
  "colors": {
    "primary": "#6750A4",
    "onPrimary": "#FFFFFF",
    "surface": "#FFFBFE",
    "onSurface": "#1C1B1F",
    "background": "#FFFFFF"
  },
  "typography": {
    "fontFamily": "Inter"
  },
  "effects": {
    "roundness": 8,
    "elevation": 1
  }
}
```

Optional color tokens include `secondary`, `onSecondary`, `onBackground`, `error`, `onError`, and `shadow`.

## Usage

```dart
import 'package:themer_flutter/themer_flutter.dart';

final model = ThemerParser.parse(themerJson);
final theme = ThemerCompiler.compile(model);
```

Use `ThemerProvider` when an app wants a provider-style wrapper around the compiled theme.

## Verification

```powershell
flutter pub get
flutter analyze
flutter test
```

## Caveats

- The parser expects valid JSON and required color fields; missing required fields throw at parse time.
- Typography size tokens exist in the model, but the current compiler uses fixed Material text sizes and the optional font family.
- This package is not currently wired into the main Kalkra app by default.
