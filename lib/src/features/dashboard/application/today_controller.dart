import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/save/save_locator.dart';
import '../../../core/save/save_models.dart';
import '../../../core/save/save_parser.dart';
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
              weekday: Weekday.monday,
            ),
          ),
        ) {
    _init();
  }
  StreamSubscription<SaveGameSummary?>? _saveSub;

  Future<void> _init() async {
    try {
      final saves = await SaveLocator.discoverSaves(includeSteamCloud: true);
      if (!mounted) return;
      SaveFolder? target;
      for (final folder in saves) {
        final hasInfo = folder.infoFilePath != null && File(folder.infoFilePath!).existsSync();
        final hasMain = folder.mainFilePath != null && File(folder.mainFilePath!).existsSync();
        if (hasInfo || hasMain) {
          target = folder;
          break;
        }
      }
      target ??= saves.isNotEmpty ? saves.first : null;
      if (target == null) return;
      _saveSub = SaveParser.watchSummary(target).listen(
        _applySummary,
        onError: (_) {},
      );
    } catch (_) {
      // ignore discovery errors
    }
  }

  void _applySummary(SaveGameSummary? summary) {
    if (!mounted || summary == null) return;
    final info = state.info;
    final season = _seasonFrom(summary.season) ?? info.season;
    final day = summary.dayOfMonth ?? info.dayOfMonth;
    final weather = _weatherFrom(summary) ?? info.weather;
    final spirits = _spiritsFrom(summary.dailyLuck) ?? info.spiritsMood;
    final weekday = _weekdayFromDay(day);
    state = state.copyWith(
      info: info.copyWith(
        year: summary.year ?? info.year,
        season: season,
        dayOfMonth: day,
        weather: weather,
        spiritsMood: spirits,
        weekday: weekday,
      ),
    );
  }

  Season? _seasonFrom(String? value) {
    switch (value?.toLowerCase()) {
      case 'spring':
        return Season.spring;
      case 'summer':
        return Season.summer;
      case 'fall':
      case 'autumn':
        return Season.fall;
      case 'winter':
        return Season.winter;
    }
    return null;
  }

  Weather? _weatherFrom(SaveGameSummary summary) {
    final icon = summary.weatherIcon?.toLowerCase();
    switch (icon) {
      case 'sunny':
      case 'sun':
        return Weather.sunny;
      case 'rain':
      case 'rainy':
        return Weather.rain;
      case 'storm':
      case 'lightning':
        return Weather.storm;
      case 'wind':
      case 'debris':
        return Weather.wind;
      case 'snow':
      case 'snowy':
        return Weather.snow;
    }
    if (summary.isSnowing == true) return Weather.snow;
    if (summary.isLightning == true) return Weather.storm;
    if (summary.isRaining == true) return Weather.rain;
    if (summary.isDebrisWeather == true) return Weather.wind;
    return null;
  }

  SpiritsMood? _spiritsFrom(double? luck) {
    if (luck == null) return null;
    if (luck >= 0.07) return SpiritsMood.veryGood;
    if (luck >= 0.02) return SpiritsMood.good;
    if (luck <= -0.07) return SpiritsMood.veryBad;
    if (luck <= -0.02) return SpiritsMood.bad;
    return SpiritsMood.neutral;
  }

  Weekday _weekdayFromDay(int day) {
    final length = Weekday.values.length;
    final index = ((day - 1) % length + length) % length;
    return Weekday.values[index];
  }

  void setSeason(Season season) =>
      state = state.copyWith(info: state.info.copyWith(season: season));
  void setDay(int day) => state = state.copyWith(
        info: state.info.copyWith(dayOfMonth: day, weekday: _weekdayFromDay(day)),
      );
  void setWeather(Weather weather) =>
      state = state.copyWith(info: state.info.copyWith(weather: weather));
  void setSpirits(SpiritsMood mood) =>
      state = state.copyWith(info: state.info.copyWith(spiritsMood: mood));

  @override
  void dispose() {
    _saveSub?.cancel();
    super.dispose();
  }
}

final todayProvider =
    StateNotifierProvider<TodayController, TodayState>((ref) => TodayController());

