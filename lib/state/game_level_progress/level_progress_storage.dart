import 'dart:convert';

import 'package:discovery_puzzle/state/game_level_progress/level_progress_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_status.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressController extends GetxController {
  static const String _progressSnapshotKey = 'level_progress_snapshot_v1';
  static const String _selectedLevelKey = 'selected_level_id';
  static const String _unlockedLevelsKey = 'unlocked_level_ids';
  static const String _completedLevelsKey = 'completed_level_ids';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    final SharedPreferences? existing = _prefs;
    if (existing != null) {
      return existing;
    }
    final SharedPreferences initialized = await SharedPreferences.getInstance();
    _prefs = initialized;
    return initialized;
  }

  Future<LevelProgressSnapshot> load() async {
    final SharedPreferences prefs = await _getPrefs();

    final String? rawSnapshot = prefs.getString(_progressSnapshotKey);
    if (rawSnapshot != null && rawSnapshot.isNotEmpty) {
      final LevelProgressSnapshot? parsedSnapshot = _decodeSnapshot(
        rawSnapshot,
      );
      if (parsedSnapshot != null) {
        return parsedSnapshot;
      }
    }

    final String? selectedLevelId = prefs.getString(_selectedLevelKey);
    final List<String> unlockedLevelIds =
        prefs.getStringList(_unlockedLevelsKey) ?? const <String>[];
    final List<String> completedLevelIds =
        prefs.getStringList(_completedLevelsKey) ?? const <String>[];

    final Map<String, LevelProgressStatus> statuses =
        <String, LevelProgressStatus>{};
    for (final String id in unlockedLevelIds) {
      statuses[id] = LevelProgressStatus.unlocked;
    }
    for (final String id in completedLevelIds) {
      statuses[id] = LevelProgressStatus.completed;
    }

    final LevelProgressSnapshot migrated =
        LevelProgressSnapshot.fromLevelStatuses(
          selectedLevelId: selectedLevelId,
          statusByLevelId: statuses,
        );

    await saveSnapshot(migrated);
    return migrated;
  }

  Future<void> saveSnapshot(LevelProgressSnapshot snapshot) async {
    final SharedPreferences prefs = await _getPrefs();

    final LevelProgressSnapshot normalized =
        LevelProgressSnapshot.fromLevelStatuses(
          selectedLevelId: snapshot.selectedLevelId,
          statusByLevelId: snapshot.levelStatusById,
        );

    await prefs.setString(
      _progressSnapshotKey,
      jsonEncode(normalized.toJson()),
    );
    if (normalized.selectedLevelId == null) {
      await prefs.remove(_selectedLevelKey);
    } else {
      await prefs.setString(_selectedLevelKey, normalized.selectedLevelId!);
    }
    await prefs.setStringList(_unlockedLevelsKey, normalized.unlockedLevelIds);
    await prefs.setStringList(
      _completedLevelsKey,
      normalized.completedLevelIds,
    );
  }

  Future<void> saveSelectedLevel(String levelId) async {
    final LevelProgressSnapshot snapshot = await load();
    final Map<String, LevelProgressStatus> statuses = snapshot.levelStatusById;
    final LevelProgressStatus? current = statuses[levelId];
    if (current != null && current == LevelProgressStatus.unlocked) {
      statuses[levelId] = LevelProgressStatus.inProgress;
    }

    await saveSnapshot(
      LevelProgressSnapshot.fromLevelStatuses(
        selectedLevelId: levelId,
        statusByLevelId: statuses,
      ),
    );
  }

  LevelProgressSnapshot? _decodeSnapshot(String rawSnapshot) {
    try {
      final dynamic decoded = jsonDecode(rawSnapshot);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final dynamic groupsValue = decoded['groups'];
      if (groupsValue is! List<dynamic>) {
        return null;
      }

      final Map<String, LevelProgressStatus> statuses =
          <String, LevelProgressStatus>{};
      for (final dynamic groupRaw in groupsValue) {
        if (groupRaw is! Map<String, dynamic>) {
          continue;
        }
        final dynamic levelsRaw = groupRaw['levels'];
        if (levelsRaw is! List<dynamic>) {
          continue;
        }

        for (final dynamic levelRaw in levelsRaw) {
          if (levelRaw is! Map<String, dynamic>) {
            continue;
          }
          final dynamic levelId = levelRaw['levelId'];
          if (levelId is! String || levelId.isEmpty) {
            continue;
          }
          statuses[levelId] = LevelProgressStatusWire.fromWire(
            levelRaw['status'] as String?,
          );
        }
      }

      return LevelProgressSnapshot.fromLevelStatuses(
        selectedLevelId: decoded['selectedLevelId'] as String?,
        statusByLevelId: statuses,
      );
    } catch (_) {
      return null;
    }
  }
}
