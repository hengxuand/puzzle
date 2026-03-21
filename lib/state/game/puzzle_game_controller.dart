import 'dart:async';
import 'dart:ui' as ui;

import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:puzzle/logic/puzzle_logic.dart';
import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/models/level_progress_snapshot.dart';
import 'package:puzzle/models/level_progress_status.dart';
import 'package:puzzle/models/levels.dart';
import 'package:puzzle/models/puzzle_difficulty.dart';
import 'package:puzzle/service/progress_storage_service.dart';
import 'package:puzzle/service/puzzle_image_loader.dart';

part 'puzzle_game_controller_board.dart';
part 'puzzle_game_controller_progress.dart';

class PuzzleGameController extends GetxController {
  static final _log = Logger('PuzzleGameController');

  late final PuzzleLogic _logic = Get.find<PuzzleLogic>();
  late final PuzzleImageLoader _imageLoader = Get.find<PuzzleImageLoader>();
  late final ProgressStorageService _storageService =
      Get.find<ProgressStorageService>();

  final RxBool isInitialized = false.obs;
  final progressSnapshot = Rx<LevelProgressSnapshot?>(null);
  final selectedGroupId = RxnInt();
  final Rxn<GameLevel> selectedLevel = Rxn<GameLevel>();

  final RxList<int> tiles = <int>[].obs;
  final imageAsync = Rx<ui.Image?>(null);
  final RxnInt hoveredTargetIndex = RxnInt();
  final RxnInt activeDragAnchorIndex = RxnInt();
  final RxnInt activeDragClusterId = RxnInt();
  final RxMap<int, int> boardIndexToClusterId = <int, int>{}.obs;
  final RxMap<int, List<int>> clusterIdToBoardIndices = <int, List<int>>{}.obs;

  int get rowCount =>
      selectedLevel.value?.difficulty.rows ?? PuzzleDifficulty.easiest.rows;
  int get columnCount =>
      selectedLevel.value?.difficulty.columns ??
      PuzzleDifficulty.easiest.columns;

  @override
  void onInit() {
    super.onInit();
    _log.fine('onInit called');
    isInitialized.value = false;
    _initializeLevelState();
  }

  Future<void> _initializeLevelState() async {
    await loadProgress();
    await loadSelectedLevel();
    isInitialized.value = true;
  }
}
