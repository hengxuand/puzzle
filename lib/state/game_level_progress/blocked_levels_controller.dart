import 'package:discovery_puzzle/state/game_level_progress/level_progress_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_level_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_status.dart';
import 'package:get/get.dart';

class BlockedLevelsController extends GetxController {
  late final LevelProgressController _progressController = Get.find();

  final RxList<LevelProgressLevelSnapshot> blockedLevels =
      <LevelProgressLevelSnapshot>[].obs;
  late final Worker _progressWorker;

  int get blockedCount => blockedLevels.length;

  bool isBlocked(String levelId) {
    return blockedLevels.any((level) => level.levelId == levelId);
  }

  @override
  void onInit() {
    super.onInit();
    _progressWorker = ever<LevelProgressSnapshot?>(
      _progressController.progressSnapshot,
      _syncBlockedLevels,
    );

    _syncBlockedLevels(_progressController.progressSnapshot.value);
  }

  @override
  void onClose() {
    _progressWorker.dispose();
    super.onClose();
  }

  void _syncBlockedLevels(LevelProgressSnapshot? snapshot) {
    blockedLevels.assignAll(_deriveBlockedLevels(snapshot));
  }

  List<LevelProgressLevelSnapshot> _deriveBlockedLevels(
    LevelProgressSnapshot? snapshot,
  ) {
    if (snapshot == null) {
      return const <LevelProgressLevelSnapshot>[];
    }

    return snapshot.groups
        .expand((group) => group.levels)
        .where((level) => level.status == LevelProgressStatus.locked)
        .toList(growable: false);
  }
}
