import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../aduan/presentation/aduan_page.dart';
import '../../pilihan_sekolah/models/pilihan_tersimpan.dart';
import '../../pilihan_sekolah/providers/pilihan_providers.dart';
import 'beranda_page.dart';
import 'riwayat_page.dart';
import 'smart_dinner_page.dart';

class UtamaPage extends ConsumerStatefulWidget {
  const UtamaPage({super.key, required this.pilihan});

  final PilihanTersimpan pilihan;

  @override
  ConsumerState<UtamaPage> createState() => _UtamaPageState();
}

class _UtamaPageState extends ConsumerState<UtamaPage>
    with WidgetsBindingObserver {
  int _indeks = 0;
  bool _sedangMemvalidasi = false;
  Timer? _timerValidasi;

  static const _judulHalaman = [
    'Beranda',
    'Riwayat menu',
    'Makan malam',
    'Aduan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _validasiPilihan());
    _timerValidasi = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _validasiPilihan(),
    );
  }

  @override
  void dispose() {
    _timerValidasi?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _validasiPilihan();
  }

  Future<void> _validasiPilihan() async {
    if (_sedangMemvalidasi || !mounted) return;
    _sedangMemvalidasi = true;
    try {
      await ref
          .read(pilihanTersimpanProvider.notifier)
          .validasi(widget.pilihan);
    } finally {
      _sedangMemvalidasi = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _MerekNuara(
          judulHalaman: _judulHalaman[_indeks],
          namaUnitSppg: widget.pilihan.namaUnitSppg,
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Gunakan mode terang'
                : 'Gunakan mode gelap',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? LucideIcons.sun
                  : LucideIcons.moon,
              size: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filledTonal(
              onPressed: () =>
                  ref.read(pilihanTersimpanProvider.notifier).hapus(),
              tooltip: 'Ganti sekolah',
              icon: const Icon(LucideIcons.mapPinned, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _indeks,
          children: [
            BerandaPage(pilihan: widget.pilihan),
            RiwayatPage(pilihan: widget.pilihan),
            SmartDinnerPage(pilihan: widget.pilihan),
            AduanPage(pilihan: widget.pilihan),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _indeks,
            onDestinationSelected: (value) => setState(() => _indeks = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(LucideIcons.house),
                selectedIcon: Icon(LucideIcons.house),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.calendarDays),
                selectedIcon: Icon(LucideIcons.calendarDays),
                label: 'Riwayat',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.chefHat),
                selectedIcon: Icon(LucideIcons.chefHat),
                label: 'Makan malam',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.messageSquareWarning),
                selectedIcon: Icon(LucideIcons.messageSquareWarning),
                label: 'Aduan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerekNuara extends StatelessWidget {
  const _MerekNuara({required this.judulHalaman, required this.namaUnitSppg});

  final String judulHalaman;
  final String namaUnitSppg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset('assets/branding/nuara-mark.png'),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Halo, Selamat Datang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 1),
              Text(
                'Di $namaUnitSppg  |  $judulHalaman',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
