import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/npc.dart';
import '../../dashboard/domain/models.dart';

final pinnedNpcsProvider = StateProvider<List<Npc>>((ref) => const []);

class NpcScheduleParams {
  final String npcId;
  final Season season;
  final int dayOfMonth;
  final bool isRaining;
  const NpcScheduleParams({
    required this.npcId,
    required this.season,
    required this.dayOfMonth,
    required this.isRaining,
  });
}

final npcScheduleProvider = FutureProvider.autoDispose
    .family<List<NpcScheduleEntry>, NpcScheduleParams>((ref, p) async {
  // Sample schedules until DB wiring
  // Minimal example: a few entries that change with rain
  List<NpcScheduleEntry> mk(List<(int, String)> entries) =>
      entries.map((e) => NpcScheduleEntry(e.$1, e.$2)).toList();

  switch (p.npcId) {
    case 'abigail':
      if (p.isRaining) {
        return mk([
          (9, '自宅'),
          (12, '酒場'),
          (20, '自宅'),
        ]);
      }
      return mk([
        (9, '自宅'),
        (13, '町広場'),
        (18, '橋付近'),
        (20, '自宅'),
      ]);
    case 'sebastian':
      return mk([
        (9, '自室'),
        (12, '鉄道脇'),
        (19, '自室'),
      ]);
    case 'leah':
      return mk([
        (9, '小屋'),
        (12, '森'),
        (17, '酒場'),
      ]);
    default:
      return const <NpcScheduleEntry>[];
  }
});
