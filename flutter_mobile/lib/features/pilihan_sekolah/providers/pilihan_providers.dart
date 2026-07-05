import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../data/pilihan_repository.dart';
import '../models/pilihan_tersimpan.dart';
import '../models/sekolah.dart';
import '../models/unit_sppg.dart';
import '../models/wilayah.dart';

final pilihanRepositoryProvider = Provider<PilihanRepository>((ref) {
  return PilihanRepository(ref.watch(dioProvider));
});

final daftarProvinsiProvider = FutureProvider.autoDispose<List<Wilayah>>(
  (ref) => ref.watch(pilihanRepositoryProvider).daftarProvinsi(),
);

final daftarKabupatenKotaProvider = FutureProvider.autoDispose
    .family<List<Wilayah>, String>(
      (ref, kode) =>
          ref.watch(pilihanRepositoryProvider).daftarKabupatenKota(kode),
    );

final daftarKecamatanProvider = FutureProvider.autoDispose
    .family<List<Wilayah>, String>(
      (ref, kode) => ref.watch(pilihanRepositoryProvider).daftarKecamatan(kode),
    );

final daftarKelurahanDesaProvider = FutureProvider.autoDispose
    .family<List<Wilayah>, String>(
      (ref, kode) =>
          ref.watch(pilihanRepositoryProvider).daftarKelurahanDesa(kode),
    );

final daftarKodePosProvider = FutureProvider.autoDispose
    .family<List<String>, String>(
      (ref, kode) => ref.watch(pilihanRepositoryProvider).daftarKodePos(kode),
    );

final daftarUnitProvider = FutureProvider.autoDispose
    .family<HasilDaftarUnit, FilterUnitWilayah>(
      (ref, filter) => ref.watch(pilihanRepositoryProvider).daftarUnit(filter),
    );

final daftarSekolahProvider = FutureProvider.autoDispose
    .family<List<Sekolah>, int>((ref, idUnit) {
      return ref.watch(pilihanRepositoryProvider).daftarSekolah(idUnit);
    });

final pilihanTersimpanProvider =
    AsyncNotifierProvider<PilihanTersimpanNotifier, PilihanTersimpan?>(
      PilihanTersimpanNotifier.new,
    );

final riwayatPilihanProvider = FutureProvider<List<PilihanTersimpan>>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final mentah = prefs.getString(PilihanTersimpanNotifier.kunciRiwayat);
  if (mentah == null) return const [];
  try {
    final data = jsonDecode(mentah) as List<dynamic>;
    return data
        .map(
          (item) =>
              PilihanTersimpan.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  } catch (_) {
    await prefs.remove(PilihanTersimpanNotifier.kunciRiwayat);
    return const [];
  }
});

class PilihanTidakTersediaException implements Exception {
  const PilihanTidakTersediaException();
}

class PilihanTersimpanNotifier extends AsyncNotifier<PilihanTersimpan?> {
  static const kunciRiwayat = 'riwayat_pilihan_sekolah';
  static const _batasRiwayat = 5;
  static const _idUnit = 'pilihan_id_unit_sppg';
  static const _namaUnit = 'pilihan_nama_unit_sppg';
  static const _idSekolah = 'pilihan_id_sekolah';
  static const _namaSekolah = 'pilihan_nama_sekolah';
  static const _jenjang = 'pilihan_jenjang';
  static const _wilayah = 'pilihan_wilayah';

  @override
  Future<PilihanTersimpan?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final idUnit = prefs.getInt(_idUnit);
    final idSekolah = prefs.getInt(_idSekolah);
    if (idUnit == null || idSekolah == null) return null;

