import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nuara_page_header.dart';
import '../../pilihan_sekolah/models/pilihan_tersimpan.dart';
import '../models/smart_dinner.dart';
import '../providers/beranda_providers.dart';

class SmartDinnerPage extends ConsumerWidget {
  const SmartDinnerPage({super.key, required this.pilihan});

  final PilihanTersimpan pilihan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(smartDinnerProvider(pilihan.idSekolah));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(smartDinnerProvider(pilihan.idSekolah));
        await ref.read(smartDinnerProvider(pilihan.idSekolah).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NuaraPageHeader(
                    eyebrow: 'Pelengkap hari ini',
                    title: 'Smart Dinner',
                    subtitle:
                        'Rekomendasi makan malam untuk membantu melengkapi gizi dari menu sekolah.',
                    icon: LucideIcons.chefHat,
                  ),
                  const SizedBox(height: 20),
                  data.when(
                    loading: () => const _MemuatSmartDinner(),
                    error: (error, _) => _GagalSmartDinner(
                      error: error,
                      onCobaLagi: () => ref.invalidate(
                        smartDinnerProvider(pilihan.idSekolah),
                      ),
                    ),
                    data: (smartDinner) => _IsiSmartDinner(data: smartDinner),
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

class _IsiSmartDinner extends StatelessWidget {
  const _IsiSmartDinner({required this.data});

  final SmartDinner data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RingkasanSiang(data: data.makanSiang),
        const SizedBox(height: 26),
        const _JudulBagian(
          ikon: LucideIcons.chartNoAxesColumnIncreasing,
          teks: 'Masih perlu dilengkapi',
        ),
        const SizedBox(height: 5),
        Text(
          'Perkiraan selisih setelah makan siang hingga target makan malam.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 12),
        _GridKekurangan(nutrisi: data.kekurangan),
        const SizedBox(height: 28),
        _JudulBagian(
          ikon: LucideIcons.chefHat,
          teks: '${data.rekomendasi.length} rekomendasi makan malam',
        ),
        const SizedBox(height: 13),
        if (data.rekomendasi.isEmpty)
          const _RekomendasiKosong()
        else
          for (var index = 0; index < data.rekomendasi.length; index++) ...[
            _KartuRekomendasi(
              urutan: index + 1,
              rekomendasi: data.rekomendasi[index],
            ),
            if (index < data.rekomendasi.length - 1) const SizedBox(height: 12),
          ],
        const SizedBox(height: 24),
        _SumberTarget(data: data),
        const SizedBox(height: 12),
        _Catatan(catatan: data.catatan),
      ],
    );
  }
}

class _RingkasanSiang extends StatelessWidget {
  const _RingkasanSiang({required this.data});

  final RingkasanMakanSiang data;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(
                LucideIcons.sunMedium,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Makan siang sekolah',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              Text(
                data.jenjang,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.namaMenu,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM y', 'id_ID').format(data.tanggalMenu),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _NilaiRingkas('${_angka(data.nutrisi.kalori)} kkal'),
              _NilaiRingkas('${_angka(data.nutrisi.protein)} g protein'),
              _NilaiRingkas('${_angka(data.nutrisi.lemak)} g lemak'),
              _NilaiRingkas('${_angka(data.nutrisi.karbohidrat)} g karbo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NilaiRingkas extends StatelessWidget {
  const _NilaiRingkas(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        teks,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(teks, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

class _GridKekurangan extends StatelessWidget {
  const _GridKekurangan({required this.nutrisi});

  final NilaiNutrisi nutrisi;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Kalori', nutrisi.kalori, 'kkal', LucideIcons.flame, AppColors.orange),
      (
        'Protein',
        nutrisi.protein,
        'g',
        LucideIcons.dumbbell,
        AppColors.primary,
      ),
      ('Lemak', nutrisi.lemak, 'g', LucideIcons.droplets, AppColors.red),
      (
        'Karbohidrat',
        nutrisi.karbohidrat,
        'g',
        LucideIcons.wheat,
        AppColors.blue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => Container(
                  width: width,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$4, color: item.$5, size: 19),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_angka(item.$2)} ${item.$3}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              item.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _KartuRekomendasi extends StatelessWidget {
  const _KartuRekomendasi({required this.urutan, required this.rekomendasi});

  final int urutan;
  final RekomendasiMakanMalam rekomendasi;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: urutan == 1
                        ? AppColors.orangeSoft
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$urutan',
                    style: TextStyle(
                      color: urutan == 1
                          ? const Color(0xFFA65F0B)
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    rekomendasi.namaMenu,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_angka(rekomendasi.skorKecocokan)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rekomendasi.fokusNutrisi,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              rekomendasi.deskripsi,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Wrap(
              spacing: 13,
              runSpacing: 8,
              children: [
                _NutrisiRekomendasi(
                  label: '${_angka(rekomendasi.nutrisi.kalori)} kkal',
                  warna: AppColors.orange,
                ),
                _NutrisiRekomendasi(
                  label: '${_angka(rekomendasi.nutrisi.protein)} g protein',
                  warna: AppColors.primary,
                ),
                _NutrisiRekomendasi(
                  label: '${_angka(rekomendasi.nutrisi.lemak)} g lemak',
                  warna: AppColors.red,
                ),
                _NutrisiRekomendasi(
                  label: '${_angka(rekomendasi.nutrisi.karbohidrat)} g karbo',
                  warna: AppColors.blue,
                ),
                _NutrisiRekomendasi(
                  label: '${_angka(rekomendasi.serat)} g serat',
                  warna: const Color(0xFF6D7D32),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _bukaSumber(context, rekomendasi.urlSumberDataGizi),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.externalLink,
                      color: AppColors.blue,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rekomendasi.sumberDataGizi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrisiRekomendasi extends StatelessWidget {
  const _NutrisiRekomendasi({required this.label, required this.warna});

  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SumberTarget extends StatelessWidget {
  const _SumberTarget({required this.data});

  final SmartDinner data;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _bukaSumber(context, data.target.urlSumber),
      icon: const Icon(LucideIcons.externalLink, size: 17),
      label: Text('Sumber target: ${data.target.sumber}'),
    );
  }
}

class _Catatan extends StatelessWidget {
  const _Catatan({required this.catatan});

  final String catatan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, color: AppColors.blue, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              catatan,
              style: const TextStyle(
                color: AppColors.onSoftMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RekomendasiKosong extends StatelessWidget {
  const _RekomendasiKosong();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Rekomendasi makan malam belum tersedia.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _GagalSmartDinner extends StatelessWidget {
  const _GagalSmartDinner({required this.error, required this.onCobaLagi});

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
            _menuKosong ? LucideIcons.cookingPot : LucideIcons.wifiOff,
            color: _menuKosong ? AppColors.orange : AppColors.red,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            _menuKosong
                ? 'Rekomendasi hari ini belum tersedia'
                : pesanDio(error),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_menuKosong) ...[
            const SizedBox(height: 6),
            Text(
              'Smart Dinner akan tersedia setelah menu sekolah diterbitkan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 15),
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

class _MemuatSmartDinner extends StatelessWidget {
  const _MemuatSmartDinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

Future<void> _bukaSumber(BuildContext context, String url) async {
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

String _angka(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
