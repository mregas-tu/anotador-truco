import 'dart:convert';

class MatchPointEvent {
  final String team;
  final int delta;
  final DateTime timestamp;
  final int nosotrosTotal;
  final int ellosTotal;

  const MatchPointEvent({
    required this.team,
    required this.delta,
    required this.timestamp,
    required this.nosotrosTotal,
    required this.ellosTotal,
  });

  Map<String, dynamic> toJson() => {
        'team': team,
        'delta': delta,
        'timestamp': timestamp.toIso8601String(),
        'nosotrosTotal': nosotrosTotal,
        'ellosTotal': ellosTotal,
      };

  factory MatchPointEvent.fromJson(Map<String, dynamic> json) =>
      MatchPointEvent(
        team: json['team'] as String,
        delta: json['delta'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        nosotrosTotal: json['nosotrosTotal'] as int,
        ellosTotal: json['ellosTotal'] as int,
      );
}

class MatchRecord {
  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String nosotrosName;
  final String ellosName;
  final int nosotrosScore;
  final int ellosScore;
  final int targetScore;
  final bool hasBuenas;
  final String winner;
  final List<MatchPointEvent> events;

  const MatchRecord({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.nosotrosName,
    required this.ellosName,
    required this.nosotrosScore,
    required this.ellosScore,
    required this.targetScore,
    required this.hasBuenas,
    required this.winner,
    required this.events,
  });

  int get milestone => hasBuenas ? targetScore ~/ 2 : targetScore;
  String get winnerName => winner == 'nosotros' ? nosotrosName : ellosName;

  int displayScore(int total) {
    if (!hasBuenas || total < milestone) return total;
    return total - milestone;
  }

  String scoreStage(int total) {
    if (!hasBuenas || total < milestone) return 'MALAS';
    return 'BUENAS';
  }

  String formattedScore(int total) =>
      '${displayScore(total)} ${scoreStage(total)}';

  Map<String, dynamic> toJson() => {
        'version': 1,
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'nosotrosName': nosotrosName,
        'ellosName': ellosName,
        'nosotrosScore': nosotrosScore,
        'ellosScore': ellosScore,
        'targetScore': targetScore,
        'hasBuenas': hasBuenas,
        'winner': winner,
        'events': events.map((event) => event.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        nosotrosName: json['nosotrosName'] as String,
        ellosName: json['ellosName'] as String,
        nosotrosScore: json['nosotrosScore'] as int,
        ellosScore: json['ellosScore'] as int,
        targetScore: json['targetScore'] as int,
        hasBuenas: json['hasBuenas'] as bool,
        winner: json['winner'] as String,
        events: (json['events'] as List<dynamic>? ?? const [])
            .map((event) =>
                MatchPointEvent.fromJson(event as Map<String, dynamic>))
            .toList(),
      );

  factory MatchRecord.decode(String value) =>
      MatchRecord.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
