import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'Accept': 'application/json'},
    ),
  );
});

String pesanDio(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['error'];
      if (detail is Map<String, dynamic> && detail['pesan'] is String) {
        return detail['pesan'] as String;
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server terlalu lama. Coba lagi.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Server Nuara belum dapat dihubungi.';
    }
  }
  return 'Data belum dapat dimuat. Coba beberapa saat lagi.';
}
