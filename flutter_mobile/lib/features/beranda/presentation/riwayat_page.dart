import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nuara_page_header.dart';
import '../../pilihan_sekolah/models/pilihan_tersimpan.dart';
import '../models/menu_harian.dart';
import '../providers/beranda_providers.dart';
import 'widgets/media_section.dart';

class RiwayatPage extends ConsumerStatefulWidget {
  const RiwayatPage({super.key, required this.pilihan});

  final PilihanTersimpan pilihan;

  @override
  ConsumerState<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends ConsumerState<RiwayatPage> {
  int _jumlahHari = 7;

  FilterRiwayat get _filter =>
      (idSekolah: widget.pilihan.idSekolah, jumlahHari: _jumlahHari);

  @override
  Widget build(BuildContext context) {
    final riwayat = ref.watch(riwayatMenuProvider(_filter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(riwayatMenuProvider(_filter));
        await ref.read(riwayatMenuProvider(_filter).future);
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
                    eyebrow: 'Arsip dapur',
                    title: 'Riwayat menu',
                    subtitle:
                        'Lihat kembali menu dan nilai gizi yang telah dibagikan oleh dapur sekolah.',
                    icon: LucideIcons.calendarClock,
                  ),
                  const SizedBox(height: 16),
                  _SekolahRiwayat(nama: widget.pilihan.namaSekolah),
                  const SizedBox(height: 16),
                  SegmentedButton<int>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 hari')),
                      ButtonSegment(value: 14, label: Text('14 hari')),
                      ButtonSegment(value: 30, label: Text('30 hari')),
                    ],
                    selected: {_jumlahHari},
                    onSelectionChanged: (value) {
                      setState(() => _jumlahHari = value.first);
                    },
                  ),
                  const SizedBox(height: 18),
                  riwayat.when(
                    loading: () => const _MemuatRiwayat(),
                    error: (error, _) => _GagalRiwayat(
                      pesan: pesanDio(error),
                      onCobaLagi: () =>
                          ref.invalidate(riwayatMenuProvider(_filter)),
                    ),
                    data: (data) => data.isEmpty
                        ? const _RiwayatKosong()
                        : _DaftarRiwayat(data: data),
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

class _SekolahRiwayat extends StatelessWidget {
  const _SekolahRiwayat({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.school, color: AppColors.primary, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaftarRiwayat extends StatelessWidget {
  const _DaftarRiwayat({required this.data});

  final List<MenuHarian> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < data.length; index++) ...[
          _KartuRiwayat(menu: data[index]),
          if (index < data.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _KartuRiwayat extends StatelessWidget {
  const _KartuRiwayat({required this.menu});

  final MenuHarian menu;

  @override
  Widget build(BuildContext context) {
    final hariIni = DateUtils.isSameDay(menu.tanggalMenu, DateTime.now());
    final tanggal = hariIni
        ? 'Hari ini'
        : _kapital(
            DateFormat('EEEE, d MMMM', 'id_ID').format(menu.tanggalMenu),
          );

    return Card(
      child: InkWell(
        onTap: () => _bukaDetail(context, menu),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hariIni
                      ? AppColors.primarySoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  menu.media.any((item) => item.video)
                      ? LucideIcons.video
                      : menu.media.isNotEmpty
                      ? LucideIcons.image
                      : LucideIcons.utensils,
                  size: 21,
                  color: hariIni ? AppColors.primary : AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tanggal,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hariIni ? AppColors.primary : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.namaMenu,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        _RingkasNutrisi(
                          ikon: LucideIcons.flame,
                          teks: '${_angka(menu.kalori)} kkal',
                          warna: AppColors.orange,
                        ),
                        _RingkasNutrisi(
                          ikon: LucideIcons.dumbbell,
                          teks: '${_angka(menu.protein)} g',
                          warna: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.subtle,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingkasNutrisi extends StatelessWidget {
  const _RingkasNutrisi({
    required this.ikon,
    required this.teks,
    required this.warna,
  });

  final IconData ikon;
  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, color: warna, size: 15),
        const SizedBox(width: 5),
        Text(teks, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MemuatRiwayat extends StatelessWidget {
  const _MemuatRiwayat();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RiwayatKosong extends StatelessWidget {
  const _RiwayatKosong();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.calendarX, color: AppColors.orange, size: 34),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat menu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Menu yang sudah diterbitkan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GagalRiwayat extends StatelessWidget {
  const _GagalRiwayat({required this.pesan, required this.onCobaLagi});

  final String pesan;
  final VoidCallback onCobaLagi;

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
          const Icon(LucideIcons.wifiOff, color: AppColors.red, size: 32),
          const SizedBox(height: 12),
          Text(pesan, textAlign: TextAlign.center),
          const SizedBox(height: 14),
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

Future<void> _bukaDetail(BuildContext context, MenuHarian menu) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) =>
          _DetailRiwayat(menu: menu, controller: controller),
    ),
  );
}

class _DetailRiwayat extends StatelessWidget {
  const _DetailRiwayat({required this.menu, required this.controller});

  final MenuHarian menu;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _kapital(
            DateFormat('EEEE, d MMMM y', 'id_ID').format(menu.tanggalMenu),
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(menu.namaMenu, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 9),
        Text(
          menu.deskripsi,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        if (menu.media.isNotEmpty) ...[
          const SizedBox(height: 24),
          MediaSection(media: menu.media),
        ],
        const SizedBox(height: 26),
        _JudulDetail(
          ikon: LucideIcons.chartNoAxesColumnIncreasing,
          teks: 'Gizi',
        ),
        const SizedBox(height: 11),
        _GridNutrisiDetail(menu: menu),
        const SizedBox(height: 26),
        const _JudulDetail(ikon: LucideIcons.utensils, teks: 'Isi menu'),
        const SizedBox(height: 11),
        _KomponenDetail(komponen: menu.komponen),
        const SizedBox(height: 26),
        const _JudulDetail(ikon: LucideIcons.triangleAlert, teks: 'Alergi'),
        const SizedBox(height: 11),
        _AlergiDetail(alergi: menu.alergi),
        const SizedBox(height: 26),
        OutlinedButton.icon(
          onPressed: () => _bukaSumber(context, menu.urlSumberDataGizi),
          icon: const Icon(LucideIcons.externalLink, size: 17),
          label: Text('Sumber: ${menu.sumberDataGizi}'),
        ),
      ],
    );
  }
}

class _JudulDetail extends StatelessWidget {
  const _JudulDetail({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(teks, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

class _GridNutrisiDetail extends StatelessWidget {
  const _GridNutrisiDetail({required this.menu});

  final MenuHarian menu;

  @override
  Widget build(BuildContext context) {
    final data = [
      ('Kalori', menu.kalori, 'kkal', AppColors.orange),
      ('Protein', menu.protein, 'g', AppColors.primary),
      ('Lemak', menu.lemak, 'g', AppColors.red),
      ('Karbohidrat', menu.karbohidrat, 'g', AppColors.blue),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: data
              .map(
                (item) => Container(
                  width: width,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_angka(item.$2)} ${item.$3}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: item.$4),
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

class _KomponenDetail extends StatelessWidget {
  const _KomponenDetail({required this.komponen});

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
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(komponen[index].nama),
              subtitle: komponen[index].keteranganPorsi == null
                  ? null
                  : Text(komponen[index].keteranganPorsi!),
            ),
            if (index < komponen.length - 1)
              const Divider(height: 1, indent: 50),
          ],
        ],
      ),
    );
  }
}

class _AlergiDetail extends StatelessWidget {
  const _AlergiDetail({required this.alergi});

  final List<AlergiMenu> alergi;

  @override
  Widget build(BuildContext context) {
    if (alergi.isEmpty) {
      return const Text('Tidak ada kategori alergi yang dicantumkan.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: alergi
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _kapital(item.nama),
                style: const TextStyle(
                  color: Color(0xFF7A470A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(growable: false),
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

String _kapital(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
