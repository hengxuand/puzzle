import 'dart:ui' as ui;

import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:discovery_puzzle/models/game_level.dart';
import 'package:discovery_puzzle/models/puzzle_difficulty.dart';
import 'package:discovery_puzzle/service/puzzle_image_loader.dart';
import 'package:discovery_puzzle/state/game_level_progress/game_level_controller.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

class PuzzleGameController extends GetxController {
  static final _log = Logger('PuzzleGameController');

  late final PuzzleLogic _logic = Get.find<PuzzleLogic>();
  late final PuzzleImageLoader _imageLoader = Get.find<PuzzleImageLoader>();
  late final GameLevelController _gameLevelController =
      Get.find<GameLevelController>();

  final RxBool isInitialized = false.obs;
  final Rxn<GameLevel> selectedLevel = Rxn<GameLevel>();

  final RxList<int> tiles = <int>[].obs;
  final RxBool isSolved = false.obs;
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
    await _gameLevelController.loadProgress();
    isInitialized.value = true;
  }

  Future<void> openLevel(GameLevel level) async {
    _log.fine('Selecting level: ${level.id}');

    await _applyLevel(level, reshuffle: true);
  }

  Future<void> _applyLevel(GameLevel level, {required bool reshuffle}) async {
    selectedLevel.value = level;

    await _loadImage(level.imageAssetPath);

    if (reshuffle) {
      final List<int> newTiles = _logic.createShuffledTiles(
        rows: level.difficulty.rows,
        columns: level.difficulty.columns,
      );
      _setBoardState(newTiles);
      endDrag();
    }
  }

  Future<void> _loadImage(String assetPath) async {
    _log.fine('Loading image from asset: $assetPath');
    imageAsync.value = await _imageLoader.loadFromAsset(assetPath);
  }

  void swapTiles(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    _log.fine('Swapped tiles: $fromIndex and $toIndex');

    final List<int> updatedTiles = [...tiles];
    _logic.swapTiles(updatedTiles, fromIndex, toIndex);
    _setBoardState(updatedTiles);
  }

  int clusterIdForBoardIndex(int boardIndex) {
    return boardIndexToClusterId[boardIndex] ?? -1;
  }

  List<int> clusterMembersForId(int clusterId) {
    return clusterIdToBoardIndices[clusterId] ?? const <int>[];
  }

  bool isBoardIndexInActiveDragCluster(int boardIndex) {
    final int? clusterId = activeDragClusterId.value;
    if (clusterId == null) {
      return false;
    }
    final List<int> members = clusterMembersForId(clusterId);
    return members.contains(boardIndex);
  }

  bool canAcceptClusterDrop({
    required int clusterId,
    required int fromAnchorIndex,
    required int toAnchorIndex,
  }) {
    if (fromAnchorIndex == toAnchorIndex) {
      return false;
    }

    final List<int> members = clusterMembersForId(clusterId);
    if (members.isEmpty || !members.contains(fromAnchorIndex)) {
      return false;
    }

    final Map<int, int>? translation = _buildTranslationMap(
      members: members,
      fromAnchorIndex: fromAnchorIndex,
      toAnchorIndex: toAnchorIndex,
    );

    return translation != null;
  }

  void setHoveredTarget(int? boardIndex) {
    hoveredTargetIndex.value = boardIndex;
  }

  void startDrag(int fromIndex) {
    activeDragAnchorIndex.value = fromIndex;
    activeDragClusterId.value = clusterIdForBoardIndex(fromIndex);
    hoveredTargetIndex.value = null;
  }

  void endDrag() {
    activeDragAnchorIndex.value = null;
    activeDragClusterId.value = null;
    hoveredTargetIndex.value = null;
  }

  void swapFromDrag({required int fromIndex, required int toIndex}) {
    endDrag();
    swapTiles(fromIndex, toIndex);
  }

  void moveClusterFromDrag({
    required int clusterId,
    required int fromAnchorIndex,
    required int toAnchorIndex,
  }) {
    final List<int> members = clusterMembersForId(clusterId);
    final Map<int, int>? translation = _buildTranslationMap(
      members: members,
      fromAnchorIndex: fromAnchorIndex,
      toAnchorIndex: toAnchorIndex,
    );

    endDrag();
    if (translation == null) {
      return;
    }

    final List<int> oldTiles = [...tiles];
    final List<int> newTiles = [...oldTiles];
    final Set<int> sourceSet = members.toSet();
    final Set<int> destinationSet = translation.values.toSet();

    final int fromRow = fromAnchorIndex ~/ columnCount;
    final int fromCol = fromAnchorIndex % columnCount;
    final int toRow = toAnchorIndex ~/ columnCount;
    final int toCol = toAnchorIndex % columnCount;
    final int rowDelta = toRow - fromRow;
    final int colDelta = toCol - fromCol;
    final int indexDelta = rowDelta * columnCount + colDelta;

    for (final int sourceIndex in members) {
      final int destinationIndex = translation[sourceIndex]!;
      newTiles[destinationIndex] = oldTiles[sourceIndex];
    }

    final Set<int> sourceOnly = sourceSet.difference(destinationSet);
    final Set<int> destinationOnly = destinationSet.difference(sourceSet);
    final Set<int> overlap = sourceSet.intersection(destinationSet);

    for (final int sourceIndex in sourceOnly) {
      int donorIndex = sourceIndex;

      while (true) {
        donorIndex += indexDelta;

        if (destinationOnly.contains(donorIndex)) {
          newTiles[sourceIndex] = oldTiles[donorIndex];
          break;
        }

        if (overlap.contains(donorIndex)) {
          continue;
        }

        newTiles[sourceIndex] = oldTiles[sourceIndex];
        break;
      }
    }

    _setBoardState(newTiles);
  }

  void _setBoardState(List<int> newTiles) {
    final bool wasSolved = isSolved.value;

    tiles.assignAll(newTiles);
    isSolved.value = _logic.isSolved(tiles);
    _recomputeClusters();

    if (!wasSolved && isSolved.value) {
      _log.fine('Current level solved: ${selectedLevel.value?.id ?? 'none'}');
      _gameLevelController.markLevelCompleted(selectedLevel.value);
    }
  }

  Future<void> resetLevelProgress() async {
    await _gameLevelController.resetProgress();

    tiles.clear();
    isSolved.value = false;
    imageAsync.value = null;
    endDrag();
  }

  void _recomputeClusters() {
    final Map<int, Set<int>> clusters = _logic.buildConnectedClusters(
      tiles: tiles,
      rows:
          selectedLevel.value?.difficulty.rows ?? PuzzleDifficulty.easiest.rows,
      columns:
          selectedLevel.value?.difficulty.columns ??
          PuzzleDifficulty.easiest.columns,
    );

    final Map<int, int> clusterLookup = <int, int>{};
    final Map<int, List<int>> clusterMembers = <int, List<int>>{};

    for (final MapEntry<int, Set<int>> entry in clusters.entries) {
      final List<int> sortedMembers = entry.value.toList()..sort();
      clusterMembers[entry.key] = sortedMembers;
      for (final int boardIndex in sortedMembers) {
        clusterLookup[boardIndex] = entry.key;
      }
    }

    boardIndexToClusterId.assignAll(clusterLookup);
    clusterIdToBoardIndices.assignAll(clusterMembers);
  }

  Map<int, int>? _buildTranslationMap({
    required List<int> members,
    required int fromAnchorIndex,
    required int toAnchorIndex,
  }) {
    final int fromRow = fromAnchorIndex ~/ columnCount;
    final int fromCol = fromAnchorIndex % columnCount;
    final int toRow = toAnchorIndex ~/ columnCount;
    final int toCol = toAnchorIndex % columnCount;
    final int rowDelta = toRow - fromRow;
    final int colDelta = toCol - fromCol;
    final Map<int, int> translation = <int, int>{};

    for (final int sourceIndex in members) {
      final int sourceRow = sourceIndex ~/ columnCount;
      final int sourceCol = sourceIndex % columnCount;
      final int destinationRow = sourceRow + rowDelta;
      final int destinationCol = sourceCol + colDelta;

      if (destinationRow < 0 ||
          destinationRow >= rowCount ||
          destinationCol < 0 ||
          destinationCol >= columnCount) {
        return null;
      }

      translation[sourceIndex] = destinationRow * columnCount + destinationCol;
    }

    return translation;
  }
}
