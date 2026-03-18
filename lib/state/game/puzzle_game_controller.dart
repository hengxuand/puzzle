import 'dart:ui' as ui;

import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:discovery_puzzle/service/puzzle_image_loader.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_status.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

class PuzzleGameController extends GetxController {
  static final _log = Logger('PuzzleGameController');

  late final PuzzleLogic _logic = Get.find<PuzzleLogic>();
  late final PuzzleImageLoader _imageLoader = Get.find<PuzzleImageLoader>();
  late final LevelProgressController _progressStorage =
      Get.find<LevelProgressController>();

  final RxBool isInitialized = false.obs;
  final Rxn<GameLevel> selectedLevel = Rxn<GameLevel>();
  final RxnString selectedGroupId = RxnString();
  final RxMap<String, LevelProgressStatus> levelStatusById =
      <String, LevelProgressStatus>{}.obs;
  final RxList<String> unlockedLevelIds = <String>[].obs;
  final RxList<String> inProgressLevelIds = <String>[].obs;
  final RxList<String> completedLevelIds = <String>[].obs;

  final RxList<int> tiles = <int>[].obs;
  final RxBool isSolved = false.obs;
  final imageAsync = Rx<ui.Image?>(null);
  final RxnInt hoveredTargetIndex = RxnInt();
  final RxnInt activeDragAnchorIndex = RxnInt();
  final RxnInt activeDragClusterId = RxnInt();
  final RxMap<int, int> boardIndexToClusterId = <int, int>{}.obs;
  final RxMap<int, List<int>> clusterIdToBoardIndices = <int, List<int>>{}.obs;
  late final Worker _progressMetricsWorker;

  int get rowCount =>
      selectedLevel.value?.difficulty.rows ?? PuzzleDifficulty.easiest.rows;
  int get columnCount =>
      selectedLevel.value?.difficulty.columns ??
      PuzzleDifficulty.easiest.columns;

  @override
  void onInit() {
    super.onInit();
    _log.fine('onInit called');
    _progressMetricsWorker = ever<Map<String, LevelProgressStatus>>(
      levelStatusById,
      (_) {
        _syncDerivedProgressMetrics();
      },
    );
    isInitialized.value = false;
    _initializeLevelState();
  }

  @override
  void onClose() {
    _progressMetricsWorker.dispose();
    super.onClose();
  }

  Future<void> _initializeLevelState() async {
    final LevelProgressSnapshot snapshot = await _progressStorage.load();
    levelStatusById.assignAll(snapshot.levelStatusById);
    _syncDerivedProgressMetrics();

    final String preferredLevelId =
        snapshot.selectedLevelId ?? AppConfig.defaultLevelId;
    GameLevel? initialLevel = _levelById(preferredLevelId);

    if (initialLevel == null || !isLevelUnlocked(initialLevel.id)) {
      initialLevel = _firstUnlockedLevel();
    }

    if (initialLevel == null) {
      initialLevel = AppConfig.levels.first;
      _setLevelStatus(initialLevel.id, LevelProgressStatus.unlocked);
    }

    await _applyLevel(
      initialLevel,
      persistSelection: snapshot.selectedLevelId != initialLevel.id,
      reshuffle: true,
    );

    await _persistProgressSnapshot(selectedLevelId: initialLevel.id);
    isInitialized.value = true;
  }

  void _syncDerivedProgressMetrics() {
    final List<String> unlocked = <String>[];
    final List<String> inProgress = <String>[];
    final List<String> completed = <String>[];

    for (final GameLevel level in AppConfig.levels) {
      final LevelProgressStatus status =
          levelStatusById[level.id] ?? LevelProgressStatus.locked;
      if (status == LevelProgressStatus.unlocked ||
          status == LevelProgressStatus.inProgress ||
          status == LevelProgressStatus.completed) {
        unlocked.add(level.id);
      }
      if (status == LevelProgressStatus.inProgress) {
        inProgress.add(level.id);
      }
      if (status == LevelProgressStatus.completed) {
        completed.add(level.id);
      }
    }

    unlockedLevelIds.assignAll(unlocked);
    inProgressLevelIds.assignAll(inProgress);
    completedLevelIds.assignAll(completed);
  }

  bool _setLevelStatus(String levelId, LevelProgressStatus status) {
    final LevelProgressStatus current =
        levelStatusById[levelId] ?? LevelProgressStatus.locked;
    if (current == status) {
      return false;
    }
    levelStatusById[levelId] = status;
    return true;
  }

