enum Season { spring, summer, fall, winter }

enum Weather { sunny, rain, storm, wind, snow }

enum SpiritsMood { veryGood, good, neutral, bad, veryBad }

class TodayInfo {
  final int year;
  final Season season;
  final int dayOfMonth; // 1-28
  final Weather weather;
  final SpiritsMood spiritsMood;

  const TodayInfo({
    required this.year,
    required this.season,
    required this.dayOfMonth,
    required this.weather,
    required this.spiritsMood,
  });

  TodayInfo copyWith({
    int? year,
    Season? season,
    int? dayOfMonth,
    Weather? weather,
    SpiritsMood? spiritsMood,
  }) {
    return TodayInfo(
      year: year ?? this.year,
      season: season ?? this.season,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weather: weather ?? this.weather,
      spiritsMood: spiritsMood ?? this.spiritsMood,
    );
  }
}

