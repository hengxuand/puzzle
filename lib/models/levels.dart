import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/models/puzzle_difficulty.dart';

class Levels {
  static const defaultLevel = GameLevel(
    id: 1,
    groupId: 1,
    name: 'Green Dragon I',
    description: 'Easy mode training board.',
    difficulty: PuzzleDifficulty.easiest,
    imageAssetPath: 'assets/levels/guanyu/guanyu_1.png',
    thumbnailAssetPath: 'assets/levels/guanyu/guanyu_1.png',
  );

  static const List<LevelGroup> levelGroups = <LevelGroup>[
    LevelGroup(
      id: 1,
      name: 'Guan Yu',
      description: 'Steady tactical boards.',
      order: 1,
      levels: <int, GameLevel>{
        1: defaultLevel,
        2: GameLevel(
          id: 2,
          groupId: 1,
          name: 'Green Dragon II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/guanyu/guanyu_2.png',
          thumbnailAssetPath: 'assets/levels/guanyu/guanyu_2.png',
        ),
        3: GameLevel(
          id: 3,
          groupId: 1,
          name: 'Green Dragon III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/guanyu/guanyu_3.png',
          thumbnailAssetPath: 'assets/levels/guanyu/guanyu_3.png',
        ),
      },
    ),
    LevelGroup(
      id: 2,
      name: 'Cao Cao',
      description: 'Balanced strategic boards.',
      order: 2,
      levels: <int, GameLevel>{
        4: GameLevel(
          id: 4,
          groupId: 2,
          name: 'Wei Vanguard I',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/caocao/caocao_1.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_1.png',
        ),
        5: GameLevel(
          id: 5,
          groupId: 2,
          name: 'Wei Vanguard II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/caocao/caocao_2.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_2.png',
        ),
        6: GameLevel(
          id: 6,
          groupId: 2,
          name: 'Wei Vanguard III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/caocao/caocao_3.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_3.png',
        ),
      },
    ),
    LevelGroup(
      id: 3,
      name: 'Lv Bu',
      description: 'Aggressive battle boards.',
      order: 3,
      levels: <int, GameLevel>{
        7: GameLevel(
          id: 7,
          groupId: 3,
          name: 'Sky Halberd I',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/lvbu/lvbu_1.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_1.png',
        ),
        8: GameLevel(
          id: 8,
          groupId: 3,
          name: 'Sky Halberd II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/lvbu/lvbu_2.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_2.png',
        ),
        9: GameLevel(
          id: 9,
          groupId: 3,
          name: 'Sky Halberd III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/lvbu/lvbu_3.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_3.png',
        ),
      },
    ),
    LevelGroup(
      id: 4,
      name: 'Zhang Fei',
      description: 'Raw force puzzle boards.',
      order: 4,
      levels: <int, GameLevel>{
        10: GameLevel(
          id: 10,
          groupId: 4,
          name: 'Black Spear I',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_1.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_1.png',
        ),
        11: GameLevel(
          id: 11,
          groupId: 4,
          name: 'Black Spear II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_2.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_2.png',
        ),
        12: GameLevel(
          id: 12,
          groupId: 4,
          name: 'Black Spear III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_3.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_3.png',
        ),
      },
    ),
  ];

  // static final List<GameLevel> levels = <GameLevel>[
  //   for (final LevelGroup group in levelGroups) ...group.levels,
  // ];

  // static final Map<String, int> levelSortOrderById = <String, int>{
  //   for (final LevelGroup group in levelGroups)
  //     for (final GameLevel level in group.levels)
  //       level.id: group.order * 100 + level.id,
  // };
}