  bool _setSelectedLevelInProgress(String selectedLevelId) {
    bool changed = false;

    for (final String id in levelStatusById.keys.toList(growable: false)) {
      final LevelProgressStatus status = levelStatusById[id]!;
      if (status == LevelProgressStatus.inProgress && id != selectedLevelId) {
        levelStatusById[id] = LevelProgressStatus.unlocked;
        changed = true;
      }
    }

    final LevelProgressStatus selectedStatus =
        levelStatusById[selectedLevelId] ?? LevelProgressStatus.locked;
    if (selectedStatus == LevelProgressStatus.unlocked) {
      levelStatusById[selectedLevelId] = LevelProgressStatus.inProgress;
      changed = true;
    }

    return changed;
  }

  Future<void> _persistProgressSnapshot({String? selectedLevelId}) async {
    await _progressStorage.saveSnapshot(
      LevelProgressSnapshot.fromLevelStatuses(
        selectedLevelId: selectedLevelId ?? selectedLevel.value?.id,
        statusByLevelId: Map<String, LevelProgressStatus>.from(levelStatusById),
      ),
    );
  }

  List<GameLevel> get levels => AppConfig.levels;
  List<LevelGroup> get groups => AppConfig.levelGroups;

  List<GameLevel> levelsForGroup(String groupId) {
    return AppConfig.levels.where((level) => level.groupId == groupId).toList()
      ..sort((a, b) => a.orderInGroup.compareTo(b.orderInGroup));
  }

  Future<void> setSelectedGroup(String groupId) async {
    if (selectedGroupId.value == groupId) {
      return;
    }

    selectedGroupId.value = groupId;

    final List<GameLevel> groupLevels = levelsForGroup(groupId);
    if (groupLevels.isEmpty) {
      return;
    }

    final GameLevel? selected = selectedLevel.value;
    if (selected != null && selected.groupId == groupId) {
      return;
    }

    GameLevel? firstUnlocked;
    for (final GameLevel level in groupLevels) {
      if (isLevelUnlocked(level.id)) {
        firstUnlocked = level;
        break;
      }
    }

    if (firstUnlocked != null) {
      await selectLevel(firstUnlocked);
    }
  }

  bool isLevelUnlocked(String levelId) => unlockedLevelIds.contains(levelId);

  bool isLevelCompleted(String levelId) => completedLevelIds.contains(levelId);

  Future<void> selectLevel(GameLevel level) async {
    _log.fine('Selecting level: ${level.id}');

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
    selectedLevel.value = level;
    selectedGroupId.value = level.groupId;
    final bool progressChanged = _setSelectedLevelInProgress(level.id);

    await _loadImage(level.imageAssetPath);

    if (persistSelection || progressChanged) {
      await _persistProgressSnapshot(selectedLevelId: level.id);
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

    if (_setLevelStatus(level.id, LevelProgressStatus.completed)) {
      changed = true;
    }

    final GameLevel? next = _nextLevelInGroup(level);
    if (next != null &&
        (levelStatusById[next.id] ?? LevelProgressStatus.locked) ==
            LevelProgressStatus.locked) {
      _setLevelStatus(next.id, LevelProgressStatus.unlocked);
      changed = true;
    }

    if (!changed) {
      return;
    }

    await _persistProgressSnapshot();
  }

  Future<void> resetLevelProgress() async {
    final GameLevel defaultLevel =
        _levelById(AppConfig.defaultLevelId) ?? AppConfig.levels.first;

    final Map<String, LevelProgressStatus> resetStatuses =
        <String, LevelProgressStatus>{};
    for (final LevelGroup group in AppConfig.levelGroups) {
      for (final GameLevel level in group.levels) {
        resetStatuses[level.id] = level.orderInGroup == 1
            ? LevelProgressStatus.unlocked
            : LevelProgressStatus.locked;
      }
    }
    levelStatusById.assignAll(resetStatuses);

    await _applyLevel(defaultLevel, persistSelection: false, reshuffle: true);
    await _persistProgressSnapshot(selectedLevelId: defaultLevel.id);
  }

  GameLevel? _nextLevelInGroup(GameLevel level) {
    final List<GameLevel> sameGroupLevels = levelsForGroup(level.groupId);
    for (final GameLevel candidate in sameGroupLevels) {
      if (candidate.orderInGroup == level.orderInGroup + 1) {
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
      if (isLevelUnlocked(level.id)) {
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
