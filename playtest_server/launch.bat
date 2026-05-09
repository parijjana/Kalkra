@echo off
title KALKRA PLAYTEST SERVER
echo === KALKRA PLAYTEST SERVER ===
if exist "build\kalkra_server.exe" (
    echo Starting compiled server...
    "build\kalkra_server.exe"
) else (
    echo Binary not found. Running with JIT...
    dart run bin/server.dart
)
pause
