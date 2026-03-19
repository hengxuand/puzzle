import 'dart:convert';

import 'package:discovery_puzzle/models/level_progress_snapshot.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProgressStorageService extends GetxService {
  ProgressStorageService({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  final GetStorage _storage;

  static const String _progressSnapshotKey = 'level_progress_snapshot_v1';

  Future<void> saveProgressSnapshot(LevelProgressSnapshot snapshot) async {
    final jsonString = jsonEncode(snapshot.toJson());

    await _storage.write(_progressSnapshotKey, jsonString);
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
  }
}
