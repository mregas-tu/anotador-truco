class WorldCupEvent {
  // FIFA World Cup 2026: opening match Jun 11, 2026 — final Jul 19, 2026.
  static final DateTime start = DateTime(2026, 6, 11);
  static final DateTime end = DateTime(2026, 7, 19, 23, 59, 59);

  static const List<String> unlockedThemes = ["LA CANCHA", "ARGENTINA"];

  static bool get isActive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }
}
