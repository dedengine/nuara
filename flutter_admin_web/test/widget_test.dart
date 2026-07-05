import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuara_admin/core/theme/app_theme.dart';
import 'package:nuara_admin/core/models/auth_session.dart';
import 'package:nuara_admin/features/dashboard/management_dialogs.dart';

void main() {
  testWidgets('tema Nuara dapat dirender', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Text('NUARA')),
      ),
    );

    expect(find.text('NUARA'), findsOneWidget);
  });

  testWidgets('tema gelap Nuara dapat dirender', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: Text('NUARA GELAP')),
      ),
    );

    final context = tester.element(find.text('NUARA GELAP'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('detail aduan responsif pada viewport sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final complaint = <String, dynamic>{
      'id': 12,
      'id_sekolah': 1,
      'nama_sekolah': 'SD Nusantara Mekarjaya 01',
      'nama_menu': 'Paket Ayam Panggang',
      'kategori': 'makanan_rusak',
      'isi_aduan':
          'Makanan berbau tidak biasa dan teksturnya berubah saat diterima.',
      'nilai_kepuasan': 2,
      'status': 'baru',
      'created_at': '2026-06-28T10:30:00',
      'media': <Map<String, dynamic>>[],
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () =>
                      showComplaintDetailDialog(context, complaint: complaint),
                  child: const Text('Buka detail'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka detail'));
    await tester.pumpAndSettle();

    expect(find.text('Detail aduan #12'), findsOneWidget);
    expect(find.text('Makanan Basi'), findsOneWidget);
    expect(find.text('Bukti media tidak tersedia'), findsOneWidget);
    expect(find.text('Status tindak lanjut'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form edit sekolah tersusun rapi pada viewport sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final school = <String, dynamic>{
      'id': 1,
      'nama': 'SD Nusantara Mekarjaya 01',
      'jenjang': 'SD',
      'provinsi': 'Jawa Barat',
      'kabupaten_kota': 'Kota Bekasi',
      'kecamatan': 'Sukmajaya',
      'kelurahan_desa': 'Mekarjaya',
      'kode_pos': '16411',
      'rt': '02',
      'rw': '04',
      'alamat_detail': 'Jalan Merdeka Pendidikan No. 7',
      'aktif': true,
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () =>
                      showSchoolFormDialog(context, school: school),
                  child: const Text('Buka form sekolah'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka form sekolah'));
    await tester.pumpAndSettle();

    expect(find.text('Ubah sekolah'), findsOneWidget);
    expect(find.text('Informasi sekolah'), findsOneWidget);
    expect(find.textContaining('otomatis mengikuti unit SPPG'), findsOneWidget);
    expect(find.text('Detail alamat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profil Super Admin dapat dilihat pada viewport sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const admin = AdminProfile(
      id: 1,
      nama: 'Nuara Super Admin',
      email: 'superadmin@nuara.test',
      peran: 'super_admin',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () =>
                      showSuperAdminProfileDialog(context, admin: admin),
                  child: const Text('Buka profil'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka profil'));
    await tester.pumpAndSettle();

    expect(find.text('Profil Super Admin'), findsOneWidget);
    expect(find.text('Nuara Super Admin'), findsOneWidget);
    expect(find.text('superadmin@nuara.test'), findsOneWidget);
    expect(find.text('ID Admin'), findsOneWidget);
    expect(find.text('Hak akses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
