# Kalkra Playtest Server - macOS Instructions

## 📋 1. Prerequisites
You need the **Dart SDK** installed on your Mac.
- **Recommended**: Use Homebrew: `brew install dart-sdk`
- **Manual**: Download from [dart.dev/get-dart](https://dart.dev/get-dart)

## 🚀 2. How to Start
1. Open **Terminal**.
2. Navigate to this folder (`cd path/to/playtest_server`).
3. Make the launcher executable:
   ```bash
   chmod +x launch_macos.sh
   ```
4. Run the server:
   ```bash
   ./launch_macos.sh
   ```

## 🛠️ 3. Optional: Compile to Native (AOT)
For maximum efficiency (fastest startup and lowest RAM), compile the server to a native Mac binary:
```bash
dart compile exe bin/server.dart -o build/kalkra_server_macos
```
The `launch_macos.sh` script will automatically use this binary if it exists.

## 🌐 4. Accessing the Game
- **Local**: `http://localhost:8000`
- **Network**: Find your Mac's IP in System Settings > Network, then share `http://YOUR_IP:8000` with your playtesters.

---
*Note: If macOS asks to "Allow incoming network connections," click **Allow** so phones on your WiFi can reach the server.*
