#!/bin/bash
echo "=== KALKRA PLAYTEST SERVER ==="
if [ -f "build/kalkra_server" ]; then
    echo "Starting compiled server..."
    ./build/kalkra_server
elif command -v dart &> /dev/null; then
    echo "Binary not found. Running with JIT..."
    dart run bin/server.dart
else
    echo "Error: Dart SDK not found. Please install Dart to run or compile the server."
fi
