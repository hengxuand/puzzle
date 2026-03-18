import 'package:discovery_puzzle/models/level_group.dart';

class LevelProgressSnapshot {
  const LevelProgressSnapshot({required this.groups});

  final Map<String, LevelGroup> groups;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': 1,
      'groups': groups.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  static LevelProgressSnapshot? fromJson(Map<String, dynamic> decoded) {
    if (decoded.isEmpty) {
      return null;
    }

    final dynamic rawGroups = decoded['groups'];

    final Map<String, LevelGroup> groups;
    if (rawGroups is Map<String, dynamic>) {
      groups = Map<String, LevelGroup>.fromEntries(
        rawGroups.entries
            .where((entry) => entry.value is Map<String, dynamic>)
            .map(
              (entry) => MapEntry(
                entry.key,
                LevelGroup.fromJson(<String, dynamic>{
                  ...((entry.value as Map<String, dynamic>)),
                  'id':
                      (entry.value as Map<String, dynamic>)['id'] ?? entry.key,
                }),
              ),
            ),
      );
    } else {
      final List<dynamic> groupsJson =
          (rawGroups as List<dynamic>?) ?? const <dynamic>[];
      groups = Map<String, LevelGroup>.fromEntries(
        groupsJson
            .whereType<Map<String, dynamic>>()
            .map(LevelGroup.fromJson)
            .map((group) => MapEntry(group.id, group)),
      );
    }

    return LevelProgressSnapshot(groups: groups);
  }
}
