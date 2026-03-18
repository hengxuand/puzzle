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

  List<GameLevel> levelsForGroup(String groupId) {
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
      final Map<String, LevelGroup> seededGroups =
          _buildInitialGroupsFromConfig();
      final LevelProgressSnapshot seededSnapshot = LevelProgressSnapshot(
        groups: seededGroups,
      );

      unawaited(_storageService.saveProgressSnapshot(seededSnapshot));
      log.info('Initialized progress snapshot with seeded data.');
      progressSnapshot.value = seededSnapshot;
      return seededSnapshot;
    }
  }

  Map<String, LevelGroup> _buildInitialGroupsFromConfig() {
    return Map<String, LevelGroup>.fromEntries(
      Levels.levelGroups.map((group) {
        final Map<String, GameLevel> levels = group.levels.map((id, level) {
          final LevelProgressStatus status = level.orderInGroup == 1
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
}
