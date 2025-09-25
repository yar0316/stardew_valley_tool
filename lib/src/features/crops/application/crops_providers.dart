import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/domain/models.dart';
import '../domain/crop.dart';

// v1: 仮のスタブデータ（drift接続まではこれで表示）
final _sampleCropsProvider = Provider<List<Crop>>((ref) {
  return const [
    Crop(
      id: 1,
      key: 'parsnip',
      nameJa: 'パースニップ',
      sellPrice: 35,
      seedPrice: 20,
      daysToGrow: 4,
      regrowDays: null,
      avgYield: 1.0,
      seasonMask: 1,
      notes: null,
    ),
    Crop(
      id: 2,
      key: 'blueberry',
      nameJa: 'ブルーベリー',
      sellPrice: 50,
      seedPrice: 80,
      daysToGrow: 13,
      regrowDays: 4,
      avgYield: 3.0,
      seasonMask: 2,
      notes: '複数収穫',
    ),
  ];
});

class CropsQuery {
  final String keyword;
  final Season? season;
  const CropsQuery({this.keyword = '', this.season});
}

final cropsQueryProvider = StateProvider<CropsQuery>((ref) => const CropsQuery());

final filteredCropsProvider = Provider<List<Crop>>((ref) {
  final all = ref.watch(_sampleCropsProvider);
  final q = ref.watch(cropsQueryProvider);
  return all.where((c) {
    final kw = q.keyword.trim();
    final okKw = kw.isEmpty || c.nameJa.contains(kw);
    final okSeason = q.season == null || c.isInSeason(q.season!);
    return okKw && okSeason;
  }).toList();
});

