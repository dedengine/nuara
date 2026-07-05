import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import '../models/auth_session.dart';
import '../network/api_client.dart';

class AuthRepository {
  AuthRepository(this.api, this.preferences, this.sessionToken);

  static const _sessionKey = 'nuara_admin_session';
  static const _selectedUnitKey = 'nuara_super_admin_selected_unit';

  final ApiClient api;
  final SharedPreferences preferences;
  final SessionToken sessionToken;

  AuthSession? restore() {
    // Hapus sesi versi lama yang pernah disimpan permanen di localStorage.
    preferences.remove(_sessionKey);
    final session = AuthSession.decode(
      web.window.sessionStorage.getItem(_sessionKey),
    );
    if (session == null) {
      web.window.sessionStorage.removeItem(_selectedUnitKey);
      preferences.remove(_selectedUnitKey);
    }
    sessionToken.value = session?.token;
    return session;
  }

  Future<AuthSession> login(String email, String password) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/api/admin/masuk',
      data: {'email': email.trim(), 'password': password},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final session = AuthSession(
      token: data['token_akses'] as String,
      admin: AdminProfile.fromJson(data['admin'] as Map<String, dynamic>),
    );
    sessionToken.value = session.token;
    web.window.sessionStorage.setItem(_sessionKey, session.encode());
    return session;
  }

  Future<void> logout() async {
    try {
      await api.dio.post<void>('/api/admin/keluar');
    } finally {
      sessionToken.value = null;
      web.window.sessionStorage.removeItem(_sessionKey);
      web.window.sessionStorage.removeItem(_selectedUnitKey);
      await preferences.remove(_sessionKey);
      await preferences.remove(_selectedUnitKey);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => api.dio.put<void>(
    '/api/admin/password',
    data: {'password_lama': currentPassword, 'password_baru': newPassword},
  );

  Future<AdminProfile> updateSuperAdminProfile({
    required String name,
    required String email,
  }) async {
    final response = await api.dio.put<Map<String, dynamic>>(
      '/api/admin/profil',
      data: {'nama': name.trim(), 'email': email.trim()},
    );
    return AdminProfile.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> storeSession(AuthSession session) async {
    sessionToken.value = session.token;
    web.window.sessionStorage.setItem(_sessionKey, session.encode());
    await preferences.remove(_sessionKey);
  }
}
