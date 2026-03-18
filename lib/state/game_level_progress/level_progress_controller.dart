import 'dart:async';

import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_group_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_level_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_status.dart';
import 'package:discovery_puzzle/state/game_level_progress/progress_storage_service.dart';
import 'package:get/get.dart';

class LevelProgressController extends GetxController {
  final ProgressStorageService _storageService = Get.find();

  Rx<LevelProgressSnapshot?> progressSnapshot = Rx<LevelProgressSnapshot?>(
    null,
  );

  @override
  void onInit() {
    super.onInit();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final LevelProgressSnapshot? snapshot = _storageService
        .loadProgressSnapshot();
    if (snapshot != null) {
      progressSnapshot.value = snapshot;
    } else {
      final List<LevelProgressGroupSnapshot> seededGroups =
          _buildInitialGroupsFromConfig();
      final LevelProgressSnapshot seededSnapshot = LevelProgressSnapshot(
        groups: seededGroups,
      );

      unawaited(_storageService.saveProgressSnapshot(seededSnapshot));
      progressSnapshot.value = seededSnapshot;
    }
  }

  List<LevelProgressGroupSnapshot> _buildInitialGroupsFromConfig() {
    return AppConfig.levelGroups
        .map((group) {
          final List<LevelProgressLevelSnapshot> levels = group.levels
              .map((level) {
                final LevelProgressStatus status = level.orderInGroup == 1
                    ? LevelProgressStatus.unlocked
                    : LevelProgressStatus.locked;

                return LevelProgressLevelSnapshot.fromGameLevel(
                  level: level,
                  status: status,
                );
              })
              .toList(growable: false);

          return LevelProgressGroupSnapshot.fromLevelGroup(
            group: group,
            levels: levels,
          );
        })
        .toList(growable: false);
  }
}
