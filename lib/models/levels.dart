import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/models/level_progress_status.dart';
import 'package:puzzle/models/puzzle_difficulty.dart';

class Levels {
  static GameLevel defaultLevel = GameLevel(
    id: 1,
    groupId: 1,
    name: 'Birth of the Stone Monkey',
    description: 'Birth of the Stone Monkey',
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
          name: 'The Disciple Kneels',
          description: 'The Disciple Kneels',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-2.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-2.png',
          status: LevelProgressStatus.locked,
        ),
        3: GameLevel(
          id: 3,
          groupId: 1,
          name: 'Claiming the Jingu Bang',
          description: 'Claiming the Jingu Bang',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-3.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-3.png',
          status: LevelProgressStatus.locked,
        ),
        4: GameLevel(
          id: 4,
          groupId: 1,
          name: 'Chaos in the Underworld',
          description: 'Chaos in the Underworld',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-4.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-4.png',
          status: LevelProgressStatus.locked,
        ),
        5: GameLevel(
          id: 5,
          groupId: 1,
          name: 'Havoc in the Heavenly Palace',
          description: 'Havoc in the Heavenly Palace',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-5.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-5.png',
          status: LevelProgressStatus.locked,
        ),
        6: GameLevel(
          id: 6,
          groupId: 1,
          name: 'The Imprisonment',
          description: 'The Imprisonment',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-6.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-6.png',
          status: LevelProgressStatus.locked,
        ),
        7: GameLevel(
          id: 7,
          groupId: 1,
          name: 'The Journey Begins',
          description: 'The Journey Begins',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-7.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-7.png',
          status: LevelProgressStatus.locked,
        ),
        8: GameLevel(
          id: 8,
          groupId: 1,
          name: 'The Golden Fillet',
          description: 'The Golden Fillet',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-8.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-8.png',
          status: LevelProgressStatus.locked,
        ),
        9: GameLevel(
          id: 9,
          groupId: 1,
          name: 'Subduing the White Dragon',
          description: 'Subduing the White Dragon',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-9.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-9.png',
          status: LevelProgressStatus.locked,
        ),
        10: GameLevel(
          id: 10,
          groupId: 1,
          name: 'Meeting Zhu Bajie',
          description: 'Meeting Zhu Bajie',
          difficulty: PuzzleDifficulty.easy,
          imageAssetPath: 'assets/images/levels/xiyouji-level-10.png',
          thumbnailAssetPath: 'assets/images/levels/xiyouji-level-10.png',
          status: LevelProgressStatus.locked,
        ),
      },
    ),
  ];
}
