import 'package:discovery_puzzle/state/game_level_progress/level_progress_level_snapshot.dart';

class LevelProgressGroupSnapshot {
  const LevelProgressGroupSnapshot({
    required this.groupId,
    required this.levels,
  });

  final String groupId;
  final List<LevelProgressLevelSnapshot> levels;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'groupId': groupId,
      'levels': levels.map((l) => l.toJson()).toList(growable: false),
    };
  }
}
