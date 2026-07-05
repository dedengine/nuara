import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/aduan_repository.dart';

final aduanRepositoryProvider = Provider<AduanRepository>((ref) {
  return AduanRepository(ref.watch(dioProvider));
});