    return PilihanTersimpan(
      idUnitSppg: idUnit,
      namaUnitSppg: prefs.getString(_namaUnit) ?? '',
      idSekolah: idSekolah,
      namaSekolah: prefs.getString(_namaSekolah) ?? '',
      jenjang: prefs.getString(_jenjang) ?? '',
      wilayah: prefs.getString(_wilayah) ?? '',
    );
  }

  Future<void> simpan(UnitSppg unit, Sekolah sekolah) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final wilayah = '${sekolah.kecamatan}, ${sekolah.kabupatenKota}';
      final pilihan = PilihanTersimpan(
        idUnitSppg: unit.id,
        namaUnitSppg: unit.nama,
        idSekolah: sekolah.id,
        namaSekolah: sekolah.nama,
        jenjang: sekolah.jenjang,
        wilayah: wilayah,
      );
      await _simpanPilihan(pilihan);
      return pilihan;
    });
  }

  Future<void> gunakanRiwayat(PilihanTersimpan pilihan) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final aktif = await ref
          .read(pilihanRepositoryProvider)
          .pilihanMasihAktif(
            idUnitSppg: pilihan.idUnitSppg,
            idSekolah: pilihan.idSekolah,
          );
      if (!aktif) {
        await _hapusDariRiwayat(pilihan);
        throw const PilihanTidakTersediaException();
      }
      await _simpanPilihan(pilihan);
      return pilihan;
    });
  }

  Future<void> hapusRiwayat(PilihanTersimpan pilihan) async {
    await _hapusDariRiwayat(pilihan);
  }

  Future<void> _simpanPilihan(PilihanTersimpan pilihan) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_idUnit, pilihan.idUnitSppg),
      prefs.setString(_namaUnit, pilihan.namaUnitSppg),
      prefs.setInt(_idSekolah, pilihan.idSekolah),
      prefs.setString(_namaSekolah, pilihan.namaSekolah),
      prefs.setString(_jenjang, pilihan.jenjang),
      prefs.setString(_wilayah, pilihan.wilayah),
    ]);
    final riwayat = await _bacaRiwayat(prefs)
      ..removeWhere(
        (item) =>
            item.idUnitSppg == pilihan.idUnitSppg &&
            item.idSekolah == pilihan.idSekolah,
      )
      ..insert(0, pilihan);
    if (riwayat.length > _batasRiwayat) {
      riwayat.removeRange(_batasRiwayat, riwayat.length);
    }
    await prefs.setString(
      kunciRiwayat,
      jsonEncode(riwayat.map((item) => item.toJson()).toList()),
    );
    ref.invalidate(riwayatPilihanProvider);
  }

  Future<List<PilihanTersimpan>> _bacaRiwayat(SharedPreferences prefs) async {
    final mentah = prefs.getString(kunciRiwayat);
    if (mentah == null) return [];
    try {
      return (jsonDecode(mentah) as List<dynamic>)
          .map(
            (item) => PilihanTersimpan.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      await prefs.remove(kunciRiwayat);
      return [];
    }
  }

  Future<void> _hapusDariRiwayat(PilihanTersimpan pilihan) async {
    final prefs = await SharedPreferences.getInstance();
    final riwayat = await _bacaRiwayat(prefs)
      ..removeWhere(
        (item) =>
            item.idUnitSppg == pilihan.idUnitSppg &&
            item.idSekolah == pilihan.idSekolah,
      );
    await prefs.setString(
      kunciRiwayat,
      jsonEncode(riwayat.map((item) => item.toJson()).toList()),
    );
    ref.invalidate(riwayatPilihanProvider);
  }

  Future<void> hapus() async {
    await _hapusPenyimpanan();
    state = const AsyncData(null);
  }

  Future<void> _hapusPenyimpanan() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_idUnit),
      prefs.remove(_namaUnit),
      prefs.remove(_idSekolah),
      prefs.remove(_namaSekolah),
      prefs.remove(_jenjang),
      prefs.remove(_wilayah),
    ]);
  }

  Future<void> _tandaiTidakTersedia() async {
    final pilihanSaatIni = state.value;
    if (pilihanSaatIni != null) await _hapusDariRiwayat(pilihanSaatIni);
    await _hapusPenyimpanan();
    state = AsyncError(
      const PilihanTidakTersediaException(),
      StackTrace.current,
    );
  }

  Future<bool> validasi(PilihanTersimpan pilihan) async {
    try {
      final masihTersedia = await ref
          .read(pilihanRepositoryProvider)
          .pilihanMasihAktif(
            idUnitSppg: pilihan.idUnitSppg,
            idSekolah: pilihan.idSekolah,
          );
      if (!masihTersedia) await _tandaiTidakTersedia();
      return masihTersedia;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        await _tandaiTidakTersedia();
        return false;
      }
      return true;
    }
  }
}
