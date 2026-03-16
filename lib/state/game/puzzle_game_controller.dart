import 'dart:ui' as ui;

import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:discovery_puzzle/service/level_progress_storage.dart';
import 'package:discovery_puzzle/service/puzzle_image_loader.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

class PuzzleGameController extends GetxController {
  static final _log = Logger('PuzzleGameController');

  late final PuzzleLogic _logic = Get.find<PuzzleLogic>();
  late final PuzzleImageLoader _imageLoader = Get.find<PuzzleImageLoader>();
  late final LevelProgressStorage _progressStorage =
      Get.find<LevelProgressStorage>();

  final Rx<PuzzleDifficulty> difficulty = AppConfig.defaultDifficulty.obs;
  final Rxn<GameLevel> selectedLevel = Rxn<GameLevel>();
  final RxList<String> unlockedLevelIds = <String>[].obs;
  final RxList<String> completedLevelIds = <String>[].obs;
  final RxnString suggestedNextLevelId = RxnString();

  final RxList<int> tiles = <int>[].obs;
  final RxBool isSolved = false.obs;
  final imageAsync = Rx<ui.Image?>(null);
  final RxnInt hoveredTargetIndex = RxnInt();
  final RxnInt activeDragAnchorIndex = RxnInt();
  final RxnInt activeDragClusterId = RxnInt();
  final RxMap<int, int> boardIndexToClusterId = <int, int>{}.obs;
  final RxMap<int, List<int>> clusterIdToBoardIndices = <int, List<int>>{}.obs;

  int get rowCount =>
      selectedLevel.value?.difficulty.rows ?? difficulty.value.rows;
  int get columnCount =>
      selectedLevel.value?.difficulty.columns ?? difficulty.value.columns;

  @override
  void onInit() {
    super.onInit();
    _log.fine('onInit called');
    _initializeLevelState();
  }

  Future<void> _initializeLevelState() async {
    final LevelProgressSnapshot snapshot = await _progressStorage.load();

    final Set<String> validLevelIds = AppConfig.levels.map((l) => l.id).toSet();
    final List<String> unlocked = _sanitizeProgressIds(
      ids: snapshot.unlockedLevelIds,
      validLevelIds: validLevelIds,
    );
    final List<String> completed = _sanitizeProgressIds(
      ids: snapshot.completedLevelIds,
      validLevelIds: validLevelIds,
    );

    if (!unlocked.contains(AppConfig.defaultLevelId)) {
      unlocked.insert(0, AppConfig.defaultLevelId);
    }

    for (final String completedId in completed) {
      if (!unlocked.contains(completedId)) {
        unlocked.add(completedId);
      }
    }

    _sortLevelIdsByOrder(unlocked);
    _sortLevelIdsByOrder(completed);

    unlockedLevelIds.assignAll(unlocked);
    completedLevelIds.assignAll(completed);

    final String preferredLevelId =
        snapshot.selectedLevelId ?? AppConfig.defaultLevelId;
    GameLevel? initialLevel = _levelById(preferredLevelId);

    if (initialLevel == null || !isLevelUnlocked(initialLevel.id)) {
      initialLevel = _firstUnlockedLevel();
    }

    if (initialLevel == null) {
      initialLevel = AppConfig.levels.first;
      unlockedLevelIds.assignAll(<String>[initialLevel.id]);
      await _progressStorage.saveUnlockedLevelIds(unlockedLevelIds.toList());
    }

    await _applyLevel(
      initialLevel,
      persistSelection: snapshot.selectedLevelId != initialLevel.id,
      reshuffle: true,
    );

    await _progressStorage.saveUnlockedLevelIds(unlockedLevelIds.toList());
    await _progressStorage.saveCompletedLevelIds(completedLevelIds.toList());
  }

  List<String> _sanitizeProgressIds({
    required List<String> ids,
    required Set<String> validLevelIds,
  }) {
    final Set<String> seen = <String>{};
    final List<String> sanitized = <String>[];

    for (final String id in ids) {
      if (!validLevelIds.contains(id)) {
        continue;
      }
      if (!seen.add(id)) {
        continue;
      }
      sanitized.add(id);
    }

    return sanitized;
  }

  void _sortLevelIdsByOrder(List<String> ids) {
    final Map<String, int> orderById = <String, int>{
      for (final GameLevel level in AppConfig.levels) level.id: level.order,
    };

    ids.sort((a, b) {
      final int orderA = orderById[a] ?? 1 << 20;
      final int orderB = orderById[b] ?? 1 << 20;
      return orderA.compareTo(orderB);
    });
  }

