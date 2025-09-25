enum Season { spring, summer, fall, winter }

enum Weather { sunny, rain, storm, wind, snow }

enum SpiritsMood { veryGood, good, neutral, bad, veryBad }

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class TodayInfo {
  final int year;
  final Season season;
  final int dayOfMonth; // 1-28
  final Weather weather;
  final SpiritsMood spiritsMood;
  final Weekday weekday;

  const TodayInfo({
    required this.year,
    required this.season,
    required this.dayOfMonth,
    required this.weather,
    required this.spiritsMood,
    required this.weekday,
  });

  TodayInfo copyWith({
    int? year,
    Season? season,
    int? dayOfMonth,
    Weather? weather,
    SpiritsMood? spiritsMood,
    Weekday? weekday,
  }) {
    return TodayInfo(
      year: year ?? this.year,
      season: season ?? this.season,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weather: weather ?? this.weather,
      spiritsMood: spiritsMood ?? this.spiritsMood,
      weekday: weekday ?? this.weekday,
    );
  }
}

