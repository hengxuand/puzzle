import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/models/level_progress_status.dart';
import 'package:puzzle/models/puzzle_difficulty.dart';

class Levels {
  static GameLevel defaultLevel = GameLevel(
    id: 1,
    groupId: 1,
    name: 'The Origin of the Monkey King',
    description: 'The birth of the legendary Monkey King',
    difficulty: PuzzleDifficulty.easy,
    imageAssetPath: 'assets/images/levels/xiyouji-level-1.png',
    thumbnailAssetPath: 'assets/images/levels/xiyouji-level-1.png',
    status: LevelProgressStatus.unlocked,
  );

  static List<LevelGroup> levelGroups = <LevelGroup>[
    LevelGroup(
      id: 1,
      name: 'Xi You Ji',
      description: 'Journey to the West',
      order: 0,
      levels: <int, GameLevel>{
        1: defaultLevel,
        2: GameLevel(
          id: 2,
          groupId: 1,
          name: 'The Monkey King\'s Training',
          description: 'The Monkey King\'s Training',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-2.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-2.png',
          status: LevelProgressStatus.locked,
        ),
        3: GameLevel(
          id: 3,
          groupId: 1,
          name: 'Weapon from the Sea',
          description: 'The Monkey King\'s Weapon from the Sea',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-3.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-3.png',
          status: LevelProgressStatus.locked,
        ),
        4: GameLevel(
          id: 4,
          groupId: 1,
          name: 'Becoming immortal',
          description: 'Becoming immortal',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-4.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-4.png',
          status: LevelProgressStatus.locked,
        ),
      },
    ),
  ];
}
