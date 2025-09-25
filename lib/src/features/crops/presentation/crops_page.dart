import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../dashboard/domain/models.dart';
import '../application/crops_providers.dart';
import '../domain/crop.dart';
import '../../../core/navigation/routes.dart';

class CropsPage extends ConsumerStatefulWidget {
  const CropsPage({super.key});

  @override
  ConsumerState<CropsPage> createState() => _CropsPageState();
}

class _CropsPageState extends ConsumerState<CropsPage> {
  final _controller = TextEditingController();
  Season? _season;

  @override
  void initState() {
    super.initState();
    // 初期クエリ反映
    ref.read(cropsQueryProvider.notifier).state = const CropsQuery();
  }

  @override
  Widget build(BuildContext context) {
    final crops = ref.watch(filteredCropsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('作物を確認')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: '作物名で検索',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => _updateQuery(keyword: v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<Season?>(
                  value: _season,
                  hint: const Text('季節'),
                  items: [
                    const DropdownMenuItem<Season?>(value: null, child: Text('全て')),
                    ...Season.values.map(
                      (s) => DropdownMenuItem<Season?>(value: s, child: Text(_seasonLabel(s))),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _season = v);
                    _updateQuery(season: v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: crops.isEmpty
                  ? const Center(child: Text('該当なし'))
                  : ListView.separated(
                      itemCount: crops.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = crops[index];
                        return _CropTile(crop: c);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(Routes.cropsPlan),
        icon: const Icon(Icons.timeline),
        label: const Text('作付け計画へ'),
      ),
    );
  }

  void _updateQuery({String? keyword, Season? season}) {
    final cur = ref.read(cropsQueryProvider);
    ref.read(cropsQueryProvider.notifier).state =
        CropsQuery(keyword: keyword ?? cur.keyword, season: season ?? cur.season);
  }

  String _seasonLabel(Season s) =>
      {Season.spring: '春', Season.summer: '夏', Season.fall: '秋', Season.winter: '冬'}[s]!;
}

class _CropTile extends StatelessWidget {
  const _CropTile({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.grass),
      title: Text(crop.nameJa),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            children: [
              Text('成長: ${crop.daysToGrow}日'),
              Text('再収穫: ${crop.regrowDays == null ? 'なし' : '${crop.regrowDays}日'}'),
              Text('平均収量: ${crop.avgYield.toStringAsFixed(1)}個/回'),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [
              Text('種: ${crop.seedPrice ?? '-'}g'),
              Text('出荷: ${crop.sellPrice ?? '-'}g'),
              Text('季節: ${_seasonMaskLabel(crop.seasonMask)}'),
            ],
          ),
          if (crop.notes != null) Text(crop.notes!),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new),
        tooltip: '作付け計画',
        onPressed: () {
          Navigator.of(context).pushNamed(Routes.cropsPlan, arguments: crop);
        },
      ),
    );
  }

  String _seasonMaskLabel(int mask) {
    final buf = <String>[];
    if ((mask & 1) != 0) buf.add('春');
    if ((mask & 2) != 0) buf.add('夏');
    if ((mask & 4) != 0) buf.add('秋');
    if ((mask & 8) != 0) buf.add('冬');
    return buf.join('・');
  }
}
