class Goal {
  final String id;
  final String name;
  final Map<String, int> required; // itemKey -> qty
  final Map<String, int> have; // itemKey -> qty

  const Goal({
    required this.id,
    required this.name,
    required this.required,
    required this.have,
  });

  Map<String, int> get missing {
    final m = <String, int>{};
    for (final e in required.entries) {
      final h = have[e.key] ?? 0;
      final diff = e.value - h;
      if (diff > 0) m[e.key] = diff;
    }
    return m;
  }
}

