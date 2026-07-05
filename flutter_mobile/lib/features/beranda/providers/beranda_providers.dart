import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/beranda_repository.dart';
import '../models/menu_harian.dart';
import '../models/smart_dinner.dart';
import '../models/target_nutrisi.dart';

final berandaRepositoryProvider = Provider<BerandaRepository>((ref) {
  return BerandaRepository(ref.watch(dioProvider));
});

final menuHariIniProvider = FutureProvider.autoDispose.family<MenuHarian, int>((
  ref,
  idSekolah,
) {
  return ref.watch(berandaRepositoryProvider).menuHariIni(idSekolah);
});

final smartDinnerProvider = FutureProvider.autoDispose.family<SmartDinner, int>(
  (ref, idSekolah) {
    return ref.watch(berandaRepositoryProvider).smartDinner(idSekolah);
  },
);

final targetNutrisiProvider = FutureProvider.autoDispose
    .family<TargetNutrisi, int>((ref, idSekolah) async {
      return (await ref.watch(smartDinnerProvider(idSekolah).future)).target;
    });

typedef FilterRiwayat = ({int idSekolah, int jumlahHari});

final riwayatMenuProvider = FutureProvider.autoDispose
    .family<List<MenuHarian>, FilterRiwayat>((ref, filter) {
      return ref
          .watch(berandaRepositoryProvider)
          .riwayatMenu(filter.idSekolah, jumlahHari: filter.jumlahHari);
    });
