import 'package:discovery_puzzle/models/game_level.dart';

class LevelGroup {
  const LevelGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.levels,
  });

  final int id;
  final String name;
  final String description;
  final int order;
  final Map<int, GameLevel> levels;

  factory LevelGroup.fromJson(Map<String, dynamic> json) {
    final dynamic rawLevels = json['levels'];

    final Map<int, GameLevel> parsedLevels;
    if (rawLevels is Map<String, dynamic>) {
      parsedLevels = Map<int, GameLevel>.fromEntries(
        rawLevels.entries
            .where((entry) => entry.value is Map<String, dynamic>)
            .map((entry) {
              final GameLevel level = GameLevel.fromJson(<String, dynamic>{
                ...((entry.value as Map<String, dynamic>)),
                'id': (entry.value as Map<String, dynamic>)['id'] ?? entry.key,
              });
              return MapEntry(level.id, level);
            }),
      );
    } else {
      final List<dynamic> rawLevelsList =
          (rawLevels as List<dynamic>?) ?? const <dynamic>[];
      parsedLevels = Map<int, GameLevel>.fromEntries(
        rawLevelsList
            .whereType<Map<String, dynamic>>()
            .map(GameLevel.fromJson)
            .map((level) => MapEntry(level.id, level)),
      );
    }

    return LevelGroup(
      id: _parseGroupId(json['id'] ?? json['groupId']),
      name: json['name'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
      levels: parsedLevels,
    );
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'levels': levels.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
    };
  }
}
