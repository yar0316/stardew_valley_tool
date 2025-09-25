import 'package:flutter/material.dart';

import '../domain/crop.dart';

class CropsPlanPage extends StatefulWidget {
  const CropsPlanPage({super.key, this.crop});
  final Crop? crop;

  @override
  State<CropsPlanPage> createState() => _CropsPlanPageState();
}

class _CropsPlanPageState extends State<CropsPlanPage> {
  final _tilesCtrl = TextEditingController(text: '100');
  final _daysCtrl = TextEditingController(text: '28');

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    return Scaffold(
      appBar: AppBar(title: const Text('作付け計画')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (crop != null)
              Text(
                '対象作物: ${crop.nameJa}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _tilesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'タイル数'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '残り日数'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (crop != null)
              _CalcView(crop: crop, tilesCtrl: _tilesCtrl, daysCtrl: _daysCtrl),
            if (crop == null) const Text('作物を選択してから開くと詳細計算が表示されます'),
          ],
        ),
      ),
    );
  }
}

class _CalcView extends StatelessWidget {
  const _CalcView({
    required this.crop,
    required this.tilesCtrl,
    required this.daysCtrl,
  });
  final Crop crop;
  final TextEditingController tilesCtrl;
  final TextEditingController daysCtrl;

  @override
  Widget build(BuildContext context) {
    final tiles = int.tryParse(tilesCtrl.text) ?? 0;
    final days = int.tryParse(daysCtrl.text) ?? 0;
    final harvests = crop.potentialHarvestsInWindow(windowDays: days);
    final perTileProfit = crop.expectedProfitPerTile(windowDays: days);
    final totalProfit = (perTileProfit * tiles).round();
    final firstHarvestDay = days >= crop.daysToGrow ? crop.daysToGrow : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('収穫回数（期間内）: $harvests 回'),
        Text('1タイルあたり想定利益: $perTileProfit g'),
        Text('合計想定利益（$tiles タイル）: $totalProfit g'),
        if (firstHarvestDay != null) Text('初回収穫日: $firstHarvestDay 日目'),
        if (crop.isRegrowable) Text('以降の間隔: $crop 日ごと'),
      ],
    );
  }
}
