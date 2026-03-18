import 'package:discovery_puzzle/models/game_level.dart';
import 'package:discovery_puzzle/models/level_progress_snapshot.dart';
import 'package:discovery_puzzle/models/level_progress_status.dart';
import 'package:discovery_puzzle/state/game_level_progress/game_level_controller.dart';
import 'package:get/get.dart';

class LevelStatusController extends GetxController {
  late final GameLevelController _progressController = Get.find();

  final RxMap<LevelProgressStatus, Map<String, GameLevel>> _levelsByStatus =
      <LevelProgressStatus, Map<String, GameLevel>>{
        LevelProgressStatus.locked: <String, GameLevel>{},
        LevelProgressStatus.unlocked: <String, GameLevel>{},
        LevelProgressStatus.completed: <String, GameLevel>{},
      }.obs;

  late final Worker _progressWorker;

  Map<String, GameLevel> levelsForStatus(LevelProgressStatus status) {
    return _levelsByStatus[status] ?? const <String, GameLevel>{};
  }

  int countForStatus(LevelProgressStatus status) {
    return levelsForStatus(status).length;
  }

  bool hasStatus(String levelId, LevelProgressStatus status) {
    return levelsForStatus(status).containsKey(levelId);
  }

  bool isLocked(String levelId) {
    return hasStatus(levelId, LevelProgressStatus.locked);
  }

  bool isUnlocked(String levelId) {
    return hasStatus(levelId, LevelProgressStatus.unlocked);
  }

  bool isCompleted(String levelId) {
    return hasStatus(levelId, LevelProgressStatus.completed);
  }

  @override
  void onInit() {
    super.onInit();
    _progressWorker = ever<LevelProgressSnapshot?>(
      _progressController.progressSnapshot,
      _syncLevelsByStatus,
    );

    _syncLevelsByStatus(_progressController.progressSnapshot.value);
  }

  @override
  void onClose() {
    _progressWorker.dispose();
    super.onClose();
  }

  void _syncLevelsByStatus(LevelProgressSnapshot? snapshot) {
    final Map<LevelProgressStatus, Map<String, GameLevel>> next =
        <LevelProgressStatus, Map<String, GameLevel>>{
          LevelProgressStatus.locked: <String, GameLevel>{},
          LevelProgressStatus.unlocked: <String, GameLevel>{},
          LevelProgressStatus.completed: <String, GameLevel>{},
        };

    if (snapshot != null) {
      for (final GameLevel level in snapshot.groups.values.expand(
        (group) => group.levels.values,
      )) {
        next[level.status]![level.id] = level;
      }
    }

    _levelsByStatus
      ..clear()
      ..addAll(next);
  }
}
