import 'package:dio/dio.dart';

class SessionToken {
  String? value;
}

class UnitScope {
  int? value;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.token, this.unitScope)
    : dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_URL',
            defaultValue: 'http://127.0.0.1:8080',
          ),
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token.value != null) {
            options.headers['Authorization'] = 'Bearer ${token.value}';
          }
          if (unitScope.value != null) {
            options.headers['X-Unit-SPPG-ID'] = unitScope.value;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final data = error.response?.data;
          if (data is Map<String, dynamic>) {
            final detail = data['error'];
            if (detail is Map<String, dynamic>) {
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: error.type,
                  error: ApiException(
                    detail['pesan']?.toString() ?? 'Permintaan gagal diproses',
                    code: detail['kode']?.toString(),
                  ),
                ),
              );
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final SessionToken token;
  final UnitScope unitScope;
  final Dio dio;

  static String errorMessage(Object error) {
    if (error is DioException && error.error is ApiException) {
      return (error.error! as ApiException).message;
    }
    if (error is DioException &&
        error.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke Nuara API. Pastikan backend sedang aktif.';
    }
    return 'Terjadi kendala. Silakan coba kembali.';
  }
}
