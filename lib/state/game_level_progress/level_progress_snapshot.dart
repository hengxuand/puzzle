import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_group_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_level_snapshot.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_progress_status.dart';

class LevelProgressSnapshot {
  const LevelProgressSnapshot({
    required this.selectedLevelId,
    required this.groups,
  });

  final String? selectedLevelId;
  final List<LevelProgressGroupSnapshot> groups;

  Map<String, LevelProgressStatus> get levelStatusById {
    final Map<String, LevelProgressStatus> statuses =
        <String, LevelProgressStatus>{};
    for (final LevelProgressGroupSnapshot group in groups) {
      for (final LevelProgressLevelSnapshot level in group.levels) {
        statuses[level.levelId] = level.status;
      }
    }
    return statuses;
  }

  List<String> get unlockedLevelIds {
    return _levelIdsByStatus(
      (LevelProgressStatus status) => status != LevelProgressStatus.locked,
    );
  }

  List<String> get inProgressLevelIds {
    return _levelIdsByStatus(
      (LevelProgressStatus status) => status == LevelProgressStatus.inProgress,
    );
  }

  List<String> get completedLevelIds {
    return _levelIdsByStatus(
      (LevelProgressStatus status) => status == LevelProgressStatus.completed,
    );
  }

  List<String> _levelIdsByStatus(bool Function(LevelProgressStatus) include) {
    final List<String> result = <String>[];
    final Map<String, LevelProgressStatus> statuses = levelStatusById;
    for (final LevelGroup group in AppConfig.levelGroups) {
      for (final GameLevel level in group.levels) {
        final LevelProgressStatus status =
            statuses[level.id] ?? LevelProgressStatus.locked;
        if (include(status)) {
          result.add(level.id);
        }
      }
    }
    return result;
  }

  LevelProgressSnapshot copyWith({
    String? selectedLevelId,
    bool clearSelectedLevel = false,
    List<LevelProgressGroupSnapshot>? groups,
  }) {
    return LevelProgressSnapshot(
      selectedLevelId: clearSelectedLevel
          ? null
          : (selectedLevelId ?? this.selectedLevelId),
      groups: groups ?? this.groups,
    );
  }

  static LevelProgressSnapshot fromLevelStatuses({
    required String? selectedLevelId,
    required Map<String, LevelProgressStatus> statusByLevelId,
  }) {
    final Map<String, LevelProgressStatus> normalizedStatuses =
        _normalizedStatuses(
          selectedLevelId: selectedLevelId,
          statusByLevelId: statusByLevelId,
        );

    final List<LevelProgressGroupSnapshot> groupSnapshots =
        <LevelProgressGroupSnapshot>[];
    for (final LevelGroup group in AppConfig.levelGroups) {
      final List<LevelProgressLevelSnapshot> levelSnapshots =
          <LevelProgressLevelSnapshot>[];
      for (final GameLevel level in group.levels) {
        levelSnapshots.add(
          LevelProgressLevelSnapshot(
            levelId: level.id,
            status: normalizedStatuses[level.id] ?? LevelProgressStatus.locked,
          ),
        );
      }
      groupSnapshots.add(
        LevelProgressGroupSnapshot(groupId: group.id, levels: levelSnapshots),
      );
    }

    final String? normalizedSelectedLevelId = _normalizedSelectedLevelId(
      selectedLevelId,
      normalizedStatuses,
    );

    return LevelProgressSnapshot(
      selectedLevelId: normalizedSelectedLevelId,
      groups: groupSnapshots,
    );
  }

  static Map<String, LevelProgressStatus> _normalizedStatuses({
    required String? selectedLevelId,
    required Map<String, LevelProgressStatus> statusByLevelId,
  }) {
    final Map<String, LevelProgressStatus> statuses =
        <String, LevelProgressStatus>{
          for (final LevelGroup group in AppConfig.levelGroups)
            for (final GameLevel level in group.levels)
              level.id: level.orderInGroup == 1
                  ? LevelProgressStatus.unlocked
                  : LevelProgressStatus.locked,
        };

    for (final MapEntry<String, LevelProgressStatus> entry
        in statusByLevelId.entries) {
      if (!statuses.containsKey(entry.key)) {
        continue;
      }
      statuses[entry.key] = entry.value;
    }

    final List<String> inProgressIds = <String>[];
    for (final MapEntry<String, LevelProgressStatus> entry
        in statuses.entries) {
      if (entry.value == LevelProgressStatus.inProgress) {
        inProgressIds.add(entry.key);
      }
    }

    for (final String id in inProgressIds) {
      statuses[id] = LevelProgressStatus.unlocked;
    }

    String? activeLevelId;
    if (selectedLevelId != null && statuses.containsKey(selectedLevelId)) {
      activeLevelId = selectedLevelId;
    } else if (inProgressIds.isNotEmpty) {
      activeLevelId = inProgressIds.first;
    }

    if (activeLevelId != null) {
      final LevelProgressStatus activeStatus = statuses[activeLevelId]!;
      if (activeStatus != LevelProgressStatus.completed) {
        statuses[activeLevelId] = LevelProgressStatus.inProgress;
      }
    }

    return statuses;
  }

  static String? _normalizedSelectedLevelId(
    String? selectedLevelId,
    Map<String, LevelProgressStatus> statuses,
  ) {
    if (selectedLevelId != null && statuses.containsKey(selectedLevelId)) {
      return selectedLevelId;
    }

    for (final GameLevel level in AppConfig.levels) {
      final LevelProgressStatus status =
          statuses[level.id] ?? LevelProgressStatus.locked;
      if (status != LevelProgressStatus.locked) {
        return level.id;
      }
    }

    return AppConfig.levels.isEmpty ? null : AppConfig.levels.first.id;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': 1,
      'selectedLevelId': selectedLevelId,
      'groups': groups.map((g) => g.toJson()).toList(growable: false),
    };
  }
}
