import '../../dashboard/domain/models.dart';

class Crop {
  final int id;
  final String key;
  final String nameJa;
  final int? sellPrice; // 出荷価格（1個あたり）
  final int? seedPrice; // 種の価格
  final int daysToGrow; // 成長日数（初回）
  final int? regrowDays; // 再収穫間隔（日）
  final double avgYield; // 1回の収穫あたりの平均個数
  final int seasonMask; // 1:春 2:夏 4:秋 8:冬
  final String? notes; // 備考

  const Crop({
    required this.id,
    required this.key,
    required this.nameJa,
    required this.sellPrice,
    required this.seedPrice,
    required this.daysToGrow,
    required this.regrowDays,
    required this.avgYield,
    required this.seasonMask,
    required this.notes,
  });

  bool get isRegrowable => regrowDays != null && regrowDays! > 0;
  bool isInSeason(Season s) => (seasonMask & _maskOfSeason(s)) != 0;

  static int _maskOfSeason(Season s) {
    switch (s) {
      case Season.spring:
        return 1;
      case Season.summer:
        return 2;
      case Season.fall:
        return 4;
      case Season.winter:
        return 8;
    }
  }

  int potentialHarvestsInWindow({required int windowDays}) {
    if (windowDays < daysToGrow) return 0;
    if (!isRegrowable) return 1; // 初回のみ
    final remaining = windowDays - daysToGrow;
    return 1 + (remaining ~/ (regrowDays!));
  }

  double expectedProfitPerTile({required int windowDays}) {
    final harvests = potentialHarvestsInWindow(windowDays: windowDays);
    if (harvests == 0) return 0;
    final sell = (sellPrice ?? 0) * avgYield * harvests;
    final cost = (seedPrice ?? 0).toDouble();
    return sell - cost;
  }
}

