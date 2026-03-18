import 'dart:ui' as ui;

import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:discovery_puzzle/service/puzzle_image_loader.dart';
import 'package:discovery_puzzle/state/game/puzzle_game_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakePuzzleImageLoader extends PuzzleImageLoader {
  const _FakePuzzleImageLoader();

  @override
  Future<ui.Image> loadFromAsset(String assetPath) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final ui.Paint paint = ui.Paint()..color = const ui.Color(0xFFCCCCCC);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 4, 4), paint);
    return recorder.endRecording().toImage(4, 4);
  }
}

class _FakeLevelProgressController extends LevelProgressController {
  _FakeLevelProgressController();

  static String? selectedLevelId;
  static List<String> unlockedLevelIds = <String>[];
  static List<String> completedLevelIds = <String>[];

  static void resetStore() {
    selectedLevelId = null;
    unlockedLevelIds = <String>[];
    completedLevelIds = <String>[];
  }

  @override
  Future<LevelProgressSnapshot> load() async {
    final Map<String, LevelProgressStatus> statuses =
        <String, LevelProgressStatus>{};
    for (final String id in unlockedLevelIds) {
      statuses[id] = LevelProgressStatus.unlocked;
    }
    for (final String id in completedLevelIds) {
      statuses[id] = LevelProgressStatus.completed;
    }

    return LevelProgressSnapshot.fromLevelStatuses(
      selectedLevelId: selectedLevelId,
      statusByLevelId: statuses,
    );
  }

  @override
  Future<void> saveSnapshot(LevelProgressSnapshot snapshot) async {
    selectedLevelId = snapshot.selectedLevelId;
    unlockedLevelIds = List<String>.from(snapshot.unlockedLevelIds);
    completedLevelIds = List<String>.from(snapshot.completedLevelIds);
  }

