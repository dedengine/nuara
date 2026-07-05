import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'models/auth_session.dart';
import 'models/dashboard_data.dart';
import 'network/api_client.dart';
import 'realtime/complaint_event_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/management_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences belum tersedia'),
);

final sessionTokenProvider = Provider<SessionToken>((ref) => SessionToken());
final unitScopeProvider = Provider<UnitScope>((ref) => UnitScope());

final apiClientProvider = Provider<ApiClient>(
  (ref) =>
      ApiClient(ref.watch(sessionTokenProvider), ref.watch(unitScopeProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sharedPreferencesProvider),
    ref.watch(sessionTokenProvider),
  ),
);

class AuthState {
  const AuthState({this.session, this.isLoading = false, this.errorMessage});

  final AuthSession? session;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AuthSession? session,
    bool clearSession = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => AuthState(
    session: clearSession ? null : (session ?? this.session),
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final session = ref.read(authRepositoryProvider).restore();
    return AuthState(session: session);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      state = AuthState(session: session);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.errorMessage(error),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  Future<void> updateSuperAdminProfile({
    required String name,
    required String email,
  }) async {
    final currentSession = state.session;
    if (currentSession == null || !currentSession.admin.isSuperAdmin) {
      throw StateError('Sesi Super Admin tidak tersedia');
    }
    final admin = await ref
        .read(authRepositoryProvider)
        .updateSuperAdminProfile(name: name, email: email);
    final updatedSession = AuthSession(
      token: currentSession.token,
      admin: admin,
    );
    await ref.read(authRepositoryProvider).storeSession(updatedSession);
    state = AuthState(session: updatedSession);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class SelectedUnitController extends Notifier<int?> {
  static const _sessionKey = 'nuara_super_admin_selected_unit';

  @override
  int? build() {
    final admin = ref.watch(authControllerProvider).session?.admin;
    if (admin == null) {
      ref.read(unitScopeProvider).value = null;
      return null;
    }
    if (!admin.isSuperAdmin) {
      web.window.sessionStorage.removeItem(_sessionKey);
      final unitId = admin.idUnitSppg;
      ref.read(unitScopeProvider).value = unitId;
      return unitId;
    }

    final unitId = int.tryParse(
      web.window.sessionStorage.getItem(_sessionKey) ?? '',
    );
    ref.read(unitScopeProvider).value = unitId;
    return unitId;
  }

  void select(int? unitId) {
    if (unitId == null) {
      web.window.sessionStorage.removeItem(_sessionKey);
    } else {
      web.window.sessionStorage.setItem(_sessionKey, unitId.toString());
    }
    ref.read(unitScopeProvider).value = unitId;
    state = unitId;
  }
}

final selectedUnitProvider = NotifierProvider<SelectedUnitController, int?>(
  SelectedUnitController.new,
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

final managementRepositoryProvider = Provider<ManagementRepository>(
  (ref) => ManagementRepository(ref.watch(apiClientProvider)),
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _preferenceKey = 'nuara_web_dark_mode';

  @override
  ThemeMode build() {
    final dark = ref.read(sharedPreferencesProvider).getBool(_preferenceKey);
    return dark == true ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_preferenceKey, next == ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) return const DashboardData();
  final selectedUnitId = ref.watch(selectedUnitProvider);
  ref.read(unitScopeProvider).value = session.admin.isSuperAdmin
      ? selectedUnitId
      : session.admin.idUnitSppg;
  return ref
      .watch(dashboardRepositoryProvider)
      .load(session, selectedUnitId: selectedUnitId);
});

final complaintEventsProvider = Provider.autoDispose<void>((ref) {
  final session = ref.watch(authControllerProvider).session;
  final selectedUnitId = ref.watch(selectedUnitProvider);
  final unitId = session?.admin.isSuperAdmin == true
      ? selectedUnitId
      : session?.admin.idUnitSppg;
  if (session == null || unitId == null) return;

  final service = ComplaintEventService(ref.watch(apiClientProvider));
  Timer? refreshDebounce;
  unawaited(
    service.start(
      onEvent: () {
        refreshDebounce?.cancel();
        refreshDebounce = Timer(const Duration(milliseconds: 300), () {
          ref.invalidate(dashboardProvider);
        });
      },
    ),
  );
  ref.onDispose(() {
    refreshDebounce?.cancel();
    service.close();
  });
});
