class LiveMatchState {
  final String id;
  final String nosotrosName;
  final String ellosName;
  final int nosotrosScore;
  final int ellosScore;
  final int targetScore;
  final bool hasBuenas;
  final bool nosotrosFinishedMalas;
  final bool ellosFinishedMalas;
  final String themeName;
  final String pointType;
  final String paletteName;
  final String gameModeLabel;
  final String? winner;
  final bool finished;
  final bool isLive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LiveMatchPointEvent> events;

  const LiveMatchState({
    required this.id,
    required this.nosotrosName,
    required this.ellosName,
    required this.nosotrosScore,
    required this.ellosScore,
    required this.targetScore,
    required this.hasBuenas,
    this.nosotrosFinishedMalas = false,
    this.ellosFinishedMalas = false,
    this.themeName = 'NAVY PROFUNDO',
    this.pointType = 'matches',
    this.paletteName = 'BORDÓ',
    required this.gameModeLabel,
    required this.winner,
    required this.finished,
    required this.isLive,
    required this.createdAt,
    required this.updatedAt,
    this.events = const [],
  });

  bool finishedMalasFor(String team) =>
      team == 'nosotros' ? nosotrosFinishedMalas : ellosFinishedMalas;

  factory LiveMatchState.fromRealtimeDatabase(
    String id,
    Map<dynamic, dynamic> data,
  ) {
    return LiveMatchState(
      id: id,
      nosotrosName: data['nosotrosName'] as String? ?? 'NOSOTROS',
      ellosName: data['ellosName'] as String? ?? 'ELLOS',
      nosotrosScore: data['nosotrosScore'] as int? ?? 0,
      ellosScore: data['ellosScore'] as int? ?? 0,
      targetScore: data['targetScore'] as int? ?? 30,
      hasBuenas: data['hasBuenas'] as bool? ?? true,
      nosotrosFinishedMalas: data['nosotrosFinishedMalas'] as bool? ?? false,
      ellosFinishedMalas: data['ellosFinishedMalas'] as bool? ?? false,
      themeName: data['themeName'] as String? ?? 'NAVY PROFUNDO',
      pointType: data['pointType'] as String? ?? 'matches',
      paletteName: data['paletteName'] as String? ?? 'BORDÓ',
      gameModeLabel: data['gameModeLabel'] as String? ?? '30 puntos - 15/15',
      winner: data['winner'] as String?,
      finished: data['finished'] as bool? ?? false,
      isLive: data['isLive'] as bool? ?? true,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      events: _readEvents(data['events']),
    );
  }

  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'nosotrosName': nosotrosName,
      'ellosName': ellosName,
      'nosotrosScore': nosotrosScore,
      'ellosScore': ellosScore,
      'targetScore': targetScore,
      'hasBuenas': hasBuenas,
      'nosotrosFinishedMalas': nosotrosFinishedMalas,
      'ellosFinishedMalas': ellosFinishedMalas,
      'themeName': themeName,
      'pointType': pointType,
      'paletteName': paletteName,
      'gameModeLabel': gameModeLabel,
      'winner': winner,
      'finished': finished,
      'isLive': isLive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get winnerName {
    if (winner == 'nosotros') return nosotrosName;
    if (winner == 'ellos') return ellosName;
    return '';
  }

  static DateTime _readDate(Object? value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static List<LiveMatchPointEvent> _readEvents(Object? value) {
    if (value is! Map) return const [];
    final events = <LiveMatchPointEvent>[];
    for (final entry in value.entries) {
      final eventValue = entry.value;
      if (eventValue is Map) {
        events.add(LiveMatchPointEvent.fromRealtimeDatabase(
          entry.key.toString(),
          eventValue,
        ));
      }
    }
    events.sort((a, b) => a.index.compareTo(b.index));
    return events;
  }
}

class LiveMatchPointEvent {
  final int index;
  final String team;
  final int delta;
  final DateTime timestamp;
  final int nosotrosTotal;
  final int ellosTotal;

  const LiveMatchPointEvent({
    required this.index,
    required this.team,
    required this.delta,
    required this.timestamp,
    required this.nosotrosTotal,
    required this.ellosTotal,
  });

  factory LiveMatchPointEvent.fromRealtimeDatabase(
    String key,
    Map<dynamic, dynamic> data,
  ) {
    return LiveMatchPointEvent(
      index: int.tryParse(key) ?? 0,
      team: data['team'] as String? ?? 'nosotros',
      delta: data['delta'] as int? ?? 0,
      timestamp: LiveMatchState._readDate(data['timestamp']),
      nosotrosTotal: data['nosotrosTotal'] as int? ?? 0,
      ellosTotal: data['ellosTotal'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toRealtimeDatabase() {
    return {
      'team': team,
      'delta': delta,
      'timestamp': timestamp.toIso8601String(),
      'nosotrosTotal': nosotrosTotal,
      'ellosTotal': ellosTotal,
    };
  }
}
