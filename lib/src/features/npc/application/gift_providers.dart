import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryItem {
  final String key; // matches item.key
  final String nameJa;
  const InventoryItem({required this.key, required this.nameJa});
}

enum GiftPref { hate, dislike, neutral, like, love }

class GiftCandidate {
  final InventoryItem item;
  final GiftPref pref;
  const GiftCandidate(this.item, this.pref);
}

// Sample inventory until DB wiring
final inventoryProvider = Provider<List<InventoryItem>>((ref) {
  return const [
    InventoryItem(key: 'amethyst', nameJa: 'アメジスト'),
    InventoryItem(key: 'blueberry', nameJa: 'ブルーベリー'),
  ];
});

// Sample NPC preferences (subset). Real app: query from DB.
final _npcPreferences = <String, Map<String, GiftPref>>{
  'abigail': {
    'amethyst': GiftPref.love,
    'blueberry': GiftPref.like,
  },
  'sebastian': {
    'amethyst': GiftPref.like,
  },
  'leah': {
    'blueberry': GiftPref.like,
  },
};

final giftableItemsProvider = Provider.family<List<GiftCandidate>, String>((ref, npcId) {
  final inv = ref.watch(inventoryProvider);
  final prefs = _npcPreferences[npcId] ?? const <String, GiftPref>{};
  final res = <GiftCandidate>[];
  for (final it in inv) {
    final pref = prefs[it.key];
    if (pref == GiftPref.like || pref == GiftPref.love) {
      res.add(GiftCandidate(it, pref!));
    }
  }
  // love first
  res.sort((a, b) => (b.pref.index).compareTo(a.pref.index));
  return res;
});

