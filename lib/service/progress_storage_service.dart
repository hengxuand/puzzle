import 'dart:convert';

import 'package:discovery_puzzle/models/game_level.dart';
import 'package:discovery_puzzle/models/level_progress_snapshot.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logging/logging.dart';

class ProgressStorageService extends GetxService {
  final log = Logger('ProgressStorageService');

  ProgressStorageService({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  final GetStorage _storage;

  static const String _progressSnapshotKey = 'level_progress_snapshot';
  static const String _selectedLevelKey = 'selected_level';

  Future<void> saveProgressSnapshot(LevelProgressSnapshot snapshot) async {
    final jsonString = jsonEncode(snapshot.toJson());

    await _storage.write(_progressSnapshotKey, jsonString);
    log.info('Saved progress snapshot to storage.');
  }

  LevelProgressSnapshot? loadProgressSnapshot() {
    final String? jsonString = _storage.read<String>(_progressSnapshotKey);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    final Map<String, dynamic> decoded = jsonDecode(jsonString);

    return LevelProgressSnapshot.fromJson(decoded);
  }

  Future<void> clearProgressSnapshot() async {
    await _storage.remove(_progressSnapshotKey);
    log.info('Cleared progress snapshot from storage.');
  }

  Future<void> saveSelectedLevel(GameLevel selectedLevel) async {
    final jsonString = jsonEncode(selectedLevel.toJson());

    await _storage.write(_selectedLevelKey, jsonString);
    log.info('Saved selected level ${selectedLevel.id} to storage.');
  }

  GameLevel? loadSelectedLevel() {
    final String? jsonString = _storage.read<String>(_selectedLevelKey);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    final Map<String, dynamic> decoded = jsonDecode(jsonString);

    return GameLevel.fromJson(decoded);
  }

  Future<void> clearSelectedLevel() async {
    await _storage.remove(_selectedLevelKey);
    log.info('Cleared selected level from storage.');
  }
}
