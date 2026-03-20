import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_progress_snapshot.dart';
import 'package:puzzle/models/level_progress_status.dart';
import 'package:puzzle/state/game_level_progress/game_level_controller.dart';
import 'package:get/get.dart';

class LevelStatusController extends GetxController {
  late final GameLevelController _progressController = Get.find();

  final RxMap<LevelProgressStatus, Map<int, GameLevel>> _levelsByStatus =
      <LevelProgressStatus, Map<int, GameLevel>>{
        LevelProgressStatus.locked: <int, GameLevel>{},
        LevelProgressStatus.unlocked: <int, GameLevel>{},
        LevelProgressStatus.completed: <int, GameLevel>{},
      }.obs;

  late final Worker _progressWorker;

  Map<int, GameLevel> levelsForStatus(LevelProgressStatus status) {
    return _levelsByStatus[status] ?? const <int, GameLevel>{};
  }

  int countForStatus(LevelProgressStatus status) {
    return levelsForStatus(status).length;
  }

  bool hasStatus(int levelId, LevelProgressStatus status) {
    return levelsForStatus(status).containsKey(levelId);
  }

  bool isLocked(int levelId) {
    return hasStatus(levelId, LevelProgressStatus.locked);
  }

  bool isUnlocked(int levelId) {
    return hasStatus(levelId, LevelProgressStatus.unlocked);
  }

  bool isCompleted(int levelId) {
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
    final Map<LevelProgressStatus, Map<int, GameLevel>> next =
        <LevelProgressStatus, Map<int, GameLevel>>{
          LevelProgressStatus.locked: <int, GameLevel>{},
          LevelProgressStatus.unlocked: <int, GameLevel>{},
          LevelProgressStatus.completed: <int, GameLevel>{},
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
