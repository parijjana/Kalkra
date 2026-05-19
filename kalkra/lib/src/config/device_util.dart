import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdUtil {
  static const String _storageKey = 'kalkra_device_id';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString(_storageKey);

    if (storedId != null) {
      return storedId;
    }

    String deviceId = const Uuid().v4();

    if (kIsWeb) {
      await prefs.setString(_storageKey, deviceId);
      return deviceId;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? deviceId;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        final macosInfo = await deviceInfo.macOsInfo;
        deviceId = macosInfo.systemGUID ?? deviceId;
      }
    } catch (e) {
      // Fallback to UUID
    }

    await prefs.setString(_storageKey, deviceId);
    return deviceId;
  }
}
