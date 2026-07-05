import 'package:dio/dio.dart';

import '../models/auth_session.dart';
import '../models/dashboard_data.dart';
import '../network/api_client.dart';

class DashboardRepository {
  DashboardRepository(this.api);

  final ApiClient api;

  Future<DashboardData> load(AuthSession session, {int? selectedUnitId}) async {
    if (session.admin.isSuperAdmin) {
      final unitsResponse = await api.dio.get<Map<String, dynamic>>(
        '/api/super-admin/unit-sppg',
      );
      final units = _list(unitsResponse.data?['data']);
      if (selectedUnitId == null) return DashboardData(units: units);

      final responses = await _loadUnitData();
      return DashboardData(
        units: units,
        schools: _list(responses[0].data?['data']),
        menus: _list(responses[1].data?['data']),
        complaints: _list(responses[2].data?['data']),
        stats: _map(responses[3].data?['data']),
      );
    }

    final responses = await _loadUnitData();
    return DashboardData(
      schools: _list(responses[0].data?['data']),
      menus: _list(responses[1].data?['data']),
      complaints: _list(responses[2].data?['data']),
      stats: _map(responses[3].data?['data']),
    );
  }

  Future<List<Response<Map<String, dynamic>>>> _loadUnitData() => Future.wait([
    api.dio.get<Map<String, dynamic>>('/api/admin/sekolah'),
    api.dio.get<Map<String, dynamic>>('/api/admin/menu-harian'),
    api.dio.get<Map<String, dynamic>>('/api/admin/aduan'),
    api.dio.get<Map<String, dynamic>>('/api/admin/aduan/statistik'),
  ]);

  List<Map<String, dynamic>> _list(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
}
