part of 'puzzle_game_controller.dart';

extension PuzzleGameControllerProgress on PuzzleGameController {
  Future<LevelProgressSnapshot> loadProgress() async {
    final LevelProgressSnapshot? snapshot = _storageService
        .loadProgressSnapshot();
    if (snapshot != null) {
      PuzzleGameController._log.info('Loaded progress snapshot from storage.');
      progressSnapshot.value = snapshot;
      return snapshot;
    }

    final Map<int, LevelGroup> seededGroups = _buildInitialGroupsFromConfig();
    final LevelProgressSnapshot seededSnapshot = LevelProgressSnapshot(
      groups: seededGroups,
    );

    unawaited(_storageService.saveProgressSnapshot(seededSnapshot));
    PuzzleGameController._log.info(
      'Initialized progress snapshot with seeded data.',
    );
    progressSnapshot.value = seededSnapshot;
    return seededSnapshot;
  }

  Future<GameLevel?> loadSelectedLevel() async {
    if (progressSnapshot.value == null) {
      await loadProgress();
    }

    final GameLevel? level = _storageService.loadSelectedLevel();
    if (level == null) {
      PuzzleGameController._log.warning(
        'No previously selected level found in storage.',
      );
      _selectDefaultLevelForGroup(Levels.defaultLevel.groupId);
      PuzzleGameController._log.info(
        'Initialized selected level with default group.',
      );
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
      PuzzleGameController._log.warning(
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
        PuzzleGameController._log.fine(
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
          PuzzleGameController._log.fine(
            'Unlocking next level $nextLevelId in group $groupId.',
          );
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
      PuzzleGameController._log.warning(
        'Cannot mark level completed: level ${level.id} not found.',
      );
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
    PuzzleGameController._log.fine('Selecting level: ${level.id}');

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
    PuzzleGameController._log.fine('Loading image from asset: $assetPath');
    imageAsync.value = await _imageLoader.loadFromAsset(assetPath);
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
}
