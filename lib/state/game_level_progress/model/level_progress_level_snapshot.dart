import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/state/game_level_progress/model/level_progress_status.dart';

class LevelProgressLevelSnapshot {
  const LevelProgressLevelSnapshot({
    required this.levelId,
    required this.groupId,
    required this.name,
    required this.description,
    required this.difficultyLabel,
    required this.rows,
    required this.columns,
    required this.imageAssetPath,
    required this.thumbnailAssetPath,
    required this.orderInGroup,
    required this.status,
  });

  final String levelId;
  final String groupId;
  final String name;
  final String description;
  final String difficultyLabel;
  final int rows;
  final int columns;
  final String imageAssetPath;
  final String? thumbnailAssetPath;
  final int orderInGroup;
  final LevelProgressStatus status;

  factory LevelProgressLevelSnapshot.fromGameLevel({
    required GameLevel level,
    required LevelProgressStatus status,
  }) {
    return LevelProgressLevelSnapshot(
      levelId: level.id,
      groupId: level.groupId,
      name: level.name,
      description: level.description,
      difficultyLabel: level.difficulty.label,
      rows: level.difficulty.rows,
      columns: level.difficulty.columns,
      imageAssetPath: level.imageAssetPath,
      thumbnailAssetPath: level.thumbnailAssetPath,
      orderInGroup: level.orderInGroup,
      status: status,
    );
  }

  factory LevelProgressLevelSnapshot.fromJson(Map<String, dynamic> json) {
    return LevelProgressLevelSnapshot(
      levelId: json['levelId'] as String,
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficultyLabel: json['difficultyLabel'] as String,
      rows: json['rows'] as int,
      columns: json['columns'] as int,
      imageAssetPath: json['imageAssetPath'] as String,
      thumbnailAssetPath: json['thumbnailAssetPath'] as String?,
      orderInGroup: json['orderInGroup'] as int,
      status: LevelProgressStatusWire.fromWire(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'levelId': levelId,
      'groupId': groupId,
      'name': name,
      'description': description,
      'difficultyLabel': difficultyLabel,
      'rows': rows,
      'columns': columns,
      'imageAssetPath': imageAssetPath,
      'thumbnailAssetPath': thumbnailAssetPath,
      'orderInGroup': orderInGroup,
      'status': status.wireValue,
    };
  }
}
