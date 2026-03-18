import 'dart:async';
import 'dart:convert';

import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_snapshot.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStorageService extends GetxService {
  late SharedPreferences _prefs;

  static const String _progressSnapshotKey = 'level_progress_snapshot_v1';

  Future<ProgressStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ✅ SAVE LIST
  Future<void> saveProgressSnapshot(LevelProgressSnapshot snapshot) async {
    final jsonString = jsonEncode(snapshot.toJson());

    await _prefs.setString(_progressSnapshotKey, jsonString);
  }

  // ✅ LOAD LIST
  LevelProgressSnapshot? loadProgressSnapshot() {
    final jsonString = _prefs.getString(_progressSnapshotKey);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    final Map<String, dynamic> decoded = jsonDecode(jsonString);

    return LevelProgressSnapshot.fromJson(decoded);
  }

  // ✅ CLEAR
  Future<void> clearGroups() async {
    await _prefs.remove(_progressSnapshotKey);
  }
}
