import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_drawer.dart';
import '../application/buildings_providers.dart';
import '../application/farm_state_providers.dart';
import '../domain/building.dart';

class BuildingsPage extends ConsumerWidget {
  const BuildingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildings = ref.watch(buildingsProvider);
    final farm = ref.watch(farmStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('牧場施設')),
      drawer: const AppDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: buildings.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _BuildingTile(
          building: buildings[index],
          farm: farm,
        ),
      ),
    );
  }
}

class _BuildingTile extends StatelessWidget {
  const _BuildingTile({required this.building, required this.farm});
  final Building building;
  final FarmState farm;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.home_repair_service),
      title: Text(building.nameJa),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (building.id == 'coop' || building.id == 'barn')
          ..._animalFacilitySections(context)
        else if (building.levels == null) ...[
          _kv(context, '建設費', building.costG == null ? '-' : '${building.costG}g'),
          const SizedBox(height: 6),
          _kv(context, '材料', building.materials.isEmpty ? '-' : _materials(building.materials)),
          if (building.description != null) ...[
            const SizedBox(height: 8),
            _kv(context, '説明', building.description!),
          ],
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text('アップグレード', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 6),
          ...building.levels!.map((lv) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _upgradeLevel(context, lv),
              )),
          if (building.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _kv(context, '説明', building.description!),
            ),
        ],
      ],
    );
  }

  List<Widget> _animalFacilitySections(BuildContext context) {
    final instances = building.id == 'coop' ? farm.coops : farm.barns;
    final current = instances.fold<int>(0, (a, b) => a + b.animals.length);
    final max = instances.fold<int>(0, (a, b) => a + b.maxCapacity);

    final Map<String, List<String>> bySpecies = {};
    for (final i in instances) {
      for (final a in i.animals) {
        bySpecies.putIfAbsent(a.speciesJa, () => <String>[]).add(a.nameJa);
      }
    }

    return [
      if (building.description != null)
        _kv(context, '説明', building.description!),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: Text('飼育中一覧($current/$max)', style: Theme.of(context).textTheme.titleMedium),
      ),
      const SizedBox(height: 6),
      if (bySpecies.isEmpty)
        const Text('飼育中の動物はいません')
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: bySpecies.entries.map((e) {
            final names = e.value;
            names.sort();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key} (${names.length})', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: names.map((n) => Chip(label: Text(n))).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: Text('所有中の${building.nameJa}', style: Theme.of(context).textTheme.titleMedium),
      ),
      const SizedBox(height: 6),
      ...instances.map(
        (i) => _kv(context, i.levelName, '${i.animals.length}/${i.maxCapacity}'),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: Text('次のアップグレード', style: Theme.of(context).textTheme.titleMedium),
      ),
      const SizedBox(height: 6),
      ..._nextUpgradeWidgets(context, instances),
    ];
  }

  List<Widget> _nextUpgradeWidgets(BuildContext context, List<FacilityInstance> instances) {
    final levels = building.levels ?? const <UpgradeLevel>[];
    if (levels.isEmpty) return [const Text('アップグレード情報はありません')];
    final children = <Widget>[];
    for (final inst in instances) {
      final idx = levels.indexWhere((lv) => lv.nameJa == inst.levelName);
      if (idx == -1 || idx == levels.length - 1) {
        children.add(_kv(context, inst.levelName, '最大（アップグレード不可）'));
      } else {
        final next = levels[idx + 1];
        children.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${inst.levelName} → ${next.nameJa}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            _kv(context, '建設費', '${next.costG}g'),
            const SizedBox(height: 2),
            _kv(context, '材料', _materials(next.materials)),
            if (next.description != null) ...[
              const SizedBox(height: 2),
              _kv(context, '説明', next.description!),
            ],
            const SizedBox(height: 8),
          ],
        ));
      }
    }
    return children.isEmpty ? [const Text('アップグレード済みで最大です')] : children;
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(k)),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  String _materials(List<MaterialReq> list) => list.map((m) => '${m.nameJa} x${m.qty}').join('・');

  Widget _upgradeLevel(BuildContext context, UpgradeLevel lv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lv.nameJa, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 2),
        _kv(context, '建設費', '${lv.costG}g'),
        const SizedBox(height: 2),
        _kv(context, '材料', _materials(lv.materials)),
        if (lv.description != null) ...[
          const SizedBox(height: 2),
          _kv(context, '説明', lv.description!),
        ]
      ],
    );
  }
}
