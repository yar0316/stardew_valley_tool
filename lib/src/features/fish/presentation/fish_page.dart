import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../dashboard/domain/models.dart';
import '../application/fish_providers.dart';

class FishPage extends ConsumerStatefulWidget {
  const FishPage({super.key});

  @override
  ConsumerState<FishPage> createState() => _FishPageState();
}

class _FishPageState extends ConsumerState<FishPage> {
  final _controller = TextEditingController();
  Season _season = Season.spring;
  Weather _weather = Weather.sunny;

  @override
  Widget build(BuildContext context) {
    final nowHour = TimeOfDay.now().hour;
    final async = ref.watch(
      availableFishProvider(
        FishQueryParams(season: _season, weather: _weather, hour: nowHour),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('魚を探す')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '魚名で検索（前方一致）',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                DropdownButton<Season>(
                  value: _season,
                  items: Season.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_seasonLabel(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _season = v ?? _season),
                ),
                DropdownButton<Weather>(
                  value: _weather,
                  items: Weather.values
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text(_weatherLabel(w)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _weather = v ?? _weather),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (list) {
                  final q = _controller.text.trim();
                  final filtered = q.isEmpty
                      ? list
                      : list.where((f) => f.nameJa.startsWith(q)).toList();
                  if (filtered.isEmpty) return const Text('該当なし');
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final f = filtered[i];
                      return ExpansionTile(
                        leading: Icon(
                          Icons.set_meal,
                          color: f.isLegendary ? Colors.orange : null,
                        ),
                        title: Text(f.nameJa),
                        subtitle: Text(
                          _fmtTimeRange(f.timeStartMinutes, f.timeEndMinutes),
                        ),
                        trailing: f.isLegendary
                            ? const Icon(Icons.stars, color: Colors.orange)
                            : null,
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          12,
                        ),
                        children: [
                          if (f.description != null &&
                              f.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(f.description!),
                              ),
                            ),
                          _section(
                            context,
                            '季節',
                            _maskLabelSeason(f.seasonMask),
                          ),
                          const SizedBox(height: 6),
                          _section(
                            context,
                            '天気',
                            _maskLabelWeather(f.weatherMask),
                          ),
                          const SizedBox(height: 6),
                          _section(
                            context,
                            '時間',
                            _fmtTimeRange(f.timeStartMinutes, f.timeEndMinutes),
                          ),
                          if (f.locations.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _section(context, '場所', f.locations.join('・')),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'バンドル',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (f.bundles.isEmpty)
                            const Text('該当なし')
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: f.bundles
                                  .map((b) => Chip(label: Text(b)))
                                  .toList(),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _seasonLabel(Season s) => {
    Season.spring: '春',
    Season.summer: '夏',
    Season.fall: '秋',
    Season.winter: '冬',
  }[s]!;
  String _weatherLabel(Weather w) => {
    Weather.sunny: '晴',
    Weather.rain: '雨',
    Weather.storm: '嵐',
    Weather.wind: '風',
    Weather.snow: '雪',
  }[w]!;

  String _fmtTimeRange(int start, int end) =>
      '${_fmtTime(start)}-${_fmtTime(end)}';
  String _fmtTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Widget _section(BuildContext context, String title, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _maskLabelSeason(int mask) {
    final buf = <String>[];
    if ((mask & 1) != 0) buf.add('春');
    if ((mask & 2) != 0) buf.add('夏');
    if ((mask & 4) != 0) buf.add('秋');
    if ((mask & 8) != 0) buf.add('冬');
    return buf.join('・');
  }

  String _maskLabelWeather(int mask) {
    final buf = <String>[];
    if ((mask & 1) != 0) buf.add('晴');
    if ((mask & 2) != 0) buf.add('雨');
    if ((mask & 4) != 0) buf.add('嵐');
    if ((mask & 8) != 0) buf.add('風');
    if ((mask & 16) != 0) buf.add('雪');
    return buf.join('・');
  }
}
