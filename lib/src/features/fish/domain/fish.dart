class Fish {
  final String id;
  final String nameJa;
  final String? description;
  final bool isLegendary;
  final int seasonMask; // 1:spring 2:summer 4:fall 8:winter
  final int weatherMask; // 1:sunny 2:rain 4:storm 8:wind 16:snow
  final int timeStartMinutes; // minutes from 0:00
  final int timeEndMinutes; // minutes from 0:00
  final List<String> locations; // human-readable
  final List<String> bundles; // bundle names

  const Fish({
    required this.id,
    required this.nameJa,
    this.description,
    this.isLegendary = false,
    required this.seasonMask,
    required this.weatherMask,
    required this.timeStartMinutes,
    required this.timeEndMinutes,
    this.locations = const [],
    this.bundles = const [],
  });
}
