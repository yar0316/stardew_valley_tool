import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../dashboard/application/today_controller.dart';
import '../../dashboard/domain/models.dart';
import '../application/npc_providers.dart';
import '../application/npc_schedule_providers.dart';
import '../application/gift_providers.dart';
import '../domain/npc.dart';

class NpcPage extends ConsumerStatefulWidget {
  const NpcPage({super.key});

  @override
  ConsumerState<NpcPage> createState() => _NpcPageState();
}

class _NpcPageState extends ConsumerState<NpcPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(npcSearchProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider).info;
    final npcs = ref.watch(filteredNpcsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('住人を確認')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '住人名で検索',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => ref.read(npcSearchProvider.notifier).state = v,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: npcs.isEmpty
                  ? const Center(child: Text('該当なし'))
                  : ListView.separated(
                      itemCount: npcs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final npc = npcs[index];
                        return _NpcTile(npc: npc, today: today);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NpcTile extends ConsumerWidget {
  const _NpcTile({required this.npc, required this.today});
  final Npc npc;
  final TodayInfo today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedAsync = ref.watch(npcScheduleProvider(NpcScheduleParams(
      npcId: npc.id,
      season: today.season,
      dayOfMonth: today.dayOfMonth,
      isRaining: today.weather == Weather.rain || today.weather == Weather.storm,
    )));
    final gifts = ref.watch(giftableItemsProvider(npc.id));

    return ExpansionTile(
      leading: const Icon(Icons.person),
      title: Text(npc.nameJa),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('今日の行動', style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 6),
        schedAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('読込中...'),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('エラー: $e'),
          ),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('スケジュール情報はありません'),
                )
              : Column(
                  children: list
                      .map(
                        (e) => Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: Text(_fmtTime(e.hour)),
                            ),
                            Expanded(child: Text(e.place)),
                          ],
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('渡せるプレゼント', style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 6),
        if (gifts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('持ち物の中に「好き」以上はありません'),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gifts
                .map((g) => Chip(
                      avatar: Icon(
                        g.pref == GiftPref.love ? Icons.favorite : Icons.thumb_up,
                        color: g.pref == GiftPref.love ? Colors.pink : Colors.blue,
                        size: 18,
                      ),
                      label: Text('${g.item.nameJa}（${_prefJa(g.pref)}）'),
                    ))
                .toList(),
          ),
      ],
    );
  }

  String _fmtTime(int hour) => '${hour.toString().padLeft(2, '0')}:00';
  String _prefJa(GiftPref p) => {GiftPref.love: '大好き', GiftPref.like: '好き'}[p]!;
}

