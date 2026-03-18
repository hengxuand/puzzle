import 'package:discovery_puzzle/models/puzzle_difficulty.dart';
import 'package:discovery_puzzle/models/level_progress_status.dart';

class GameLevel {
  const GameLevel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.imageAssetPath,
    this.thumbnailAssetPath,
    required this.orderInGroup,
    this.status = LevelProgressStatus.locked,
  });

  final String id;
  final String groupId;
  final String name;
  final String description;
  final PuzzleDifficulty difficulty;
  final String imageAssetPath;
  final String? thumbnailAssetPath;
  final int orderInGroup;
  final LevelProgressStatus status;

  factory GameLevel.fromJson(Map<String, dynamic> json) {
    return GameLevel(
      id: (json['id'] ?? json['levelId']) as String,
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: PuzzleDifficulty.fromWire(
        (json['difficulty'] ?? json['difficultyLabel']) as String?,
      ),
      imageAssetPath: json['imageAssetPath'] as String,
      thumbnailAssetPath: json['thumbnailAssetPath'] as String?,
      orderInGroup: json['orderInGroup'] as int,
      status: LevelProgressStatusWire.fromWire(json['status'] as String?),
    );
  }

  GameLevel copyWith({LevelProgressStatus? status}) {
    return GameLevel(
      id: id,
      groupId: groupId,
      name: name,
      description: description,
      difficulty: difficulty,
      imageAssetPath: imageAssetPath,
      thumbnailAssetPath: thumbnailAssetPath,
      orderInGroup: orderInGroup,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'groupId': groupId,
      'name': name,
      'description': description,
      'difficulty': difficulty.name,
      'imageAssetPath': imageAssetPath,
      'thumbnailAssetPath': thumbnailAssetPath,
      'orderInGroup': orderInGroup,
      'status': status.wireValue,
    };
  }
}
