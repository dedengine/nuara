import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../data/pilihan_repository.dart';
import '../models/pilihan_tersimpan.dart';
import '../models/sekolah.dart';
import '../models/unit_sppg.dart';
import '../models/wilayah.dart';
import '../providers/pilihan_providers.dart';

class PilihanSekolahPage extends ConsumerStatefulWidget {
  const PilihanSekolahPage({super.key, this.kesalahanAwal});

  final Object? kesalahanAwal;

  @override
  ConsumerState<PilihanSekolahPage> createState() => _PilihanSekolahPageState();
}

class _PilihanSekolahPageState extends ConsumerState<PilihanSekolahPage> {
  Wilayah? _provinsi;
  Wilayah? _kabupatenKota;
  Wilayah? _kecamatan;
  Wilayah? _kelurahanDesa;
  String? _kodePos;
  UnitSppg? _unitTerpilih;
  Sekolah? _sekolahTerpilih;

  FilterUnitWilayah? get _filterUnit {
    if (_provinsi == null ||
        _kabupatenKota == null ||
        _kecamatan == null ||
        _kelurahanDesa == null ||
        _kodePos == null) {
      return null;
    }
    return (
      kodeProvinsi: _provinsi!.kode,
      kodeKabupatenKota: _kabupatenKota!.kode,
      kodeKecamatan: _kecamatan!.kode,
      kodeKelurahanDesa: _kelurahanDesa!.kode,
      kodePos: _kodePos!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provinsi = ref.watch(daftarProvinsiProvider);
    final kabupatenKota = _provinsi == null
        ? null
        : ref.watch(daftarKabupatenKotaProvider(_provinsi!.kode));
    final kecamatan = _kabupatenKota == null
        ? null
        : ref.watch(daftarKecamatanProvider(_kabupatenKota!.kode));
    final kelurahanDesa = _kecamatan == null
        ? null
        : ref.watch(daftarKelurahanDesaProvider(_kecamatan!.kode));
    final kodePos = _kelurahanDesa == null
        ? null
        : ref.watch(daftarKodePosProvider(_kelurahanDesa!.kode));
    final filter = _filterUnit;
    final unit = filter == null ? null : ref.watch(daftarUnitProvider(filter));
    final sekolah = _unitTerpilih == null
        ? null
        : ref.watch(daftarSekolahProvider(_unitTerpilih!.id));
    final sedangMenyimpan = ref.watch(pilihanTersimpanProvider).isLoading;
    final riwayat = ref.watch(riwayatPilihanProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _IdentitasNuara(),
                  const SizedBox(height: 26),
                  Text(
                    'Temukan sekolah anak',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Pilih wilayah secara berurutan agar menu dan informasi dapur berasal dari SPPG yang tepat.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  riwayat.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (items) => items.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: _RiwayatPilihan(
                              items: items,
                              onPilih: (pilihan) => ref
                                  .read(pilihanTersimpanProvider.notifier)
                                  .gunakanRiwayat(pilihan),
                              onHapus: (pilihan) => ref
                                  .read(pilihanTersimpanProvider.notifier)
                                  .hapusRiwayat(pilihan),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _ProgressPilihan(
                    tahap: _sekolahTerpilih != null
                        ? 3
                        : _unitTerpilih != null
                        ? 2
                        : _filterUnit != null
                        ? 1
                        : 0,
                  ),
                  const SizedBox(height: 18),
                  _PanelPilihan(
                    nomor: 1,
                    judul: 'Pilih wilayah',
                    child: Column(
                      children: [
                        _WilayahDropdown(
                          label: 'Provinsi',
                          value: _provinsi,
                          data: provinsi,
                          onChanged: _pilihProvinsi,
                        ),
                        const SizedBox(height: 12),
                        _WilayahDropdown(
                          label: 'Kabupaten/Kota',
                          value: _kabupatenKota,
                          data: kabupatenKota,
                          disabledText: 'Pilih provinsi terlebih dahulu',
                          onChanged: _pilihKabupatenKota,
                        ),
                        const SizedBox(height: 12),
                        _WilayahDropdown(
                          label: 'Kecamatan',
                          value: _kecamatan,
                          data: kecamatan,
                          disabledText: 'Pilih kabupaten/kota terlebih dahulu',
                          onChanged: _pilihKecamatan,
                        ),
                        const SizedBox(height: 12),
                        _WilayahDropdown(
                          label: 'Kelurahan/Desa',
                          value: _kelurahanDesa,
                          data: kelurahanDesa,
                          disabledText: 'Pilih kecamatan terlebih dahulu',
                          onChanged: _pilihKelurahanDesa,
                        ),
                        const SizedBox(height: 12),
                        _KodePosDropdown(
                          value: _kodePos,
                          data: kodePos,
                          onChanged: (value) {
                            setState(() {
                              _kodePos = value;
                              _unitTerpilih = null;
                              _sekolahTerpilih = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PanelPilihan(
                    nomor: 2,
                    judul: 'Pilih unit SPPG',
                    child: _UnitDropdown(
                      value: _unitTerpilih,
                      data: unit,
                      onChanged: (value) {
                        setState(() {
                          _unitTerpilih = value;
                          _sekolahTerpilih = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PanelPilihan(
                    nomor: 3,
                    judul: 'Pilih sekolah',
                    child: _SekolahDropdown(
                      value: _sekolahTerpilih,
                      data: sekolah,
                      onChanged: (value) =>
                          setState(() => _sekolahTerpilih = value),
                    ),
                  ),
                  if (widget.kesalahanAwal != null) ...[
                    const SizedBox(height: 12),
                    _PesanInformasi(
                      icon: LucideIcons.triangleAlert,
                      color: AppColors.orange,
                      background: AppColors.orangeSoft,
                      text:
                          widget.kesalahanAwal is PilihanTidakTersediaException
                          ? 'Anda keluar dari beranda karena SPPG atau sekolah yang dipilih baru saja dinonaktifkan. Silakan pilih lokasi lain.'
                          : 'Pilihan sebelumnya tidak dapat dibaca. Silakan pilih kembali.',
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed:
                        _unitTerpilih != null &&
                            _sekolahTerpilih != null &&
                            !sedangMenyimpan
                        ? _simpan
                        : null,
                    icon: sedangMenyimpan
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.arrowRight, size: 20),
                    label: Text(sedangMenyimpan ? 'Menyimpan...' : 'Lanjutkan'),
                  ),
                  const SizedBox(height: 14),
                  const _CatatanPrivasi(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pilihProvinsi(Wilayah? value) {
    setState(() {
      _provinsi = value;
      _kabupatenKota = null;
      _kecamatan = null;
      _kelurahanDesa = null;
      _kodePos = null;
      _unitTerpilih = null;
      _sekolahTerpilih = null;
    });
  }

  void _pilihKabupatenKota(Wilayah? value) {
    setState(() {
      _kabupatenKota = value;
      _kecamatan = null;
      _kelurahanDesa = null;
      _kodePos = null;
      _unitTerpilih = null;
      _sekolahTerpilih = null;
    });
  }

  void _pilihKecamatan(Wilayah? value) {
    setState(() {
      _kecamatan = value;
      _kelurahanDesa = null;
      _kodePos = null;
      _unitTerpilih = null;
      _sekolahTerpilih = null;
    });
  }

  void _pilihKelurahanDesa(Wilayah? value) {
    setState(() {
      _kelurahanDesa = value;
      _kodePos = value?.kodePos;
      _unitTerpilih = null;
      _sekolahTerpilih = null;
    });
  }

  Future<void> _simpan() async {
    final unit = _unitTerpilih;
    final sekolah = _sekolahTerpilih;
    if (unit == null || sekolah == null) return;
    await ref.read(pilihanTersimpanProvider.notifier).simpan(unit, sekolah);
  }
}

class _RiwayatPilihan extends StatelessWidget {
  const _RiwayatPilihan({
    required this.items,
    required this.onPilih,
    required this.onHapus,
  });

  final List<PilihanTersimpan> items;
  final ValueChanged<PilihanTersimpan> onPilih;
  final ValueChanged<PilihanTersimpan> onHapus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.history,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Riwayat pilihan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (final item in items) ...[
          Material(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onPilih(item),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 6, 11),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        LucideIcons.school,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaSekolah,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.namaUnitSppg} - ${item.wilayah}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onHapus(item),
                      tooltip: 'Hapus dari riwayat',
                      icon: const Icon(LucideIcons.trash2, size: 18),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ProgressPilihan extends StatelessWidget {
  const _ProgressPilihan({required this.tahap});

  final int tahap;

  @override
  Widget build(BuildContext context) {
    const labels = ['Wilayah', 'SPPG', 'Sekolah'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: tahap > index ? 1 : 0,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tahap > index ? AppColors.primary : AppColors.muted,
                    fontWeight: tahap > index
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (index < labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _IdentitasNuara extends ConsumerWidget {
  const _IdentitasNuara();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset('assets/branding/nuara-mark.png'),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUARA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nutrisi Anak Nusantara',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Gunakan mode terang'
                : 'Gunakan mode gelap',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            color: Colors.white,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? LucideIcons.sun
                  : LucideIcons.moon,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelPilihan extends StatelessWidget {
  const _PanelPilihan({
    required this.nomor,
    required this.judul,
    required this.child,
  });

  final int nomor;
  final String judul;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$nomor',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(judul, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _WilayahDropdown extends StatelessWidget {
  const _WilayahDropdown({
    required this.label,
    required this.value,
    required this.data,
    required this.onChanged,
    this.disabledText = 'Data belum tersedia',
  });

  final String label;
  final Wilayah? value;
  final AsyncValue<List<Wilayah>>? data;
  final ValueChanged<Wilayah?> onChanged;
  final String disabledText;

  @override
  Widget build(BuildContext context) {
    final async = data;
    if (async == null) return _IsianStatus(text: disabledText);
    return async.when(
      loading: () => const _IsianStatus(text: 'Memuat data...', loading: true),
      error: (error, _) => _IsianGagal(message: pesanDio(error)),
      data: (items) {
        if (items.isEmpty) {
          return const _SegeraDatang(text: 'Data wilayah Segera Datang');
        }
        return DropdownButtonFormField<Wilayah>(
          key: ValueKey('$label-${value?.kode}-${items.length}'),
          initialValue: value,
          isExpanded: true,
          menuMaxHeight: 340,
          icon: const Icon(LucideIcons.chevronDown, size: 19),
          hint: Text('Pilih $label'),
          decoration: InputDecoration(labelText: label),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.nama, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _KodePosDropdown extends StatelessWidget {
  const _KodePosDropdown({
    required this.value,
    required this.data,
    required this.onChanged,
  });

  final String? value;
  final AsyncValue<List<String>>? data;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final async = data;
    if (async == null) {
      return const _IsianStatus(text: 'Pilih kelurahan/desa terlebih dahulu');
    }
    return async.when(
      loading: () =>
          const _IsianStatus(text: 'Memuat kode pos...', loading: true),
      error: (error, _) => _IsianGagal(message: pesanDio(error)),
      data: (items) {
        if (items.isEmpty) {
          return const _SegeraDatang(text: 'Kode pos Segera Datang');
        }
        final selected = items.contains(value) ? value : items.first;
        if (value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(selected);
          });
        }
        return DropdownButtonFormField<String>(
          key: ValueKey('kode-pos-$selected-${items.length}'),
          initialValue: selected,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 19),
          decoration: const InputDecoration(labelText: 'Kode pos'),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(growable: false),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({
    required this.value,
    required this.data,
    required this.onChanged,
  });

  final UnitSppg? value;
  final AsyncValue<HasilDaftarUnit>? data;
  final ValueChanged<UnitSppg?> onChanged;

  @override
  Widget build(BuildContext context) {
    final async = data;
    if (async == null) {
      return const _IsianStatus(
        text: 'Lengkapi pilihan wilayah terlebih dahulu',
      );
    }
    return async.when(
      loading: () => const _IsianStatus(text: 'Mencari SPPG...', loading: true),
      error: (error, _) => _IsianGagal(message: pesanDio(error)),
      data: (hasil) {
        final items = hasil.unit;
        if (items.isEmpty) {
          return _SegeraDatang(
            text: hasil.adaUnitNonaktif
                ? 'Unit SPPG di wilayah ini sedang dinonaktifkan'
                : 'Unit SPPG di wilayah ini Segera Datang',
          );
        }
        return DropdownButtonFormField<UnitSppg>(
          key: ValueKey('unit-${value?.id}-${items.length}'),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 19),
          hint: const Text('Pilih unit SPPG'),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.nama, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SekolahDropdown extends StatelessWidget {
  const _SekolahDropdown({
    required this.value,
    required this.data,
    required this.onChanged,
  });

  final Sekolah? value;
  final AsyncValue<List<Sekolah>>? data;
  final ValueChanged<Sekolah?> onChanged;

  @override
  Widget build(BuildContext context) {
    final async = data;
    if (async == null) {
      return const _IsianStatus(text: 'Pilih unit SPPG terlebih dahulu');
    }
    return async.when(
      loading: () =>
          const _IsianStatus(text: 'Memuat sekolah...', loading: true),
      error: (error, _) => _IsianGagal(message: pesanDio(error)),
      data: (items) {
        if (items.isEmpty) {
          return const _SegeraDatang(text: 'Sekolah binaan Segera Datang');
        }
        return DropdownButtonFormField<Sekolah>(
          key: ValueKey('sekolah-${value?.id}-${items.length}'),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 19),
          hint: const Text('Pilih sekolah'),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.nama, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _IsianStatus extends StatelessWidget {
  const _IsianStatus({required this.text, this.loading = false});

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (loading) ...[
            const SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegeraDatang extends StatelessWidget {
  const _SegeraDatang({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _PesanInformasi(
      icon: LucideIcons.clock3,
      color: AppColors.orange,
      background: AppColors.orangeSoft,
      text: text,
    );
  }
}

class _IsianGagal extends StatelessWidget {
  const _IsianGagal({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _PesanInformasi(
      icon: LucideIcons.wifiOff,
      color: AppColors.red,
      background: AppColors.redSoft,
      text: message,
    );
  }
}

class _PesanInformasi extends StatelessWidget {
  const _PesanInformasi({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.onSoft)),
          ),
        ],
      ),
    );
  }
}

class _CatatanPrivasi extends StatelessWidget {
  const _CatatanPrivasi();

  @override
  Widget build(BuildContext context) {
    return const _PesanInformasi(
      icon: LucideIcons.shieldCheck,
      color: AppColors.blue,
      background: AppColors.blueSoft,
      text:
          'Pilihan tersimpan hanya di perangkat ini. NUARA tidak meminta NIK, KK, atau nama anak.',
    );
  }
}
