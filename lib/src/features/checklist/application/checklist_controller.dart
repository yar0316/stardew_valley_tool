import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/application/today_controller.dart';
import '../../dashboard/domain/models.dart';
import '../domain/check_item.dart';

class ChecklistState {
  final DayKey key;
  final List<ChecklistItem> items;
  const ChecklistState({required this.key, required this.items});

  ChecklistState copyWith({DayKey? key, List<ChecklistItem>? items}) =>
      ChecklistState(key: key ?? this.key, items: items ?? this.items);
}

class ChecklistController extends StateNotifier<ChecklistState> {
  ChecklistController(this.ref)
      : super(
          ChecklistState(
            key: const DayKey(year: 1, season: Season.spring, dayOfMonth: 1),
            items: const [],
          ),
        ) {
    _syncFromToday();
  }

  final Ref ref;

  // Keeps manual edits and checked states per day
  final Map<DayKey, List<ChecklistItem>> _manualByDay = {};
  final Map<DayKey, Map<String, bool>> _checkedByDay = {};

  void _syncFromToday() {
    final today = ref.read(todayProvider).info;
    final key = DayKey(year: today.year, season: today.season, dayOfMonth: today.dayOfMonth);
    // baseline: auto items (events + watering rule)
    final baseline = _autoItemsFor(today);
    // merge manual
    final manual = _manualByDay[key] ?? const <ChecklistItem>[];
    final merged = [...baseline, ...manual];
    // apply checked state
    final checked = _checkedByDay[key] ?? const <String, bool>{};
    final withChecked = merged
        .map((e) => e.copyWith(isChecked: checked[e.id] ?? e.isChecked))
        .toList()
      ..sort((a, b) {
        int priA = (a.isRequired ? 0 : 1);
        int priB = (b.isRequired ? 0 : 1);
        if (priA != priB) return priA - priB;
        // events first by time
        if (a.timeMinutes != null && b.timeMinutes != null) {
          return a.timeMinutes!.compareTo(b.timeMinutes!);
        }
        if (a.timeMinutes != null) return -1;
        if (b.timeMinutes != null) return 1;
        return a.title.compareTo(b.title);
      });
    state = ChecklistState(key: key, items: withChecked);
  }

  void onTodayChanged() => _syncFromToday();

  void toggle(String id, bool value) {
    final key = state.key;
    final cur = Map<String, bool>.from(_checkedByDay[key] ?? const {});
    cur[id] = value;
    _checkedByDay[key] = cur;
    _syncFromToday();
  }

  void addCustomItem(String title) {
    final key = state.key;
    final items = List<ChecklistItem>.from(_manualByDay[key] ?? const <ChecklistItem>[]);
    final id = 'custom:${items.length + 1}:${DateTime.now().millisecondsSinceEpoch}';
    items.add(
      ChecklistItem(
        id: id,
        type: ChecklistItemType.custom,
        title: title,
        timeMinutes: null,
        isRequired: false,
        isChecked: false,
        source: ChecklistItemSource.manual,
      ),
    );
    _manualByDay[key] = items;
    _syncFromToday();
  }

  void removeItem(String id) {
    final key = state.key;
    final items = List<ChecklistItem>.from(_manualByDay[key] ?? const <ChecklistItem>[]);
    items.removeWhere((e) => e.id == id);
    _manualByDay[key] = items;
    _syncFromToday();
  }

  List<ChecklistItem> _autoItemsFor(TodayInfo today) {
    final list = <ChecklistItem>[];
    // Watering: required, included every day; mark auto if rainy/storm
    final isRainy = today.weather == Weather.rain || today.weather == Weather.storm;
    list.add(
      ChecklistItem(
        id: 'watering',
        type: ChecklistItemType.watering,
        title: '水やり',
        timeMinutes: null,
        isRequired: true,
        isChecked: false, // no auto judgement for watering
        source: isRainy ? ChecklistItemSource.auto : ChecklistItemSource.manual,
      ),
    );
    // Events for today
    for (final ev in _eventsFor(today.season, today.dayOfMonth)) {
      list.add(ev);
    }
    return list;
  }

  List<ChecklistItem> _eventsFor(Season season, int dayOfMonth) {
    // Minimal built-in festival list with start times
    final events = <(Season, int, String, int)>[
      // Spring
      (Season.spring, 13, 'タマゴ祭り', 9 * 60),
      (Season.spring, 24, '花踊り', 9 * 60),
      // Summer
      (Season.summer, 11, 'ルアウ', 9 * 60),
      // Fall
      (Season.fall, 16, 'スターデューバレー祭', 9 * 60),
      (Season.fall, 27, 'スピリッツイブ', 10 * 60),
      // Winter
      (Season.winter, 8, '氷祭り', 9 * 60),
      (Season.winter, 15, 'ナイトマーケット', 17 * 60),
      (Season.winter, 16, 'ナイトマーケット', 17 * 60),
      (Season.winter, 17, 'ナイトマーケット', 17 * 60),
      (Season.winter, 25, '冬星祭り', 9 * 60),
    ];
    return events
        .where((e) => e.$1 == season && e.$2 == dayOfMonth)
        .map((e) => ChecklistItem(
              id: 'event:${e.$3}',
              type: ChecklistItemType.event,
              title: e.$3,
              timeMinutes: e.$4,
              isRequired: false,
              isChecked: false,
              source: ChecklistItemSource.auto,
            ))
        .toList();
  }
}

final checklistProvider = StateNotifierProvider<ChecklistController, ChecklistState>((ref) {
  final ctrl = ChecklistController(ref);
  // react to today changes
  ref.listen(todayProvider, (_, __) => ctrl.onTodayChanged());
  return ctrl;
});

