import 'package:discovery_puzzle/models/level_progress_status.dart';
import 'package:discovery_puzzle/models/puzzle_difficulty.dart';

class GameLevel {
  const GameLevel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.imageAssetPath,
    this.thumbnailAssetPath,
    this.status = LevelProgressStatus.locked,
  });

  final int id;
  final int groupId;
  final String name;
  final String description;
  final PuzzleDifficulty difficulty;
  final String imageAssetPath;
  final String? thumbnailAssetPath;
  final LevelProgressStatus status;

  factory GameLevel.fromJson(Map<String, dynamic> json) {
    return GameLevel(
      id: _parseLevelId(json['id'] ?? json['levelId']),
      groupId: _parseGroupId(json['groupId']),
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: PuzzleDifficulty.fromWire(
        (json['difficulty'] ?? json['difficultyLabel']) as String?,
      ),
      imageAssetPath: json['imageAssetPath'] as String,
      thumbnailAssetPath: json['thumbnailAssetPath'] as String?,
      status: LevelProgressStatusWire.fromWire(json['status'] as String?),
    );
  }

  static int _parseLevelId(dynamic rawId) {
    if (rawId is int) {
      return rawId;
    }

    if (rawId is String) {
      final int? direct = int.tryParse(rawId);
      if (direct != null) {
        return direct;
      }
    }

    throw FormatException('Invalid level id: $rawId');
  }

  static int _parseGroupId(dynamic rawGroupId) {
    if (rawGroupId is int) {
      return rawGroupId;
    }

    if (rawGroupId is String) {
      final int? direct = int.tryParse(rawGroupId);
      if (direct != null) {
        return direct;
      }
    }

    throw FormatException('Invalid group id: $rawGroupId');
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
      'status': status.wireValue,
    };
  }
}
