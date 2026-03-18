import 'package:discovery_puzzle/state/game_level_progress/level_progress_status.dart';

class LevelProgressLevelSnapshot {
  const LevelProgressLevelSnapshot({
    required this.levelId,
    required this.status,
  });

  final String levelId;
  final LevelProgressStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'levelId': levelId, 'status': status.wireValue};
  }
}
