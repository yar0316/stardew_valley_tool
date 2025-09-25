import '../../dashboard/domain/models.dart';

enum ChecklistItemType { event, watering, custom }

enum ChecklistItemSource { auto, manual }

class DayKey {
  final int year;
  final Season season;
  final int dayOfMonth; // 1-28

  const DayKey({required this.year, required this.season, required this.dayOfMonth});

  @override
  bool operator ==(Object other) =>
      other is DayKey && other.year == year && other.season == season && other.dayOfMonth == dayOfMonth;

  @override
  int get hashCode => Object.hash(year, season, dayOfMonth);
}

class ChecklistItem {
  final String id; // unique within a day
  final ChecklistItemType type;
  final String title;
  final int? timeMinutes; // start time in minutes since 0:00
  final bool isRequired;
  final bool isChecked;
  final ChecklistItemSource source;

  const ChecklistItem({
    required this.id,
    required this.type,
    required this.title,
    required this.timeMinutes,
    required this.isRequired,
    required this.isChecked,
    required this.source,
  });

  ChecklistItem copyWith({
    String? id,
    ChecklistItemType? type,
    String? title,
    int? timeMinutes,
    bool? isRequired,
    bool? isChecked,
    ChecklistItemSource? source,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      isRequired: isRequired ?? this.isRequired,
      isChecked: isChecked ?? this.isChecked,
      source: source ?? this.source,
    );
  }
}

