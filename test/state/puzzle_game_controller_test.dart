import 'dart:ui' as ui;

import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:discovery_puzzle/service/level_progress_storage.dart';
import 'package:discovery_puzzle/service/puzzle_image_loader.dart';
import 'package:discovery_puzzle/state/game/puzzle_game_controller.dart';
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

class _FakeLevelProgressStorage extends LevelProgressStorage {
  const _FakeLevelProgressStorage();

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
    return LevelProgressSnapshot(
      selectedLevelId: selectedLevelId,
      unlockedLevelIds: List<String>.from(unlockedLevelIds),
      completedLevelIds: List<String>.from(completedLevelIds),
    );
  }

  @override
  Future<void> saveSelectedLevel(String levelId) async {
    selectedLevelId = levelId;
  }

  @override
  Future<void> saveUnlockedLevelIds(List<String> ids) async {
    unlockedLevelIds = List<String>.from(ids);
  }

  @override
  Future<void> saveCompletedLevelIds(List<String> ids) async {
    completedLevelIds = List<String>.from(ids);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PuzzleGameController controller;

  setUp(() async {
    Get.testMode = true;
    Get.reset();
    _FakeLevelProgressStorage.resetStore();

    Get.put(PuzzleLogic(), permanent: true);
    Get.put<LevelProgressStorage>(
      const _FakeLevelProgressStorage(),
      permanent: true,
    );
    Get.put<PuzzleImageLoader>(const _FakePuzzleImageLoader(), permanent: true);
    controller = Get.put(PuzzleGameController(), permanent: true);

    for (int i = 0; i < 10; i++) {
      if (controller.selectedLevel.value != null) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  });

  tearDown(() {
    Get.reset();
  });

  test('canAcceptClusterDrop rejects out-of-bounds translation', () {
    controller.difficulty.value = controller.difficulty.value;
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
    controller.tiles.assignAll(List<int>.generate(24, (i) => i));
    controller.clusterIdToBoardIndices.assignAll(<int, List<int>>{
      9: <int>[0, 4],
    });

    controller.moveClusterFromDrag(
      clusterId: 9,
      fromAnchorIndex: 0,
      toAnchorIndex: 4,
    );

    expect(controller.tiles[4], 0);
    expect(controller.tiles[8], 4);
    expect(controller.tiles[0], 8);
  });

  test('moveClusterFromDrag handles overlapping right shift', () {
    controller.tiles.assignAll(List<int>.generate(24, (i) => i));
    controller.clusterIdToBoardIndices.assignAll(<int, List<int>>{
      10: <int>[0, 1],
    });

    controller.moveClusterFromDrag(
      clusterId: 10,
      fromAnchorIndex: 0,
      toAnchorIndex: 1,
    );

    expect(controller.tiles[1], 0);
    expect(controller.tiles[2], 1);
    expect(controller.tiles[0], 2);
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
    expect(controller.isLevelUnlocked('level_2'), isTrue);
    expect(controller.suggestedNextLevelId.value, 'level_2');
  });

  test(
    'applySuggestedLevelSelectionForMenu selects unlocked next level',
    () async {
      final List<int> almostSolved = List<int>.generate(24, (i) => i);
      almostSolved[0] = 1;
      almostSolved[1] = 0;
      controller.tiles.assignAll(almostSolved);
      controller.swapTiles(0, 1);

      await Future<void>.delayed(const Duration(milliseconds: 1));
      await controller.applySuggestedLevelSelectionForMenu();

      expect(controller.selectedLevel.value?.id, 'level_2');
      expect(controller.suggestedNextLevelId.value, isNull);
    },
  );

  test('playSuggestedNextLevel starts the next level immediately', () async {
    final List<int> almostSolved = List<int>.generate(24, (i) => i);
    almostSolved[0] = 1;
    almostSolved[1] = 0;
    controller.tiles.assignAll(almostSolved);
    controller.swapTiles(0, 1);

    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(controller.suggestedNextLevelId.value, 'level_2');
    await controller.playSuggestedNextLevel();

    expect(controller.selectedLevel.value?.id, 'level_2');
    expect(controller.suggestedNextLevelId.value, isNull);
    expect(controller.isSolved.value, isFalse);
  });

  test('sanitizes persisted level progress against catalog changes', () async {
    Get.reset();
    _FakeLevelProgressStorage.resetStore();
    _FakeLevelProgressStorage.selectedLevelId = 'removed_level';
    _FakeLevelProgressStorage.unlockedLevelIds = <String>[
      'level_1',
      'level_1',
      'removed_level',
    ];
    _FakeLevelProgressStorage.completedLevelIds = <String>[
      'level_2',
      'removed_level',
      'level_2',
    ];

    Get.put(PuzzleLogic(), permanent: true);
    Get.put<LevelProgressStorage>(
      const _FakeLevelProgressStorage(),
      permanent: true,
    );
    Get.put<PuzzleImageLoader>(const _FakePuzzleImageLoader(), permanent: true);
    final PuzzleGameController sanitizedController = Get.put(
      PuzzleGameController(),
      permanent: true,
    );

    for (int i = 0; i < 10; i++) {
      if (sanitizedController.selectedLevel.value != null) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    expect(
      sanitizedController.unlockedLevelIds,
      containsAll(<String>['level_1', 'level_2']),
    );
    expect(
      sanitizedController.unlockedLevelIds
          .where((id) => id == 'level_1')
          .length,
      1,
    );
    expect(
      sanitizedController.unlockedLevelIds.contains('removed_level'),
      isFalse,
    );
    expect(sanitizedController.selectedLevel.value?.id, 'level_1');
  });
}
