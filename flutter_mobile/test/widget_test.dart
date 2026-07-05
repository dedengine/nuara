import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nuara_mobile/features/aduan/models/hasil_aduan.dart';
import 'package:nuara_mobile/features/aduan/presentation/aduan_page.dart';
import 'package:nuara_mobile/core/theme/app_theme.dart';
import 'package:nuara_mobile/features/beranda/models/menu_harian.dart';
import 'package:nuara_mobile/features/beranda/models/smart_dinner.dart';
import 'package:nuara_mobile/features/beranda/models/target_nutrisi.dart';
import 'package:nuara_mobile/features/beranda/presentation/beranda_page.dart';
import 'package:nuara_mobile/features/beranda/presentation/riwayat_page.dart';
import 'package:nuara_mobile/features/beranda/presentation/smart_dinner_page.dart';
import 'package:nuara_mobile/features/beranda/providers/beranda_providers.dart';
import 'package:nuara_mobile/features/pilihan_sekolah/data/pilihan_repository.dart';
import 'package:nuara_mobile/features/pilihan_sekolah/models/pilihan_tersimpan.dart';
import 'package:nuara_mobile/features/pilihan_sekolah/models/unit_sppg.dart';
import 'package:nuara_mobile/features/pilihan_sekolah/models/wilayah.dart';
import 'package:nuara_mobile/features/pilihan_sekolah/presentation/pilihan_sekolah_page.dart';
import 'package:nuara_mobile/features/pilihan_sekolah/providers/pilihan_providers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

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

  test('data unit SPPG dari API dapat dipetakan', () {
    final unit = UnitSppg.fromJson({
      'id': 1,
      'kode': 'SPPG-DPK-001',
      'nama': 'SPPG Mekarjaya',
      'kode_provinsi': '32',
      'provinsi': 'Jawa Barat',
      'kode_kabupaten_kota': '32.76',
      'kabupaten_kota': 'Kota Depok',
      'kode_kecamatan': '32.76.05',
      'kecamatan': 'Sukmajaya',
      'kode_kelurahan_desa': '32.76.05.1001',
      'kelurahan_desa': 'Mekar Jaya',
      'kode_pos': '16411',
      'jumlah_sekolah': 3,
    });

    expect(unit.nama, 'SPPG Mekarjaya');
    expect(unit.wilayah, 'Sukmajaya, Kota Depok');
    expect(unit.jumlahSekolah, 3);
  });

  test('respons aduan anonim dapat dipetakan', () {
    final hasil = HasilAduan.fromJson({
      'id': 12,
      'status': 'baru',
      'created_at': '2026-06-28T10:30:00',
    });

    expect(hasil.id, 12);
    expect(hasil.status, 'baru');
  });

  testWidgets('layar pemilihan tidak overflow pada viewport ponsel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const unit = UnitSppg(
      id: 1,
      kode: 'SPPG-DPK-001',
      nama: 'SPPG Mekarjaya',
      kodeProvinsi: '32',
      provinsi: 'Jawa Barat',
      kodeKabupatenKota: '32.76',
      kabupatenKota: 'Kota Depok',
      kodeKecamatan: '32.76.05',
      kecamatan: 'Sukmajaya',
      kodeKelurahanDesa: '32.76.05.1001',
      kelurahanDesa: 'Mekar Jaya',
      kodePos: '16411',
      jumlahSekolah: 3,
    );
    const province = Wilayah(kode: '32', nama: 'Jawa Barat');
    const regency = Wilayah(kode: '32.76', nama: 'Kota Depok');
    const district = Wilayah(kode: '32.76.05', nama: 'Sukmajaya');
    const village = Wilayah(
      kode: '32.76.05.1001',
      nama: 'Mekar Jaya',
      kodePos: '16411',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          daftarProvinsiProvider.overrideWith((ref) async => const [province]),
          daftarKabupatenKotaProvider.overrideWith(
            (ref, _) async => const [regency],
          ),
          daftarKecamatanProvider.overrideWith(
            (ref, _) async => const [district],
          ),
          daftarKelurahanDesaProvider.overrideWith(
            (ref, _) async => const [village],
          ),
          daftarKodePosProvider.overrideWith((ref, _) async => const ['16411']),
          daftarUnitProvider.overrideWith(
            (ref, _) async =>
                const HasilDaftarUnit(unit: [unit], adaUnitNonaktif: false),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const PilihanSekolahPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Temukan sekolah anak'), findsOneWidget);
    expect(find.text('Pilih unit SPPG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('beranda menu dan gizi tidak overflow pada viewport ponsel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final menu = MenuHarian.fromJson({
      'id': 6,
      'tanggal_menu': '2026-06-27',
      'nama_menu': 'Paket Bandeng Presto',
      'deskripsi': 'Nasi, ikan, sayur, dan buah.',
      'kalori': 670,
      'protein': 36.4,
      'lemak': 21.2,
      'karbohidrat': 83.7,
      'sumber_data_gizi': 'PanganKu/TKPI',
      'url_sumber_data_gizi': 'https://panganku.org/',
      'komponen': [
        {'nama_komponen': 'Nasi', 'keterangan_porsi': '150 gram', 'urutan': 1},
        {
          'nama_komponen': 'Ikan bandeng presto',
          'keterangan_porsi': null,
          'urutan': 2,
        },
      ],
      'alergi': [
        {'nama_alergi': 'seafood', 'keterangan': null},
      ],
      'media': [],
    });
    const target = TargetNutrisi(
      kalori: 1200,
      protein: 40,
      lemak: 40,
      karbohidrat: 180,
      sumber: 'Permenkes Nomor 28 Tahun 2019 tentang AKG',
      urlSumber: 'https://peraturan.bpk.go.id/Details/138621',
    );
    const pilihan = PilihanTersimpan(
      idUnitSppg: 1,
      namaUnitSppg: 'SPPG Mekarjaya',
      idSekolah: 1,
      namaSekolah: 'SD Nusantara Mekarjaya 01',
      jenjang: 'SD',
      wilayah: 'Sukmajaya, Kota Depok',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuHariIniProvider(1).overrideWith((ref) async => menu),
          targetNutrisiProvider(1).overrideWith((ref) async => target),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: BerandaPage(pilihan: pilihan)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Paket Bandeng Presto'), findsOneWidget);
    expect(find.text('670 kkal'), findsOneWidget);
    expect(find.text('Seafood'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('riwayat dan detail menu tidak overflow pada viewport ponsel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final menu = MenuHarian.fromJson({
      'id': 6,
      'tanggal_menu': '2026-06-27',
      'nama_menu': 'Paket Bandeng Presto',
      'deskripsi': 'Nasi, ikan, sayur, dan buah.',
      'kalori': 670,
      'protein': 36.4,
      'lemak': 21.2,
      'karbohidrat': 83.7,
      'sumber_data_gizi': 'PanganKu/TKPI',
      'url_sumber_data_gizi': 'https://panganku.org/',
      'komponen': [
        {'nama_komponen': 'Nasi', 'keterangan_porsi': '150 gram', 'urutan': 1},
        {
          'nama_komponen': 'Ikan bandeng presto',
          'keterangan_porsi': null,
          'urutan': 2,
        },
      ],
      'alergi': [
        {'nama_alergi': 'seafood', 'keterangan': null},
      ],
      'media': [],
    });
    const pilihan = PilihanTersimpan(
      idUnitSppg: 1,
      namaUnitSppg: 'SPPG Mekarjaya',
      idSekolah: 1,
      namaSekolah: 'SD Nusantara Mekarjaya 01',
      jenjang: 'SD',
      wilayah: 'Sukmajaya, Kota Depok',
    );
    const filter = (idSekolah: 1, jumlahHari: 7);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riwayatMenuProvider(filter).overrideWith((ref) async => [menu]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: RiwayatPage(pilihan: pilihan)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Riwayat menu'), findsOneWidget);
    expect(find.text('Paket Bandeng Presto'), findsOneWidget);
    await tester.tap(find.text('Paket Bandeng Presto'));
    await tester.pumpAndSettle();

    expect(find.text('Gizi'), findsOneWidget);
    expect(find.text('Sumber: PanganKu/TKPI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Smart Dinner tidak overflow pada viewport ponsel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final smartDinner = SmartDinner.fromJson({
      'makan_siang': {
        'id_menu_harian': 7,
        'nama_menu': 'Paket Ayam Panggang',
        'tanggal_menu': '2026-06-28',
        'jenjang': 'SD',
        'kalori': 640,
        'protein': 35,
        'lemak': 18,
        'karbohidrat': 85,
      },
      'target_hingga_makan_malam': {
        'kalori': 1200,
        'protein': 40,
        'lemak': 40,
        'karbohidrat': 180,
      },
      'kekurangan_setelah_makan_siang': {
        'kalori': 560,
        'protein': 5,
        'lemak': 22,
        'karbohidrat': 95,
      },
      'rekomendasi': [
        {
          'id': 1,
          'nama_menu': 'Sup Ayam Kentang dan Wortel',
          'deskripsi': 'Sup ayam dengan kentang, wortel, dan nasi secukupnya.',
          'fokus_nutrisi': 'Protein dan karbohidrat',
          'kalori': 520,
          'protein': 27,
          'lemak': 14,
          'karbohidrat': 72,
          'serat': 7,
          'sumber_data_gizi': 'PanganKu/TKPI',
          'url_sumber_data_gizi': 'https://panganku.org/',
          'skor_kecocokan': 94.2,
        },
        {
          'id': 2,
          'nama_menu': 'Pepes Tahu dan Sayur Bening',
          'deskripsi': 'Pepes tahu dengan sayur bening dan nasi.',
          'fokus_nutrisi': 'Protein nabati dan serat',
          'kalori': 480,
          'protein': 20,
          'lemak': 12,
          'karbohidrat': 75,
          'serat': 9,
          'sumber_data_gizi': 'PanganKu/TKPI',
          'url_sumber_data_gizi': 'https://panganku.org/',
          'skor_kecocokan': 91.8,
        },
      ],
      'sumber_target': 'Permenkes Nomor 28 Tahun 2019 tentang AKG',
      'url_sumber_target': 'https://peraturan.bpk.go.id/Details/138621',
      'catatan':
          'Rekomendasi bersifat umum berdasarkan jenjang sekolah dan bukan diagnosis medis.',
    });
    const pilihan = PilihanTersimpan(
      idUnitSppg: 1,
      namaUnitSppg: 'SPPG Mekarjaya',
      idSekolah: 1,
      namaSekolah: 'SD Nusantara Mekarjaya 01',
      jenjang: 'SD',
      wilayah: 'Sukmajaya, Kota Depok',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smartDinnerProvider(1).overrideWith((ref) async => smartDinner),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SmartDinnerPage(pilihan: pilihan)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Smart Dinner'), findsOneWidget);
    expect(find.text('2 rekomendasi makan malam'), findsOneWidget);
    expect(find.text('Sup Ayam Kentang dan Wortel'), findsOneWidget);
    expect(find.text('94.2%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form aduan dan validasi tidak overflow pada viewport ponsel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const pilihan = PilihanTersimpan(
      idUnitSppg: 1,
      namaUnitSppg: 'SPPG Mekarjaya',
      idSekolah: 1,
      namaSekolah: 'SD Nusantara Mekarjaya 01',
      jenjang: 'SD',
      wilayah: 'Sukmajaya, Kota Depok',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AduanPage(pilihan: pilihan)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Suara Orang Tua'), findsOneWidget);
    expect(find.text('Tambah bukti'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Kirim aduan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim aduan'));
    await tester.pump();

    expect(find.text('Pilih kategori aduan terlebih dahulu'), findsOneWidget);
    expect(find.text('Isi aduan minimal 10 karakter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
