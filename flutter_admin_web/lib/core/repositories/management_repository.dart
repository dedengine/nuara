import 'package:dio/dio.dart';

import '../network/api_client.dart';

class ManagementRepository {
  ManagementRepository(this.api);

  final ApiClient api;

  Future<List<Map<String, dynamic>>> getProvinces() =>
      _getRegions('/api/wilayah/provinsi');

  Future<List<Map<String, dynamic>>> getRegencies(String provinceCode) =>
      _getRegions('/api/wilayah/kabupaten-kota/$provinceCode');

  Future<List<Map<String, dynamic>>> getDistricts(String regencyCode) =>
      _getRegions('/api/wilayah/kecamatan/$regencyCode');

  Future<List<Map<String, dynamic>>> getVillages(String districtCode) =>
      _getRegions('/api/wilayah/kelurahan-desa/$districtCode');

  Future<List<String>> getPostalCodes(String villageCode) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/api/wilayah/kode-pos/$villageCode',
    );
    return (response.data?['data'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);
  }

  Future<void> saveUnit(Map<String, dynamic> data, {int? id}) async {
    if (id == null) {
      await api.dio.post<void>('/api/super-admin/unit-sppg', data: data);
      return;
    }
    await api.dio.put<void>('/api/super-admin/unit-sppg/$id', data: data);
  }

  Future<void> deactivateUnit(int id) =>
      api.dio.delete<void>('/api/super-admin/unit-sppg/$id');

  Future<void> deleteUnitPermanently(int id) =>
      api.dio.delete<void>('/api/super-admin/unit-sppg/$id/permanen');

  Future<void> createUnitAdmin(int id, Map<String, dynamic> data) =>
      api.dio.post<void>('/api/super-admin/unit-sppg/$id/admin', data: data);

  Future<void> updateUnitAdmin(int id, Map<String, dynamic> data) =>
      api.dio.put<void>('/api/super-admin/unit-sppg/$id/admin', data: data);

  Future<void> resetUnitAdminPassword(int id) =>
      api.dio.post<void>('/api/super-admin/unit-sppg/$id/admin/reset-password');

  Future<void> saveSchool(Map<String, dynamic> data, {int? id}) async {
    if (id == null) {
      await api.dio.post<void>('/api/admin/sekolah', data: data);
      return;
    }
    await api.dio.put<void>('/api/admin/sekolah/$id', data: data);
  }

  Future<void> deactivateSchool(int id) =>
      api.dio.delete<void>('/api/admin/sekolah/$id');

  Future<void> saveMenu(Map<String, dynamic> data, {int? id}) async {
    if (id == null) {
      await api.dio.post<void>('/api/admin/menu-harian', data: data);
      return;
    }
    await api.dio.put<void>('/api/admin/menu-harian/$id', data: data);
  }

  Future<Map<String, dynamic>> getMenuCatalog() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/api/admin/katalog-menu',
    );
    return Map<String, dynamic>.from(response.data?['data'] as Map);
  }

  Future<void> createMenuTemplate(Map<String, dynamic> data) =>
      api.dio.post<void>('/api/admin/katalog-menu', data: data);

  Future<void> deactivateMenu(int id) =>
      api.dio.delete<void>('/api/admin/menu-harian/$id');

  Future<void> deleteMenuPermanently(int id) =>
      api.dio.delete<void>('/api/admin/menu-harian/$id/permanen');

  Future<Map<String, dynamic>> uploadMenuMedia(
    int menuId, {
    required List<int> bytes,
    required String fileName,
    ProgressCallback? onSendProgress,
  }) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/admin/menu-harian/$menuId/media',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
      onSendProgress: onSendProgress,
    );
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<void> deleteMenuMedia(int mediaId) =>
      api.dio.delete<void>('/api/admin/media-menu/$mediaId');

  Future<void> updateComplaintStatus(int id, String status) => api.dio
      .put<void>('/api/admin/aduan/$id/status', data: {'status': status});

  Future<List<Map<String, dynamic>>> _getRegions(String path) async {
    final response = await api.dio.get<Map<String, dynamic>>(path);
    return (response.data?['data'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }
}
