import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/live_match_state.dart';

class LiveMatchService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference<Map<String, dynamic>> _matches =
      _db.collection('live_matches');

  static const String linkPrefix = 'https://purotruco.app/live/';
  static const String uriPrefix = 'purotruco://live/';

  static String buildShareValue(String matchId) => '$linkPrefix$matchId';

  static String? parseMatchId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      if (uri.scheme == 'purotruco' &&
          uri.host == 'live' &&
          uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
      if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.pathSegments.length >= 2 &&
          uri.pathSegments[uri.pathSegments.length - 2] == 'live') {
        return uri.pathSegments.last;
      }
    }

    final idPattern = RegExp(r'^[A-Za-z0-9_-]{8,80}$');
    return idPattern.hasMatch(trimmed) ? trimmed : null;
  }

  static Future<String> createMatch(LiveMatchState state) async {
    final app = Firebase.app();
    debugPrint(
      '[LiveMatch] Creating match ${state.id} '
      'project=${app.options.projectId} app=${app.name}',
    );
    final doc = _matches.doc(state.id);
    await doc.get(const GetOptions(source: Source.server)).timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        throw TimeoutException('Firestore server read timed out');
      },
    );
    await doc.set(state.toFirestore()).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw TimeoutException('Firestore server write timed out');
      },
    );
    debugPrint('[LiveMatch] Created match ${state.id}');
    return state.id;
  }

  static Future<void> updateMatch(LiveMatchState state) async {
    await _matches
        .doc(state.id)
        .set(
          state.toFirestore(),
          SetOptions(merge: true),
        )
        .timeout(const Duration(seconds: 12));
  }

  static Stream<LiveMatchState?> watchMatch(String matchId) {
    return _matches.doc(matchId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return LiveMatchState.fromFirestore(snapshot);
    });
  }
}
