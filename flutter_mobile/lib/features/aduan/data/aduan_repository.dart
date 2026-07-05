import 'package:dio/dio.dart';

import '../models/hasil_aduan.dart';

class AduanRepository {
  const AduanRepository(this._dio);

  final Dio _dio;

  Future<HasilAduan> kirim({
    required int idUnitSppg,
    required int idSekolah,
    required int? idMenuHarian,
    required String kategori,
    required String isiAduan,
    required int nilaiKepuasan,
    required String pathBerkas,
    required String namaBerkas,
    ProgressCallback? onSendProgress,
  }) async {
    final data = <String, dynamic>{
      'id_unit_sppg': idUnitSppg.toString(),
      'id_sekolah': idSekolah.toString(),
      'kategori': kategori,
      'isi_aduan': isiAduan,
      'nilai_kepuasan': nilaiKepuasan.toString(),
      'file': await MultipartFile.fromFile(pathBerkas, filename: namaBerkas),
    };
    if (idMenuHarian != null) {
      data['id_menu_harian'] = idMenuHarian.toString();
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/aduan',
      data: FormData.fromMap(data),
      onSendProgress: onSendProgress,
    );
    return HasilAduan.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
