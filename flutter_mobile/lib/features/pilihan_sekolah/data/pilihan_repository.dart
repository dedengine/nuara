import 'package:dio/dio.dart';

import '../models/sekolah.dart';
import '../models/unit_sppg.dart';
import '../models/wilayah.dart';

class PilihanRepository {
  const PilihanRepository(this._dio);

  final Dio _dio;

  Future<List<Wilayah>> daftarProvinsi() =>
      _daftarWilayah('/api/wilayah/provinsi');

  Future<List<Wilayah>> daftarKabupatenKota(String kodeProvinsi) =>
      _daftarWilayah('/api/wilayah/kabupaten-kota/$kodeProvinsi');

  Future<List<Wilayah>> daftarKecamatan(String kodeKabupatenKota) =>
      _daftarWilayah('/api/wilayah/kecamatan/$kodeKabupatenKota');

  Future<List<Wilayah>> daftarKelurahanDesa(String kodeKecamatan) =>
      _daftarWilayah('/api/wilayah/kelurahan-desa/$kodeKecamatan');

  Future<List<String>> daftarKodePos(String kodeKelurahanDesa) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/wilayah/kode-pos/$kodeKelurahanDesa',
    );
    return (response.data?['data'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);
  }

  Future<HasilDaftarUnit> daftarUnit(FilterUnitWilayah filter) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/unit-sppg',
      queryParameters: {
        'kode_provinsi': filter.kodeProvinsi,
        'kode_kabupaten_kota': filter.kodeKabupatenKota,
        'kode_kecamatan': filter.kodeKecamatan,
        'kode_kelurahan_desa': filter.kodeKelurahanDesa,
        'kode_pos': filter.kodePos,
      },
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    final unit = data
        .map((item) => UnitSppg.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final meta = response.data?['meta'];
    return HasilDaftarUnit(
      unit: unit,
      adaUnitNonaktif:
          meta is Map<String, dynamic> && meta['ada_unit_nonaktif'] == true,
    );
  }

  Future<List<Sekolah>> daftarSekolah(int idUnitSppg) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/unit-sppg/$idUnitSppg/sekolah',
    );
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => Sekolah.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<bool> pilihanMasihAktif({
    required int idUnitSppg,
    required int idSekolah,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/status-pilihan',
      queryParameters: {'id_unit_sppg': idUnitSppg, 'id_sekolah': idSekolah},
    );
    return response.data?['data'] == true;
  }

  Future<List<Wilayah>> _daftarWilayah(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    final data = response.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => Wilayah.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class HasilDaftarUnit {
  const HasilDaftarUnit({required this.unit, required this.adaUnitNonaktif});

  final List<UnitSppg> unit;
  final bool adaUnitNonaktif;
}

typedef FilterUnitWilayah = ({
  String kodeProvinsi,
  String kodeKabupatenKota,
  String kodeKecamatan,
  String kodeKelurahanDesa,
  String kodePos,
});
