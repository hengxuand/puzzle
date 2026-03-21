part of 'puzzle_game_controller.dart';

extension PuzzleGameControllerBoard on PuzzleGameController {
  void swapTiles(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    PuzzleGameController._log.fine('Swapped tiles: $fromIndex and $toIndex');

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
    PuzzleGameController._log.fine(
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

    PuzzleGameController._log.info(
      'Board state updated. isSolved: $isSolved, level status: ${selectedLevel.value?.status}',
    );

    if (!wasSolved && isSolved) {
      PuzzleGameController._log.fine(
        'Current level ${selectedLevel.value?.id ?? 'none'} wasn\'t solved and is now solved.',
      );
      unawaited(markLevelCompleted(selectedLevel.value));
    }
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
