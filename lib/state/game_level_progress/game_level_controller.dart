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

  Rx<LevelProgressSnapshot?> progressSnapshot = Rx<LevelProgressSnapshot?>(
    null,
  );
  Rx<GameLevel?> selectedLevel = Rx<GameLevel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProgress();
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
  }
}
