import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/live_match_state.dart';

class LiveMatchService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final DatabaseReference _matches = _db.ref('live_matches');

  static const String linkPrefix = 'https://martostudio.com/purotruco/live/';
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
          uri.host == 'martostudio.com' &&
          uri.pathSegments.length >= 3 &&
          uri.pathSegments[0] == 'purotruco' &&
          uri.pathSegments[1] == 'live') {
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
    final ref = _matches.child(state.id);
    await ref.set(state.toRealtimeDatabase()).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw TimeoutException('Realtime Database write timed out');
      },
    );
    // If the host's connection drops for any reason — the app gets killed,
    // the phone dies, it never gets a chance to call stopHosting — the
    // server notices on its own and marks the match not-live, same as a
    // clean stop would. Registered only after the initial write: the
    // validation rules require the full match document to already exist
    // (hasChildren([...])), which isn't true yet before that first .set().
    await ref.onDisconnect().update({'isLive': false});
    debugPrint('[LiveMatch] Created match ${state.id}');
    return state.id;
  }

  static Future<void> cancelHostPresence(String matchId) async {
    await _matches.child(matchId).onDisconnect().cancel();
  }

  static Future<void> updateMatch(LiveMatchState state) async {
    await _matches.child(state.id).update(state.toRealtimeDatabase()).timeout(
          const Duration(seconds: 12),
        );
  }

  static Future<void> addEvent({
    required String matchId,
    required LiveMatchPointEvent event,
  }) async {
    final key = event.index.toString().padLeft(6, '0');
    await _matches
        .child(matchId)
        .child('events')
        .child(key)
        .set(event.toRealtimeDatabase())
        .timeout(const Duration(seconds: 12));
  }

  static Stream<LiveMatchState?> watchMatch(String matchId) {
    return _matches.child(matchId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      return LiveMatchState.fromRealtimeDatabase(matchId, value);
    });
  }

  /// Random, unique per viewing session — not persisted or tied to identity.
  static String generateViewerId() => _matches.push().key!;

  static Future<void> joinAsViewer({
    required String matchId,
    required String viewerId,
  }) async {
    final ref = _matches.child(matchId).child('viewers').child(viewerId);
    await ref.onDisconnect().remove();
    await ref.set(true);
  }

  static Future<void> leaveAsViewer({
    required String matchId,
    required String viewerId,
  }) async {
    final ref = _matches.child(matchId).child('viewers').child(viewerId);
    unawaited(ref.onDisconnect().cancel());
    await ref.remove();
  }

  static Stream<int> watchViewerCount(String matchId) {
    return _matches.child(matchId).child('viewers').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return 0;
      return value.length;
    });
  }
}
