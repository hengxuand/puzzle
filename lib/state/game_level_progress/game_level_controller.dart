import 'dart:async';

import 'package:discovery_puzzle/models/game_level.dart';
import 'package:discovery_puzzle/models/level_group.dart';
import 'package:discovery_puzzle/models/level_progress_snapshot.dart';
import 'package:discovery_puzzle/models/level_progress_status.dart';
import 'package:discovery_puzzle/models/levels.dart';
import 'package:discovery_puzzle/service/progress_storage_service.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

class GameLevelController extends GetxController {
  final log = Logger('GameLevelController');
  final ProgressStorageService _storageService = Get.find();

  final progressSnapshot = Rx<LevelProgressSnapshot?>(null);
  final selectedGroupId = RxnInt();
  final selectedLevel = Rx<GameLevel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProgress();
    loadSelectedLevel();
  }

  Future<void> resetProgress() async {
    _storageService.clearProgressSnapshot();
    await loadProgress();
  }

  List<GameLevel> levelsForGroup(int groupId) {
    final LevelProgressSnapshot? snapshot = progressSnapshot.value;
    if (snapshot == null) {
      return [];
    }

    final LevelGroup? group = snapshot.groups[groupId];
    if (group == null) {
      return [];
    }

    return group.levels.values.toList(growable: false);
  }

  Future<GameLevel> loadSelectedLevel() async {
    GameLevel? level = _storageService.loadSelectedLevel();
    if (level == null) {
      log.warning('No previously selected level found in storage.');
      level = Levels.defaultLevel;
      unawaited(_storageService.saveSelectedLevel(level));
      _selectDefaultLevelForGroup(level.groupId);
      log.info('Initialized selected level in storage with default level.');
    }

    selectedLevel.value = level;
    selectedGroupId.value = level.groupId;
    return level;
  }

  void selectGroup(int groupId) {
    selectedGroupId.value = groupId;
    if (selectedLevel.value?.groupId != groupId) {
      _selectDefaultLevelForGroup(groupId);
    }
  }

  void _selectDefaultLevelForGroup(int groupId) {
    final LevelGroup? group = progressSnapshot.value?.groups[groupId];
    if (group == null || group.levels.isEmpty) {
      clearSelection();
      return;
    }

    final List<GameLevel> levels = group.levels.values.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));

    GameLevel? firstUnlockedNonCompleted;
    bool allCompleted = true;

    for (final GameLevel level in levels) {
      if (level.status == LevelProgressStatus.unlocked &&
          firstUnlockedNonCompleted == null) {
        firstUnlockedNonCompleted = level;
      }

      if (level.status != LevelProgressStatus.completed) {
        allCompleted = false;
      }
    }

    if (firstUnlockedNonCompleted != null) {
      selectLevel(firstUnlockedNonCompleted);
      return;
    }

    if (allCompleted) {
      selectLevel(levels.first);
      return;
    }

    selectLevel(levels.first);
  }

  void selectLevel(GameLevel level) {
    selectedLevel.value = level;
    selectedGroupId.value = level.groupId;
    unawaited(_storageService.saveSelectedLevel(level));
  }

  void clearSelection() {
    selectedGroupId.value = progressSnapshot.value?.groups.keys.first;
    _selectDefaultLevelForGroup(selectedGroupId.value!);
  }

  Future<LevelProgressSnapshot> loadProgress() async {
    final LevelProgressSnapshot? snapshot = _storageService
        .loadProgressSnapshot();
    if (snapshot != null) {
      log.info('Loaded progress snapshot from storage.');
      progressSnapshot.value = snapshot;
      return snapshot;
    } else {
      final Map<int, LevelGroup> seededGroups = _buildInitialGroupsFromConfig();
      final LevelProgressSnapshot seededSnapshot = LevelProgressSnapshot(
        groups: seededGroups,
      );

      unawaited(_storageService.saveProgressSnapshot(seededSnapshot));
      log.info('Initialized progress snapshot with seeded data.');
      progressSnapshot.value = seededSnapshot;
      return seededSnapshot;
    }
  }

  Map<int, LevelGroup> _buildInitialGroupsFromConfig() {
    return Map<int, LevelGroup>.fromEntries(
      Levels.levelGroups.map((group) {
        final List<int> sortedIds = group.levels.keys.toList()..sort();
        final int? firstLevelId = sortedIds.isEmpty ? null : sortedIds.first;

        final Map<int, GameLevel> levels = group.levels.map((id, level) {
          final LevelProgressStatus status = id == firstLevelId
              ? LevelProgressStatus.unlocked
              : LevelProgressStatus.locked;

          return MapEntry(id, level.copyWith(status: status));
        });

        return MapEntry(
          group.id,
          LevelGroup(
            id: group.id,
            name: group.name,
            description: group.description,
            order: group.order,
            levels: levels,
          ),
        );
      }),
    );
  }

  Future<void> markLevelCompleted(GameLevel? level) async {
    final LevelProgressSnapshot? snapshot = progressSnapshot.value;
    if (snapshot == null || level == null) {
      log.warning('Cannot mark level completed: snapshot or level is missing.');
      return;
    }

    final Map<int, LevelGroup> currentGroups = snapshot.groups;
    bool didUpdate = false;
    final Map<int, LevelGroup> updatedGroups = <int, LevelGroup>{};

    for (int groupId in currentGroups.keys) {
      final LevelGroup group = currentGroups[groupId]!;
      if (group.levels.containsKey(level.id)) {
        log.fine(
          'Found level ${level.id} in group $groupId, marking as completed.',
        );
        didUpdate = true;

        final Map<int, GameLevel> levels = Map<int, GameLevel>.from(
          group.levels,
        );

        final GameLevel levelToUpdate = levels[level.id]!;
        levels[level.id] = levelToUpdate.copyWith(
          status: LevelProgressStatus.completed,
        );

        // IDs are now integers, so the next level is current id + 1.
        final int nextLevelId = level.id + 1;
        final GameLevel? nextLevel = levels[nextLevelId];

        if (nextLevel != null) {
          log.fine('Unlocking next level $nextLevelId in group $groupId.');
          levels[nextLevel.id] = nextLevel.copyWith(
            status: LevelProgressStatus.unlocked,
          );
        }

        updatedGroups[groupId] = LevelGroup(
          id: group.id,
          name: group.name,
          description: group.description,
          order: group.order,
          levels: levels,
        );
      } else {
        updatedGroups[groupId] = group;
      }
    }

    if (!didUpdate) {
      log.warning('Cannot mark level completed: level ${level.id} not found.');
      return;
    }

    final LevelProgressSnapshot updatedSnapshot = LevelProgressSnapshot(
      groups: updatedGroups,
    );

    progressSnapshot.value = updatedSnapshot;
    await _storageService.saveProgressSnapshot(updatedSnapshot);
    _selectDefaultLevelForGroup(level.groupId);
  }
}
