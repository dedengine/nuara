import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/beranda/presentation/utama_page.dart';
import 'features/pilihan_sekolah/presentation/pilihan_sekolah_page.dart';
import 'features/pilihan_sekolah/providers/pilihan_providers.dart';

class NuaraApp extends ConsumerWidget {
  const NuaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pilihan = ref.watch(pilihanTersimpanProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Nuara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: pilihan.when(
        loading: () => const _LayarAwal(),
        error: (error, _) => PilihanSekolahPage(kesalahanAwal: error),
        data: (data) => data == null
            ? const PilihanSekolahPage()
            : UtamaPage(pilihan: data),
      ),
    );
  }
}

class _LayarAwal extends StatelessWidget {
  const _LayarAwal();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset('assets/branding/nuara-mark.png'),
              ),
              const SizedBox(height: 18),
              const Text(
                'NUARA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Nutrisi Anak Nusantara',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 26),
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
