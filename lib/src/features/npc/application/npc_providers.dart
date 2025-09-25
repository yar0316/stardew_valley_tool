import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/npc.dart';

// Sample NPC master list until Drift wiring
final allNpcsProvider = Provider<List<Npc>>((ref) {
  return const [
    Npc(id: 'abigail', nameJa: 'アビゲイル'),
    Npc(id: 'sebastian', nameJa: 'セバスチャン'),
    Npc(id: 'leah', nameJa: 'リア'),
  ];
});

final npcSearchProvider = StateProvider<String>((ref) => '');

final filteredNpcsProvider = Provider<List<Npc>>((ref) {
  final list = ref.watch(allNpcsProvider);
  final kw = ref.watch(npcSearchProvider).trim();
  if (kw.isEmpty) return list;
  return list.where((n) => n.nameJa.contains(kw)).toList();
});