  @override
  Future<void> saveSelectedLevel(String levelId) async {
    final LevelProgressSnapshot current = await load();
    await saveSnapshot(
      LevelProgressSnapshot.fromLevelStatuses(
        selectedLevelId: levelId,
        statusByLevelId: current.levelStatusById,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PuzzleGameController controller;

  setUp(() async {
    Get.testMode = true;
    Get.reset();
    _FakeLevelProgressController.resetStore();

    Get.put(PuzzleLogic(), permanent: true);
    Get.put<LevelProgressController>(
      _FakeLevelProgressController(),
      permanent: true,
    );
    Get.put<PuzzleImageLoader>(const _FakePuzzleImageLoader(), permanent: true);
    controller = Get.put(PuzzleGameController(), permanent: true);

    for (int i = 0; i < 100; i++) {
      if (controller.isInitialized.value &&
          controller.selectedLevel.value != null &&
          controller.imageAsync.value != null &&
          controller.tiles.isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  });

  tearDown(() {
    Get.reset();
  });

  test('canAcceptClusterDrop rejects out-of-bounds translation', () {
    controller.tiles.assignAll(List<int>.generate(24, (i) => i));
    controller.clusterIdToBoardIndices.assignAll(<int, List<int>>{
      7: <int>[0, 1],
    });

    final bool canAccept = controller.canAcceptClusterDrop(
      clusterId: 7,
      fromAnchorIndex: 0,
      toAnchorIndex: 23,
    );

    expect(canAccept, isFalse);
  });

  test('moveClusterFromDrag translates cluster and swaps occupants', () {
    controller.tiles.assignAll(List<int>.generate(24, (i) => i));
    controller.clusterIdToBoardIndices.assignAll(<int, List<int>>{
      7: <int>[0, 1],
    });

    controller.moveClusterFromDrag(
      clusterId: 7,
      fromAnchorIndex: 0,
      toAnchorIndex: 4,
    );

    expect(controller.tiles[4], 0);
    expect(controller.tiles[5], 1);
    expect(controller.tiles[0], 4);
    expect(controller.tiles[1], 5);
  });

  test('moveClusterFromDrag handles overlapping downward shift', () {
    final int total = controller.rowCount * controller.columnCount;
    final int below = controller.columnCount;
    final int twoBelow = controller.columnCount * 2;

    controller.tiles.assignAll(List<int>.generate(total, (i) => i));
    controller.clusterIdToBoardIndices.assignAll(<int, List<int>>{
      9: <int>[0, below],
    });

    controller.moveClusterFromDrag(
      clusterId: 9,
      fromAnchorIndex: 0,
      toAnchorIndex: below,
    );

    expect(controller.tiles[below], 0);
    expect(controller.tiles[twoBelow], below);
    expect(controller.tiles[0], twoBelow);
  });

  test('moveClusterFromDrag handles overlapping shift', () {
    final int total = controller.rowCount * controller.columnCount;

    controller.tiles.assignAll(List<int>.generate(total, (i) => i));

    if (controller.columnCount >= 3) {
      controller.clusterIdToBoardIndices.assignAll(<int, List<int>>{
        10: <int>[0, 1],
      });

      expect(
        controller.canAcceptClusterDrop(
          clusterId: 10,
          fromAnchorIndex: 0,
          toAnchorIndex: 1,
        ),
        isTrue,
      );

      controller.moveClusterFromDrag(
        clusterId: 10,
        fromAnchorIndex: 0,
        toAnchorIndex: 1,
      );

      expect(controller.tiles[1], 0);
      expect(controller.tiles[2], 1);
      expect(controller.tiles[0], 2);
      return;
    }

    final int below = controller.columnCount;
    final int twoBelow = controller.columnCount * 2;

    controller.clusterIdToBoardIndices.assignAll(<int, List<int>>{
      10: <int>[1, 1 + below],
    });

    expect(
      controller.canAcceptClusterDrop(
        clusterId: 10,
        fromAnchorIndex: 1,
        toAnchorIndex: 1 + below,
      ),
      isTrue,
    );

    controller.moveClusterFromDrag(
      clusterId: 10,
      fromAnchorIndex: 1,
      toAnchorIndex: 1 + below,
    );

    expect(controller.tiles[1 + below], 1);
    expect(controller.tiles[1 + twoBelow], 1 + below);
    expect(controller.tiles[1], 1 + twoBelow);
  });

  test('startDrag and endDrag update drag state', () {
    controller.boardIndexToClusterId.assignAll(<int, int>{0: 12, 1: 12});

    controller.startDrag(0);

    expect(controller.activeDragAnchorIndex.value, 0);
    expect(controller.activeDragClusterId.value, 12);

    controller.setHoveredTarget(5);
    expect(controller.hoveredTargetIndex.value, 5);

    controller.endDrag();

    expect(controller.activeDragAnchorIndex.value, isNull);
    expect(controller.activeDragClusterId.value, isNull);
    expect(controller.hoveredTargetIndex.value, isNull);
  });

  test('initializes with default unlocked level', () {
    expect(controller.selectedLevel.value?.id, AppConfig.defaultLevelId);
    expect(controller.isLevelUnlocked(AppConfig.defaultLevelId), isTrue);
  });

  test('solving a level unlocks the next level', () async {
    final List<int> almostSolved = List<int>.generate(24, (i) => i);
    almostSolved[0] = 1;
    almostSolved[1] = 0;
    controller.tiles.assignAll(almostSolved);

    controller.swapTiles(0, 1);

    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(controller.isSolved.value, isTrue);
    expect(controller.isLevelCompleted(AppConfig.defaultLevelId), isTrue);
    expect(controller.isLevelUnlocked('guanyu_2'), isTrue);
  });

  test('resetLevelProgress restores default unlock state', () async {
    final int total = controller.rowCount * controller.columnCount;
    final List<int> almostSolved = List<int>.generate(total, (i) => i);
    almostSolved[0] = 1;
    almostSolved[1] = 0;
    controller.tiles.assignAll(almostSolved);

    controller.swapTiles(0, 1);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(controller.isLevelCompleted(AppConfig.defaultLevelId), isTrue);

    await controller.resetLevelProgress();

    expect(controller.selectedLevel.value?.id, AppConfig.defaultLevelId);
    expect(controller.completedLevelIds, isEmpty);
    expect(controller.unlockedLevelIds, <String>[
      for (final LevelGroup group in AppConfig.levelGroups)
        if (group.levels.isNotEmpty) group.levels.first.id,
    ]);

    expect(
      _FakeLevelProgressController.selectedLevelId,
      AppConfig.defaultLevelId,
    );
    expect(_FakeLevelProgressController.unlockedLevelIds, <String>[
      for (final LevelGroup group in AppConfig.levelGroups)
        if (group.levels.isNotEmpty) group.levels.first.id,
    ]);
    expect(_FakeLevelProgressController.completedLevelIds, isEmpty);
  });

  test('sanitizes persisted level progress against catalog changes', () async {
    Get.reset();
    _FakeLevelProgressController.resetStore();
    _FakeLevelProgressController.selectedLevelId = 'removed_level';
    _FakeLevelProgressController.unlockedLevelIds = <String>[
      'guanyu_1',
      'guanyu_1',
      'removed_level',
    ];
    _FakeLevelProgressController.completedLevelIds = <String>[
      'guanyu_2',
      'removed_level',
      'guanyu_2',
    ];

    Get.put(PuzzleLogic(), permanent: true);
    Get.put<LevelProgressController>(
      _FakeLevelProgressController(),
      permanent: true,
    );
    Get.put<PuzzleImageLoader>(const _FakePuzzleImageLoader(), permanent: true);
    final PuzzleGameController sanitizedController = Get.put(
      PuzzleGameController(),
      permanent: true,
    );

    for (int i = 0; i < 100; i++) {
      if (sanitizedController.isInitialized.value &&
          sanitizedController.selectedLevel.value != null &&
          sanitizedController.imageAsync.value != null &&
          sanitizedController.tiles.isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    expect(
      sanitizedController.unlockedLevelIds,
      containsAll(<String>['guanyu_1', 'guanyu_2']),
    );
    expect(
      sanitizedController.unlockedLevelIds
          .where((id) => id == 'guanyu_1')
          .length,
      1,
    );
    expect(
      sanitizedController.unlockedLevelIds.contains('removed_level'),
      isFalse,
    );
    expect(sanitizedController.selectedLevel.value?.id, 'guanyu_1');
  });
}
