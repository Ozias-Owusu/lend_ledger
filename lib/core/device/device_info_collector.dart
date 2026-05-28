import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';

class LoginDeviceMetadata {
  const LoginDeviceMetadata({
    required this.deviceName,
    required this.deviceType,
    required this.platform,
  });

  final String deviceName;
  final String deviceType;
  final String platform;

  Map<String, String> toJson() => {
        'deviceName': deviceName,
        'deviceType': deviceType,
        'platform': platform,
      };
}

/// Collects device metadata silently for auth requests (no user input).
class DeviceInfoCollector {
  static Future<LoginDeviceMetadata> collect() async {
    final plugin = DeviceInfoPlugin();
    final platform = _platformLabel();
    final deviceType = _deviceTypeLabel();

    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final name = '${info.brand} ${info.model}'.trim();
        return LoginDeviceMetadata(
          deviceName: name.isEmpty ? 'Android Device' : name,
          deviceType: deviceType,
          platform: platform,
        );
      }

      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final name = info.name.trim().isNotEmpty
            ? info.name.trim()
            : '${info.model} ${info.utsname.machine}'.trim();
        final type = info.model.toLowerCase().contains('ipad')
            ? 'Tablet'
            : deviceType;
        return LoginDeviceMetadata(
          deviceName: name.isEmpty ? 'iOS Device' : name,
          deviceType: type,
          platform: platform,
        );
      }

      if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return LoginDeviceMetadata(
          deviceName: info.computerName.trim().isEmpty
              ? 'Windows PC'
              : info.computerName.trim(),
          deviceType: 'Desktop',
          platform: platform,
        );
      }

      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return LoginDeviceMetadata(
          deviceName: info.model.trim().isEmpty ? 'Mac' : info.model.trim(),
          deviceType: 'Desktop',
          platform: platform,
        );
      }

      if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        final name = info.prettyName.trim().isEmpty
            ? info.name.trim()
            : info.prettyName.trim();
        return LoginDeviceMetadata(
          deviceName: name.isEmpty ? 'Linux Device' : name,
          deviceType: 'Desktop',
          platform: platform,
        );
      }
    } catch (_) {
      // Fall through to generic values.
    }

    return LoginDeviceMetadata(
      deviceName: 'Unknown Device',
      deviceType: deviceType,
      platform: platform,
    );
  }

  static String _platformLabel() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }

  static String _deviceTypeLabel() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 'Phone';

    final view = views.first;
    final width = view.physicalSize.width / view.devicePixelRatio;
    final height = view.physicalSize.height / view.devicePixelRatio;
    final shortestSide = width < height ? width : height;

    if (shortestSide >= 600) return 'Tablet';
    return 'Phone';
  }
}
