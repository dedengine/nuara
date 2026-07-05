import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../pilihan_sekolah/models/pilihan_tersimpan.dart';
import '../models/menu_harian.dart';
import '../models/target_nutrisi.dart';
import '../providers/beranda_providers.dart';
import 'widgets/media_section.dart';

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key, required this.pilihan});

  final PilihanTersimpan pilihan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuHariIniProvider(pilihan.idSekolah));
    final target = ref.watch(targetNutrisiProvider(pilihan.idSekolah));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(menuHariIniProvider(pilihan.idSekolah));
        ref.invalidate(targetNutrisiProvider(pilihan.idSekolah));
        await ref.read(menuHariIniProvider(pilihan.idSekolah).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SekolahAktif(pilihan: pilihan),
                  const SizedBox(height: 16),
                  menu.when(
                    loading: () => const _MemuatBeranda(),
                    error: (error, _) => _GagalMemuatMenu(
                      error: error,
                      onCobaLagi: () => ref.invalidate(
                        menuHariIniProvider(pilihan.idSekolah),
                      ),
                    ),
                    data: (data) => _IsiBeranda(menu: data, target: target),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SekolahAktif extends StatelessWidget {
  const _SekolahAktif({required this.pilihan});

  final PilihanTersimpan pilihan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.school,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pilihan.namaSekolah,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  pilihan.namaUnitSppg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IsiBeranda extends StatelessWidget {
  const _IsiBeranda({required this.menu, required this.target});

  final MenuHarian menu;
  final AsyncValue<TargetNutrisi> target;

  @override
  Widget build(BuildContext context) {
    final targetData = target.whenOrNull(data: (data) => data);
    final progress = targetData == null
        ? null
        : ([
                menu.kalori / targetData.kalori,
                menu.protein / targetData.protein,
                menu.lemak / targetData.lemak,
                menu.karbohidrat / targetData.karbohidrat,
              ].map((value) => value.clamp(0.0, 1.0)).reduce((a, b) => a + b) /
              4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MENU HARI INI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    LucideIcons.calendarDays,
                    color: Colors.white70,
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.namaMenu,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM y',
                            'id_ID',
                          ).format(menu.tanggalMenu),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(width: 14),
                    SizedBox.square(
                      dimension: 68,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            color: const Color(0xFF7ED0C1),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (menu.deskripsi.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  menu.deskripsi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (menu.media.isNotEmpty) ...[
          MediaSection(media: menu.media),
          const SizedBox(height: 24),
        ],
        _JudulBagian(
          ikon: LucideIcons.chartNoAxesColumnIncreasing,
          judul: 'Kandungan gizi',
        ),
        const SizedBox(height: 12),
        _NutrisiGrid(menu: menu, target: targetData),
        const SizedBox(height: 10),
        Text(
          targetData == null
              ? 'Target kecukupan sedang tidak tersedia; nilai menu tetap ditampilkan.'
              : 'Persentase menunjukkan kontribusi makan siang terhadap target sampai makan malam.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
        ),
        if (targetData != null) ...[
          const SizedBox(height: 4),
          _TautanSumber(
            label: 'Sumber target: ${targetData.sumber}',
            url: targetData.urlSumber,
          ),
        ],
        const SizedBox(height: 24),
        const _JudulBagian(ikon: LucideIcons.utensils, judul: 'Isi menu'),
        const SizedBox(height: 12),
        _DaftarKomponen(komponen: menu.komponen),
        const SizedBox(height: 24),
        const _JudulBagian(
          ikon: LucideIcons.triangleAlert,
          judul: 'Informasi alergi',
        ),
        const SizedBox(height: 12),
        _DaftarAlergi(alergi: menu.alergi),
        if (menu.media.isEmpty) ...[
          const SizedBox(height: 24),
          const MediaSection(media: []),
        ],
        const SizedBox(height: 24),
        _SumberMenu(menu: menu),
      ],
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian({required this.ikon, required this.judul});

  final IconData ikon;
  final String judul;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(judul, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

class _NutrisiGrid extends StatelessWidget {
  const _NutrisiGrid({required this.menu, required this.target});

  final MenuHarian menu;
  final TargetNutrisi? target;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DataNutrisi(
        label: 'Kalori',
        nilai: menu.kalori,
        satuan: 'kkal',
        target: target?.kalori,
        warna: AppColors.orange,
        latar: AppColors.orangeSoft,
        ikon: LucideIcons.flame,
      ),
      _DataNutrisi(
        label: 'Protein',
        nilai: menu.protein,
        satuan: 'g',
        target: target?.protein,
        warna: AppColors.primary,
        latar: AppColors.primarySoft,
        ikon: LucideIcons.dumbbell,
      ),
      _DataNutrisi(
        label: 'Lemak',
        nilai: menu.lemak,
        satuan: 'g',
        target: target?.lemak,
        warna: AppColors.red,
        latar: const Color(0xFFFBE9E9),
        ikon: LucideIcons.droplets,
      ),
      _DataNutrisi(
        label: 'Karbohidrat',
        nilai: menu.karbohidrat,
        satuan: 'g',
        target: target?.karbohidrat,
        warna: AppColors.blue,
        latar: AppColors.blueSoft,
        ikon: LucideIcons.wheat,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const jarak = 10.0;
        final lebar = (constraints.maxWidth - jarak) / 2;
        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: items
              .map(
                (item) => SizedBox(
                  width: lebar,
                  height: 134,
                  child: _KartuNutrisi(data: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _DataNutrisi {
  const _DataNutrisi({
    required this.label,
    required this.nilai,
    required this.satuan,
    required this.target,
    required this.warna,
    required this.latar,
    required this.ikon,
  });

  final String label;
  final double nilai;
  final String satuan;
  final double? target;
  final Color warna;
  final Color latar;
  final IconData ikon;
}

class _KartuNutrisi extends StatelessWidget {
  const _KartuNutrisi({required this.data});

  final _DataNutrisi data;

  @override
  Widget build(BuildContext context) {
    final rasio = data.target == null || data.target == 0
        ? null
        : (data.nilai / data.target!).clamp(0.0, 1.0);
    final persen = data.target == null || data.target == 0
        ? null
        : (data.nilai / data.target! * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: data.latar,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(data.ikon, color: data.warna, size: 17),
                ),
                const Spacer(),
                if (persen != null)
                  Text(
                    '$persen%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: data.warna,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '${_angka(data.nilai)} ${data.satuan}',
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(data.label, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: rasio,
                color: data.warna,
                backgroundColor: data.latar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaftarKomponen extends StatelessWidget {
  const _DaftarKomponen({required this.komponen});

  final List<KomponenMenu> komponen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var index = 0; index < komponen.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(komponen[index].nama),
                        if (komponen[index].keteranganPorsi case final porsi?)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              porsi,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < komponen.length - 1)
              const Divider(height: 1, indent: 50),
          ],
        ],
      ),
    );
  }
}

class _DaftarAlergi extends StatelessWidget {
  const _DaftarAlergi({required this.alergi});

  final List<AlergiMenu> alergi;

  @override
  Widget build(BuildContext context) {
    if (alergi.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.circleCheck, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tidak ada kategori alergi yang dicantumkan.',
                style: TextStyle(color: AppColors.onSoft),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: alergi
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF4D5A9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.triangleAlert,
                    color: Color(0xFFA65F0B),
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      _hurufAwalBesar(item.nama),
                      style: const TextStyle(
                        color: Color(0xFF7A470A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SumberMenu extends StatelessWidget {
  const _SumberMenu({required this.menu});

  final MenuHarian menu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sumber data gizi',
            style: const TextStyle(color: AppColors.onSoftMuted, fontSize: 12),
          ),
          const SizedBox(height: 3),
          _TautanSumber(
            label: menu.sumberDataGizi,
            url: menu.urlSumberDataGizi,
          ),
        ],
      ),
    );
  }
}

class _TautanSumber extends StatelessWidget {
  const _TautanSumber({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _bukaTautan(context, url),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              LucideIcons.externalLink,
              color: AppColors.blue,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _GagalMemuatMenu extends StatelessWidget {
  const _GagalMemuatMenu({required this.error, required this.onCobaLagi});

  final Object error;
  final VoidCallback onCobaLagi;

  bool get _menuKosong =>
      error is DioException &&
      (error as DioException).response?.statusCode == 404;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            _menuKosong ? LucideIcons.calendarX : LucideIcons.wifiOff,
            color: _menuKosong ? AppColors.orange : AppColors.red,
            size: 34,
          ),
          const SizedBox(height: 13),
          Text(
            _menuKosong ? 'Menu hari ini belum tersedia' : pesanDio(error),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_menuKosong) ...[
            const SizedBox(height: 6),
            Text(
              'Silakan periksa kembali setelah dapur memublikasikan menu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCobaLagi,
            icon: const Icon(LucideIcons.refreshCw, size: 17),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _MemuatBeranda extends StatelessWidget {
  const _MemuatBeranda();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 18,
          width: 140,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 24),
        const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

Future<void> _bukaTautan(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null &&
      await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Tautan belum dapat dibuka.')));
}

String _angka(double nilai) {
  return nilai == nilai.roundToDouble()
      ? nilai.toStringAsFixed(0)
      : nilai.toStringAsFixed(1);
}

String _hurufAwalBesar(String nilai) {
  if (nilai.isEmpty) return nilai;
  return '${nilai[0].toUpperCase()}${nilai.substring(1)}';
}
