import 'package:dio/dio.dart';

import '../models/menu_harian.dart';
import '../models/smart_dinner.dart';

class BerandaRepository {
  const BerandaRepository(this._dio);

  final Dio _dio;

  Future<MenuHarian> menuHariIni(int idSekolah) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/menu-harian',
      queryParameters: {'id_sekolah': idSekolah},
    );
    return MenuHarian.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<SmartDinner> smartDinner(int idSekolah) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/rekomendasi-makan-malam',
      queryParameters: {'id_sekolah': idSekolah},
    );
    return SmartDinner.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<List<MenuHarian>> riwayatMenu(
    int idSekolah, {
    required int jumlahHari,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/menu-harian/riwayat',
      queryParameters: {'id_sekolah': idSekolah, 'jumlah_hari': jumlahHari},
    );
    final data = response.data!['data'] as List<dynamic>;
    return data
        .map((item) => MenuHarian.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
