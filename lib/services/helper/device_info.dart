import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final Map<String, String> deviceData = {};

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        deviceData['device_name'] =
            '${webInfo.browserName} on ${webInfo.platform}';
        deviceData['platform'] = 'web';
        deviceData['browser'] = webInfo.browserName.toString();
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData['device_name'] = '${androidInfo.brand} ${androidInfo.model}';
        deviceData['platform'] = 'android';
        deviceData['model'] = androidInfo.model;
        deviceData['manufacturer'] = androidInfo.manufacturer;
        deviceData['android_version'] = androidInfo.version.release;
        deviceData['sdk_int'] = androidInfo.version.sdkInt.toString();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData['device_name'] = '${iosInfo.name} (${iosInfo.model})';
        deviceData['platform'] = 'ios';
        deviceData['model'] = iosInfo.model;
        deviceData['system_version'] = iosInfo.systemVersion;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        deviceData['device_name'] = windowsInfo.computerName;
        deviceData['platform'] = 'windows';
        deviceData['product_name'] = windowsInfo.productName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceData['device_name'] = linuxInfo.name;
        deviceData['platform'] = 'linux';
        deviceData['version'] = linuxInfo.version ?? 'Unknown';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        deviceData['device_name'] = macInfo.computerName;
        deviceData['platform'] = 'macos';
        deviceData['model'] = macInfo.model;
      }
    } catch (e) {
       debugPrint('Error getting device info: $e');
       deviceData['device_name'] = 'Unknown Device';
       deviceData['platform'] = 'unknown';
    }

    return deviceData;
  }

}