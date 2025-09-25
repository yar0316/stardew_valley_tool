import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/building.dart';

final buildingsProvider = Provider<List<Building>>((ref) {
  // 家のアップグレード（1つの施設扱い・最上段）
  const house = Building(
    id: 'house',
    nameJa: '家のアップグレード',
    levels: [
      UpgradeLevel(
        nameJa: '1段階目（キッチン追加）',
        costG: 10000,
        materials: [MaterialReq(nameJa: '木材', qty: 450)],
        description: 'キッチンが追加され、料理が作れるようになる。',
      ),
      UpgradeLevel(
        nameJa: '2段階目（子供部屋）',
        costG: 50000,
        materials: [MaterialReq(nameJa: '硬い木', qty: 150)],
        description: '寝室拡張と子供部屋が追加。',
      ),
      UpgradeLevel(
        nameJa: '3段階目（地下室）',
        costG: 100000,
        materials: [MaterialReq(nameJa: '石', qty: 100)],
        description: '地下室が追加され、熟成樽を設置できる。',
      ),
    ],
    materials: [],
    description: 'ロビンに依頼して家を拡張できる。段階ごとにコスト/素材が必要。',
  );

  const coop = Building(
    id: 'coop',
    nameJa: '鶏小屋',
    description: 'ニワトリ等の小型家畜を飼育できる施設。上位改築で飼育数/種類が増える。',
    levels: [
      UpgradeLevel(
        nameJa: '鶏小屋',
        costG: 4000,
        materials: [MaterialReq(nameJa: '木材', qty: 300), MaterialReq(nameJa: '石', qty: 100)],
        description: '基本の鶏小屋。4羽まで飼育可能。',
      ),
      UpgradeLevel(
        nameJa: '大きな鶏小屋',
        costG: 10000,
        materials: [MaterialReq(nameJa: '木材', qty: 400), MaterialReq(nameJa: '石', qty: 150)],
        description: 'アヒルが飼えるようになり、8羽まで飼育可能。',
      ),
      UpgradeLevel(
        nameJa: 'デラックス鶏小屋',
        costG: 20000,
        materials: [MaterialReq(nameJa: '木材', qty: 500), MaterialReq(nameJa: '石', qty: 200)],
        description: '自動給餌器付き。12羽まで飼育可能。',
      ),
    ],
  );

  const barn = Building(
    id: 'barn',
    nameJa: '家畜小屋',
    description: 'ウシ等の大型家畜を飼育できる施設。上位改築で飼育数/種類が増える。',
    levels: [
      UpgradeLevel(
        nameJa: '家畜小屋',
        costG: 6000,
        materials: [MaterialReq(nameJa: '木材', qty: 350), MaterialReq(nameJa: '石', qty: 150)],
        description: '基本の家畜小屋。4頭まで飼育可能。',
      ),
      UpgradeLevel(
        nameJa: '大きな家畜小屋',
        costG: 12000,
        materials: [MaterialReq(nameJa: '木材', qty: 450), MaterialReq(nameJa: '石', qty: 200)],
        description: 'ヤギが飼えるようになり、8頭まで飼育可能。',
      ),
      UpgradeLevel(
        nameJa: 'デラックス家畜小屋',
        costG: 25000,
        materials: [MaterialReq(nameJa: '木材', qty: 550), MaterialReq(nameJa: '石', qty: 300)],
        description: '自動給餌器付き。12頭まで飼育可能。',
      ),
    ],
  );

  const silo = Building(
    id: 'silo',
    nameJa: 'サイロ',
    costG: 100,
    materials: [
      MaterialReq(nameJa: '石', qty: 100),
      MaterialReq(nameJa: '粘土', qty: 10),
      MaterialReq(nameJa: '銅の延べ棒', qty: 5),
    ],
    description: '牧草を貯蔵できる。草を刈ると自動でサイロに入る。',
  );

  const well = Building(
    id: 'well',
    nameJa: '井戸',
    costG: 1000,
    materials: [
      MaterialReq(nameJa: '石', qty: 75),
    ],
    description: '水を汲める井戸。畑の近くに作ると便利。',
  );

  // 表示順: 家のアップグレードを最上段に、その後その他施設
  return const [house, coop, barn, silo, well];
});
