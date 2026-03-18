import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_level_snapshot.dart';

class LevelProgressGroupSnapshot {
  const LevelProgressGroupSnapshot({
    required this.groupId,
    required this.name,
    required this.description,
    required this.order,
    required this.levels,
  });

  final String groupId;
  final String name;
  final String description;
  final int order;
  final List<LevelProgressLevelSnapshot> levels;

  factory LevelProgressGroupSnapshot.fromLevelGroup({
    required LevelGroup group,
    required List<LevelProgressLevelSnapshot> levels,
  }) {
    return LevelProgressGroupSnapshot(
      groupId: group.id,
      name: group.name,
      description: group.description,
      order: group.order,
      levels: levels,
    );
  }

  factory LevelProgressGroupSnapshot.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawLevels =
        (json['levels'] as List<dynamic>?) ?? const <dynamic>[];

    return LevelProgressGroupSnapshot(
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
      levels: rawLevels
          .whereType<Map<String, dynamic>>()
          .map(LevelProgressLevelSnapshot.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'groupId': groupId,
      'name': name,
      'description': description,
      'order': order,
      'levels': levels.map((l) => l.toJson()).toList(growable: false),
    };
  }
}
