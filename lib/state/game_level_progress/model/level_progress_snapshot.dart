import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_group_snapshot.dart';

class LevelProgressSnapshot {
  const LevelProgressSnapshot({required this.groups});

  final List<LevelProgressGroupSnapshot> groups;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': 1,
      'groups': groups.map((g) => g.toJson()).toList(growable: false),
    };
  }

  static LevelProgressSnapshot? fromJson(Map<String, dynamic> decoded) {
    if (decoded.isEmpty) {
      return null;
    }

    final List<dynamic> groupsJson = decoded['groups'] ?? [];
    final List<LevelProgressGroupSnapshot> groups = groupsJson
        .whereType<Map<String, dynamic>>()
        .map(LevelProgressGroupSnapshot.fromJson)
        .toList();

    return LevelProgressSnapshot(groups: groups);
  }
}
