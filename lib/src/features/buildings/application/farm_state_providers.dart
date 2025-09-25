import 'package:flutter_riverpod/flutter_riverpod.dart';

class FarmAnimal {
  final String speciesJa;
  final String nameJa;
  const FarmAnimal({required this.speciesJa, required this.nameJa});
}

class FacilityInstance {
  final String typeId; // 'coop' | 'barn'
  final String levelName; // must match one of Building.levels.nameJa
  final int maxCapacity;
  final List<FarmAnimal> animals;
  const FacilityInstance({
    required this.typeId,
    required this.levelName,
    required this.maxCapacity,
    required this.animals,
  });
}

class FarmState {
  final List<FacilityInstance> coops;
  final List<FacilityInstance> barns;
  const FarmState({required this.coops, required this.barns});
}

final farmStateProvider = Provider<FarmState>((ref) {
  // Sample: Coop instances
  final coop1 = FacilityInstance(
    typeId: 'coop',
    levelName: '大きな鶏小屋',
    maxCapacity: 8,
    animals: const [
      FarmAnimal(speciesJa: 'ニワトリ', nameJa: 'コケ太郎'),
      FarmAnimal(speciesJa: 'ニワトリ', nameJa: 'ピヨ美'),
      FarmAnimal(speciesJa: 'ニワトリ', nameJa: 'チキ丸'),
      FarmAnimal(speciesJa: 'ニワトリ', nameJa: 'たまごん'),
      FarmAnimal(speciesJa: 'アヒル', nameJa: 'ガーコ'),
      FarmAnimal(speciesJa: 'アヒル', nameJa: 'クワック'),
    ],
  );
  final coop2 = FacilityInstance(
    typeId: 'coop',
    levelName: '鶏小屋',
    maxCapacity: 4,
    animals: const [
      FarmAnimal(speciesJa: 'ニワトリ', nameJa: 'コケ吉'),
      FarmAnimal(speciesJa: 'ニワトリ', nameJa: 'ピヨ代'),
    ],
  );

  // Sample: Barn instances
  final barn1 = FacilityInstance(
    typeId: 'barn',
    levelName: '家畜小屋',
    maxCapacity: 4,
    animals: const [
      FarmAnimal(speciesJa: 'ウシ', nameJa: 'モー子'),
      FarmAnimal(speciesJa: 'ウシ', nameJa: 'モー太'),
    ],
  );
  return FarmState(coops: [coop1, coop2], barns: [barn1]);
});

