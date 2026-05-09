#!/bin/bash

# KALKRA Playtest Server - macOS/Linux Launcher
echo "======================================"
echo "   KALKRA PLAYTEST SERVER (macOS)     "
echo "======================================"

# 1. Check for Dart SDK
if ! command -v dart &> /dev/null
then
    echo "ERROR: Dart SDK not found."
    echo "Please install it via Homebrew: brew install dart-sdk"
    echo "Or visit: https://dart.dev/get-dart"
    exit 1
fi

# 2. Sync dependencies
echo "Checking dependencies..."
dart pub get --quiet

# 3. Handle Binary vs JIT
if [ -f "build/kalkra_server_macos" ]; then
    echo "Starting compiled server..."
    ./build/kalkra_server_macos
else
    echo "Running with Dart VM (JIT)..."
    echo "Tip: For maximum performance, run 'dart compile exe bin/server.dart -o build/kalkra_server_macos'"
    dart run bin/server.dart
fi
