import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/today_controller.dart';
import '../domain/models.dart';
import '../../fish/application/fish_providers.dart';
import '../../checklist/presentation/checklist_card.dart';
import '../../npc/application/npc_schedule_providers.dart';
import '../../fish/domain/fish.dart';
import '../../npc/domain/npc.dart';
import '../../../core/widgets/app_drawer.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider).info;
    final pinned = ref.watch(pinnedNpcsProvider);
    final fishAsync = ref.watch(availableFishProvider(FishQueryParams(
      season: today.season,
      weather: today.weather,
      hour: TimeOfDay.now().hour,
    )));
    // goals removed; checklist shown instead

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _TodayCard(today: today),
          const SizedBox(height: 12),
          // Replace goals block with checklist
          const ChecklistCard(),
          const SizedBox(height: 12),
          _FishCard(fishAsync: fishAsync),
          const SizedBox(height: 12),
          _NpcCard(pinnedNpcs: pinned),
        ],
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.today});
  final TodayInfo today;

  String _seasonLabel(Season s) =>
      {Season.spring: '春', Season.summer: '夏', Season.fall: '秋', Season.winter: '冬'}[s]!;
  String _weatherLabel(Weather w) => {
        Weather.sunny: '晴れ',
        Weather.rain: '雨',
        Weather.storm: '嵐',
        Weather.wind: '風',
        Weather.snow: '雪',
      }[w]!;
  String _spiritsLabel(SpiritsMood m) => {
        SpiritsMood.veryGood: 'とても良い',
        SpiritsMood.good: '良い',
        SpiritsMood.neutral: '普通',
        SpiritsMood.bad: '悪い',
        SpiritsMood.veryBad: 'とても悪い',
      }[m]!;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(todayProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('年: ${today.year}'),
                Text('季節: ${_seasonLabel(today.season)}'),
                Text('日付: ${today.dayOfMonth}日'),
                Text('天気: ${_weatherLabel(today.weather)}'),
                Text('精霊: ${_spiritsLabel(today.spiritsMood)}'),
              ],
            ),
            const Divider(),
            Row(
              children: [
                DropdownButton<Season>(
                  value: today.season,
                  items: Season.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(_seasonLabel(s))))
                      .toList(),
                  onChanged: (v) => v == null ? null : ctrl.setSeason(v),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: today.dayOfMonth,
                  items: List.generate(28, (i) => i + 1)
                      .map((d) => DropdownMenuItem(value: d, child: Text('$d日')))
                      .toList(),
                  onChanged: (v) => v == null ? null : ctrl.setDay(v),
                ),
                const SizedBox(width: 8),
                DropdownButton<Weather>(
                  value: today.weather,
                  items: Weather.values
                      .map((w) => DropdownMenuItem(value: w, child: Text(_weatherLabel(w))))
                      .toList(),
                  onChanged: (v) => v == null ? null : ctrl.setWeather(v),
                ),
                const SizedBox(width: 8),
                DropdownButton<SpiritsMood>(
                  value: today.spiritsMood,
                  items: SpiritsMood.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(_spiritsLabel(m))))
                      .toList(),
                  onChanged: (v) => v == null ? null : ctrl.setSpirits(v),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Goals card removed; replaced by ChecklistCard

class _FishCard extends StatelessWidget {
  const _FishCard({required this.fishAsync});
  final AsyncValue<List<Fish>> fishAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日釣れる魚', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            fishAsync.when(
              loading: () => const Text('読込中...'),
              error: (e, _) => Text('エラー: $e'),
              data: (list) => list.isEmpty
                  ? const Text('該当なし')
                  : Wrap(
                      spacing: 8,
                      children:
                          list.map((e) => Chip(label: Text(e.nameJa))).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NpcCard extends ConsumerWidget {
  const _NpcCard({required this.pinnedNpcs});
  final List<Npc> pinnedNpcs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NPCスケジュール', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (pinnedNpcs.isEmpty) const Text('ピン留めされた住人はいません'),
          ],
        ),
      ),
    );
  }
}
