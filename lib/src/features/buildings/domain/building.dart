class MaterialReq {
  final String nameJa;
  final int qty;
  const MaterialReq({required this.nameJa, required this.qty});
}

class AnimalCapacity {
  final String speciesJa;
  final int current;
  final int max;
  const AnimalCapacity({required this.speciesJa, required this.current, required this.max});
}

class UpgradeLevel {
  final String nameJa; // 1段階目、2段階目 など
  final int costG; // 建設費（g）
  final List<MaterialReq> materials;
  final String? description;
  const UpgradeLevel({
    required this.nameJa,
    required this.costG,
    required this.materials,
    this.description,
  });
}

class Building {
  final String id;
  final String nameJa;
  final int? costG; // 建設費（g）
  final List<MaterialReq> materials;
  final String? description; // Wikiの説明（抜粋）
  final List<AnimalCapacity> animals; // Coop/Barn用
  final List<UpgradeLevel>? levels; // 家のアップグレード用

  const Building({
    required this.id,
    required this.nameJa,
    this.costG,
    this.materials = const [],
    this.description,
    this.animals = const [],
    this.levels,
  });
}

