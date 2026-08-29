import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMatchState {
  final String id;
  final String nosotrosName;
  final String ellosName;
  final int nosotrosScore;
  final int ellosScore;
  final int targetScore;
  final bool hasBuenas;
  final String gameModeLabel;
  final String? winner;
  final bool finished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LiveMatchState({
    required this.id,
    required this.nosotrosName,
    required this.ellosName,
    required this.nosotrosScore,
    required this.ellosScore,
    required this.targetScore,
    required this.hasBuenas,
    required this.gameModeLabel,
    required this.winner,
    required this.finished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LiveMatchState.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return LiveMatchState(
      id: snapshot.id,
      nosotrosName: data['nosotrosName'] as String? ?? 'NOSOTROS',
      ellosName: data['ellosName'] as String? ?? 'ELLOS',
      nosotrosScore: data['nosotrosScore'] as int? ?? 0,
      ellosScore: data['ellosScore'] as int? ?? 0,
      targetScore: data['targetScore'] as int? ?? 30,
      hasBuenas: data['hasBuenas'] as bool? ?? true,
      gameModeLabel: data['gameModeLabel'] as String? ?? '30 puntos - 15/15',
      winner: data['winner'] as String?,
      finished: data['finished'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nosotrosName': nosotrosName,
      'ellosName': ellosName,
      'nosotrosScore': nosotrosScore,
      'ellosScore': ellosScore,
      'targetScore': targetScore,
      'hasBuenas': hasBuenas,
      'gameModeLabel': gameModeLabel,
      'winner': winner,
      'finished': finished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get winnerName {
    if (winner == 'nosotros') return nosotrosName;
    if (winner == 'ellos') return ellosName;
    return '';
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
