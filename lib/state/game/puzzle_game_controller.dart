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

  Future<LevelProgressSnapshot> loadProgress() async {
    final LevelProgressSnapshot? snapshot = _storageService
        .loadProgressSnapshot();
    if (snapshot != null) {
      _log.info('Loaded progress snapshot from storage.');
      progressSnapshot.value = snapshot;
      return snapshot;
    }

    final Map<int, LevelGroup> seededGroups = _buildInitialGroupsFromConfig();
    final LevelProgressSnapshot seededSnapshot = LevelProgressSnapshot(
      groups: seededGroups,
    );

    unawaited(_storageService.saveProgressSnapshot(seededSnapshot));
    _log.info('Initialized progress snapshot with seeded data.');
    progressSnapshot.value = seededSnapshot;
    return seededSnapshot;
  }

  Future<GameLevel?> loadSelectedLevel() async {
    if (progressSnapshot.value == null) {
      await loadProgress();
    }

    final GameLevel? level = _storageService.loadSelectedLevel();
    if (level == null) {
      _log.warning('No previously selected level found in storage.');
      _selectDefaultLevelForGroup(Levels.defaultLevel.groupId);
      _log.info('Initialized selected level with default group.');
      return selectedLevel.value;
    }

    selectLevel(level);
    return selectedLevel.value;
  }

  Future<void> resetProgress() async {
    await _storageService.clearProgressSnapshot();
    await loadProgress();
  }

  void selectGroup(int groupId) {
    selectedGroupId.value = groupId;
    if (selectedLevel.value?.groupId != groupId) {
      _selectDefaultLevelForGroup(groupId);
    }
  }

  void selectLevel(GameLevel level) {
    final GameLevel canonical = _findLevelById(level.id) ?? level;
    selectedLevel.value = canonical;
    selectedGroupId.value = canonical.groupId;
    unawaited(_storageService.saveSelectedLevel(canonical));
  }

  void clearSelection() {
    final LevelProgressSnapshot? snapshot = progressSnapshot.value;
    if (snapshot == null || snapshot.groups.isEmpty) {
      selectedGroupId.value = null;
      selectedLevel.value = null;
      return;
    }

    final List<int> groupIds = snapshot.groups.keys.toList()..sort();
    selectedGroupId.value = groupIds.first;
    _selectDefaultLevelForGroup(groupIds.first);
  }

  bool hasStatus(int levelId, LevelProgressStatus status) {
    final GameLevel? level = _findLevelById(levelId);
    return level?.status == status;
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

  Future<void> markLevelCompleted(GameLevel? level) async {
    final LevelProgressSnapshot? snapshot = progressSnapshot.value;
    if (snapshot == null || level == null) {
      _log.warning(
        'Cannot mark level completed: snapshot or level is missing.',
      );
      return;
    }

    final Map<int, LevelGroup> currentGroups = snapshot.groups;
    bool didUpdate = false;
    final Map<int, LevelGroup> updatedGroups = <int, LevelGroup>{};

    for (final int groupId in currentGroups.keys) {
      final LevelGroup group = currentGroups[groupId]!;
      if (group.levels.containsKey(level.id)) {
        _log.fine(
          'Found level ${level.id} in group $groupId, marking as completed.',
        );
        didUpdate = true;

        final Map<int, GameLevel> levels = Map<int, GameLevel>.from(
          group.levels,
        );

        final GameLevel levelToUpdate = levels[level.id]!;
        levels[level.id] = levelToUpdate.copyWith(
          status: LevelProgressStatus.completed,
        );

        final int nextLevelId = level.id + 1;
        final GameLevel? nextLevel = levels[nextLevelId];

        if (nextLevel != null &&
            nextLevel.status == LevelProgressStatus.locked) {
          _log.fine('Unlocking next level $nextLevelId in group $groupId.');
          levels[nextLevel.id] = nextLevel.copyWith(
            status: LevelProgressStatus.unlocked,
          );
        }

        updatedGroups[groupId] = LevelGroup(
          id: group.id,
          name: group.name,
          description: group.description,
          order: group.order,
          levels: levels,
        );
      } else {
        updatedGroups[groupId] = group;
      }
    }

    if (!didUpdate) {
      _log.warning('Cannot mark level completed: level ${level.id} not found.');
      return;
    }

    final LevelProgressSnapshot updatedSnapshot = LevelProgressSnapshot(
      groups: updatedGroups,
    );

    progressSnapshot.value = updatedSnapshot;
    await _storageService.saveProgressSnapshot(updatedSnapshot);

    if (selectedLevel.value != null) {
      final GameLevel? refreshedActiveLevel = _findLevelById(
        selectedLevel.value!.id,
      );
      if (refreshedActiveLevel != null) {
        selectedLevel.value = refreshedActiveLevel;
      }
    }
  }

  Future<void> openLevel(GameLevel level, {bool reshuffle = true}) async {
    _log.fine('Selecting level: ${level.id}');

    selectLevel(level);

    await _applyLevel(level, reshuffle: reshuffle);
  }

  Future<void> _applyLevel(GameLevel level, {required bool reshuffle}) async {
    selectedLevel.value = _findLevelById(level.id) ?? level;

    await _loadImage(level.imageAssetPath);

    if (reshuffle) {
      final List<int> newTiles = _logic.createShuffledTiles(
        rows: level.difficulty.rows,
        columns: level.difficulty.columns,
      );
      _setBoardState(newTiles);
      endDrag();
    } else {
      final int tileCount = level.difficulty.rows * level.difficulty.columns;
      final List<int> solvedTiles = List<int>.generate(tileCount, (i) => i);
      _setBoardState(solvedTiles);
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
    // final bool wasSolved = isSolved.value;

    _log.fine(
      'Selected level status before setboardstate = ${selectedLevel.value?.status}',
    );
    final bool wasSolved =
        selectedLevel.value!.status == LevelProgressStatus.completed;

    tiles.assignAll(newTiles);

    final bool isSolved = _logic.isSolved(tiles);

    selectedLevel.value!.status = isSolved
        ? LevelProgressStatus.completed
        : LevelProgressStatus.unlocked;

    _recomputeClusters();

    _log.info(
      'Board state updated. isSolved: $isSolved, level status: ${selectedLevel.value?.status}',
    );

    if (!wasSolved && isSolved) {
      _log.fine(
        'Current level ${selectedLevel.value?.id ?? 'none'} wasn\'t solved and is now solved.',
      );
      unawaited(markLevelCompleted(selectedLevel.value));
    }
  }

  Future<void> resetLevelProgress() async {
    await resetProgress();
    clearSelection();

    tiles.clear();
    imageAsync.value = null;
    selectedLevel.value = null;
    endDrag();
  }

  Map<int, LevelGroup> _buildInitialGroupsFromConfig() {
    return Map<int, LevelGroup>.fromEntries(
      Levels.levelGroups.map((group) {
        final List<int> sortedIds = group.levels.keys.toList()..sort();
        final int? firstLevelId = sortedIds.isEmpty ? null : sortedIds.first;

        final Map<int, GameLevel> levels = group.levels.map((id, level) {
          final LevelProgressStatus status = id == firstLevelId
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

  void _selectDefaultLevelForGroup(int groupId) {
    final LevelGroup? group = progressSnapshot.value?.groups[groupId];
    if (group == null || group.levels.isEmpty) {
      selectedLevel.value = null;
      return;
    }

    final List<GameLevel> levels = group.levels.values.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));

    GameLevel? firstUnlockedNonCompleted;
    bool allCompleted = true;

    for (final GameLevel level in levels) {
      if (level.status == LevelProgressStatus.unlocked &&
          firstUnlockedNonCompleted == null) {
        firstUnlockedNonCompleted = level;
      }

      if (level.status != LevelProgressStatus.completed) {
        allCompleted = false;
      }
    }

    if (firstUnlockedNonCompleted != null) {
      selectLevel(firstUnlockedNonCompleted);
      return;
    }

    if (allCompleted) {
      selectLevel(levels.first);
      return;
    }

    selectLevel(levels.first);
  }

  GameLevel? _findLevelById(int levelId) {
    final LevelProgressSnapshot? snapshot = progressSnapshot.value;
    if (snapshot == null) {
      return null;
    }

    for (final LevelGroup group in snapshot.groups.values) {
      final GameLevel? level = group.levels[levelId];
      if (level != null) {
        return level;
      }
    }

    return null;
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
