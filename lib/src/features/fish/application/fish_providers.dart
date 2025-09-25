import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../domain/fish.dart';
import '../../dashboard/domain/models.dart';
import '../../../core/db/database.dart';

class FishQueryParams {
  final Season season;
  final Weather weather;
  final int hour;
  const FishQueryParams({
    required this.season,
    required this.weather,
    required this.hour,
  });

  @override
  bool operator ==(Object other) =>
      other is FishQueryParams &&
      other.season == season &&
      other.weather == weather &&
      other.hour == hour;

  @override
  int get hashCode => Object.hash(season, weather, hour);
}

// Simple dummy list until Drift wiring
// Drift接続後はDB検索で取得

final availableFishProvider =
    FutureProvider.family<List<Fish>, FishQueryParams>((ref, p) async {
      final db = ref.read(appDatabaseProvider);
      final seasonMask = _maskOfSeason(p.season);
      final weatherMask = _maskOfWeather(p.weather);
      final minute = p.hour * 60;

      const sql = '''
    SELECT i.key AS id,
           i.name_ja AS name_ja,
           f.season_mask AS season_mask,
           f.weather_mask AS weather_mask,
           f.time_start AS time_start,
           f.time_end AS time_end,
           IFNULL(f.locations, '') AS locations,
           IFNULL(GROUP_CONCAT(b.name_ja), '') AS bundles
      FROM fish f
      JOIN item i ON i.id = f.item_id
      LEFT JOIN bundle_item bi ON bi.item_id = i.id
      LEFT JOIN bundle b ON b.id = bi.bundle_id
     WHERE (f.season_mask & ?1) != 0
       AND (f.weather_mask & ?2) != 0
       AND ?3 BETWEEN f.time_start AND f.time_end
     GROUP BY i.key, i.name_ja, f.season_mask, f.weather_mask, f.time_start, f.time_end, f.locations
     ORDER BY i.name_ja
  ''';

      final rows = await db
          .customSelect(
            sql,
            variables: [
              Variable.withInt(seasonMask),
              Variable.withInt(weatherMask),
              Variable.withInt(minute),
            ],
            readsFrom: {},
          )
          .get();

      return rows.map((r) {
        final locations = r
            .read<String>('locations')
            .split(RegExp(r'[、,]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final bundles = r
            .read<String>('bundles')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return Fish(
          id: r.read<String>('id'),
          nameJa: r.read<String>('name_ja'),
          description: null,
          isLegendary: false,
          seasonMask: r.read<int>('season_mask'),
          weatherMask: r.read<int>('weather_mask'),
          timeStartMinutes: r.read<int>('time_start'),
          timeEndMinutes: r.read<int>('time_end'),
          locations: locations,
          bundles: bundles,
        );
      }).toList();
    });

int _maskOfSeason(Season s) => switch (s) {
  Season.spring => 1,
  Season.summer => 2,
  Season.fall => 4,
  Season.winter => 8,
};
int _maskOfWeather(Weather w) => switch (w) {
  Weather.sunny => 1,
  Weather.rain => 2,
  Weather.storm => 4,
  Weather.wind => 8,
  Weather.snow => 16,
};