  List<GameLevel> get levels => AppConfig.levels;

  bool isLevelUnlocked(String levelId) => unlockedLevelIds.contains(levelId);

  bool isLevelCompleted(String levelId) => completedLevelIds.contains(levelId);

  Future<void> selectLevel(GameLevel level) async {
    if (!isLevelUnlocked(level.id)) {
      return;
    }
    await _applyLevel(level, persistSelection: true, reshuffle: true);
  }

  Future<void> _applyLevel(
    GameLevel level, {
    required bool persistSelection,
    required bool reshuffle,
  }) async {
    suggestedNextLevelId.value = null;
    selectedLevel.value = level;
    difficulty.value = level.difficulty;

    await _loadImage(level.imageAssetPath);

    if (persistSelection) {
      await _progressStorage.saveSelectedLevel(level.id);
    }

    if (reshuffle) {
      final List<int> newTiles = _logic.createShuffledTiles(
        rows: rowCount,
        columns: columnCount,
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

  void reset() {
    final List<int> newTiles = _logic.createShuffledTiles(
      rows: rowCount,
      columns: columnCount,
    );
    _setBoardState(newTiles);
    endDrag();
  }

  Future<void> setDifficulty(PuzzleDifficulty newDifficulty) async {
    if (difficulty.value == newDifficulty) return;

    GameLevel? matching;
    for (final GameLevel level in AppConfig.levels) {
      if (level.difficulty == newDifficulty && isLevelUnlocked(level.id)) {
        matching = level;
        break;
      }
    }

    if (matching != null) {
      await selectLevel(matching);
      return;
    }

    difficulty.value = newDifficulty;
    final List<int> newTiles = _logic.createShuffledTiles(
      rows: rowCount,
      columns: columnCount,
    );
    _setBoardState(newTiles);
    endDrag();
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
      _handleCurrentLevelSolved();
    }
  }

  Future<void> _handleCurrentLevelSolved() async {
    final GameLevel? level = selectedLevel.value;
    if (level == null) {
      return;
    }

    bool changed = false;

    if (!completedLevelIds.contains(level.id)) {
      completedLevelIds.add(level.id);
      changed = true;
    }

    final GameLevel? next = _nextLevel(level);
    if (next != null && !unlockedLevelIds.contains(next.id)) {
      unlockedLevelIds.add(next.id);
      _sortLevelIdsByOrder(unlockedLevelIds);
      suggestedNextLevelId.value = next.id;
      changed = true;
    }

    if (!changed) {
      return;
    }

    await _progressStorage.saveCompletedLevelIds(completedLevelIds.toList());
    await _progressStorage.saveUnlockedLevelIds(unlockedLevelIds.toList());
  }

  String? get suggestedNextLevelName {
    final String? id = suggestedNextLevelId.value;
    if (id == null) {
      return null;
    }
    return _levelById(id)?.name;
  }

  Future<void> applySuggestedLevelSelectionForMenu() async {
    final String? id = suggestedNextLevelId.value;
    if (id == null) {
      return;
    }

    final GameLevel? level = _levelById(id);
    if (level == null || !isLevelUnlocked(level.id)) {
      suggestedNextLevelId.value = null;
      return;
    }

    selectedLevel.value = level;
    difficulty.value = level.difficulty;
    suggestedNextLevelId.value = null;
    await _progressStorage.saveSelectedLevel(level.id);
  }

  Future<void> playSuggestedNextLevel() async {
    final String? id = suggestedNextLevelId.value;
    if (id == null) {
      return;
    }

    final GameLevel? level = _levelById(id);
    if (level == null || !isLevelUnlocked(level.id)) {
      suggestedNextLevelId.value = null;
      return;
    }

    await _applyLevel(
      level,
      persistSelection: true,
      reshuffle: true,
    );
  }

  GameLevel? _nextLevel(GameLevel level) {
    for (final GameLevel candidate in AppConfig.levels) {
      if (candidate.order == level.order + 1) {
        return candidate;
      }
    }
    return null;
  }

  GameLevel? _levelById(String id) {
    for (final GameLevel level in AppConfig.levels) {
      if (level.id == id) {
        return level;
      }
    }
    return null;
  }

  GameLevel? _firstUnlockedLevel() {
    for (final GameLevel level in AppConfig.levels) {
      if (unlockedLevelIds.contains(level.id)) {
        return level;
      }
    }
    return null;
  }

  void _recomputeClusters() {
    final Map<int, Set<int>> clusters = _logic.buildConnectedClusters(
      tiles: tiles,
      rows: rowCount,
      columns: columnCount,
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
