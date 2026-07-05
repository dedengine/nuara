import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _urlDariBuild = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlDariBuild.isNotEmpty) return _urlDariBuild;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  static String mediaUrl(String path) {
    final dasar = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/');
    return dasar.resolve(path.replaceFirst(RegExp(r'^/+'), '')).toString();
  }
}
