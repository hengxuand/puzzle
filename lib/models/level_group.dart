import 'package:discovery_puzzle/models/game_level.dart';

class LevelGroup {
  const LevelGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.levels,
  });

  final String id;
  final String name;
  final String description;
  final int order;
  final Map<String, GameLevel> levels;

  factory LevelGroup.fromJson(Map<String, dynamic> json) {
    final dynamic rawLevels = json['levels'];

    final Map<String, GameLevel> parsedLevels;
    if (rawLevels is Map<String, dynamic>) {
      parsedLevels = Map<String, GameLevel>.fromEntries(
        rawLevels.entries
            .where((entry) => entry.value is Map<String, dynamic>)
            .map(
              (entry) => MapEntry(
                entry.key,
                GameLevel.fromJson(<String, dynamic>{
                  ...((entry.value as Map<String, dynamic>)),
                  'id':
                      (entry.value as Map<String, dynamic>)['id'] ?? entry.key,
                }),
              ),
            ),
      );
    } else {
      final List<dynamic> rawLevelsList =
          (rawLevels as List<dynamic>?) ?? const <dynamic>[];
      parsedLevels = Map<String, GameLevel>.fromEntries(
        rawLevelsList
            .whereType<Map<String, dynamic>>()
            .map(GameLevel.fromJson)
            .map((level) => MapEntry(level.id, level)),
      );
    }

    return LevelGroup(
      id: (json['id'] ?? json['groupId']) as String,
      name: json['name'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
      levels: parsedLevels,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'levels': levels.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
