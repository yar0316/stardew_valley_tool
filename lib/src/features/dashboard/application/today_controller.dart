import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';

class TodayState {
  final TodayInfo info;
  const TodayState(this.info);

  TodayState copyWith({TodayInfo? info}) => TodayState(info ?? this.info);
}

class TodayController extends StateNotifier<TodayState> {
  TodayController()
      : super(
          TodayState(
            const TodayInfo(
              year: 1,
              season: Season.spring,
              dayOfMonth: 1,
              weather: Weather.sunny,
              spiritsMood: SpiritsMood.neutral,
            ),
          ),
        );

  void setSeason(Season season) =>
      state = state.copyWith(info: state.info.copyWith(season: season));
  void setDay(int day) =>
      state = state.copyWith(info: state.info.copyWith(dayOfMonth: day));
  void setWeather(Weather weather) =>
      state = state.copyWith(info: state.info.copyWith(weather: weather));
  void setSpirits(SpiritsMood mood) =>
      state = state.copyWith(info: state.info.copyWith(spiritsMood: mood));
}

final todayProvider =
    StateNotifierProvider<TodayController, TodayState>((ref) => TodayController());

