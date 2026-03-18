import 'package:discovery_puzzle/models/game_level.dart';
import 'package:discovery_puzzle/models/level_group.dart';
import 'package:discovery_puzzle/models/puzzle_difficulty.dart';

class Levels {
  static const defaultLevel = GameLevel(
    id: 'guanyu_1',
    groupId: 'guanyu',
    name: 'Green Dragon I',
    description: 'Easy mode training board.',
    difficulty: PuzzleDifficulty.easiest,
    imageAssetPath: 'assets/levels/guanyu/guanyu_1.png',
    thumbnailAssetPath: 'assets/levels/guanyu/guanyu_1.png',
    orderInGroup: 1,
  );

  static const List<LevelGroup> levelGroups = <LevelGroup>[
    LevelGroup(
      id: 'guanyu',
      name: 'Guan Yu',
      description: 'Steady tactical boards.',
      order: 1,
      levels: <String, GameLevel>{
        'guanyu_1': defaultLevel,
        'guanyu_2': GameLevel(
          id: 'guanyu_2',
          groupId: 'guanyu',
          name: 'Green Dragon II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/guanyu/guanyu_2.png',
          thumbnailAssetPath: 'assets/levels/guanyu/guanyu_2.png',
          orderInGroup: 2,
        ),
        'guanyu_3': GameLevel(
          id: 'guanyu_3',
          groupId: 'guanyu',
          name: 'Green Dragon III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/guanyu/guanyu_3.png',
          thumbnailAssetPath: 'assets/levels/guanyu/guanyu_3.png',
          orderInGroup: 3,
        ),
      },
    ),
    LevelGroup(
      id: 'caocao',
      name: 'Cao Cao',
      description: 'Balanced strategic boards.',
      order: 2,
      levels: <String, GameLevel>{
        'caocao_1': GameLevel(
          id: 'caocao_1',
          groupId: 'caocao',
          name: 'Wei Vanguard I',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/caocao/caocao_1.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_1.png',
          orderInGroup: 1,
        ),
        'caocao_2': GameLevel(
          id: 'caocao_2',
          groupId: 'caocao',
          name: 'Wei Vanguard II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/caocao/caocao_2.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_2.png',
          orderInGroup: 2,
        ),
        'caocao_3': GameLevel(
          id: 'caocao_3',
          groupId: 'caocao',
          name: 'Wei Vanguard III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/caocao/caocao_3.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_3.png',
          orderInGroup: 3,
        ),
      },
    ),
    LevelGroup(
      id: 'lvbu',
      name: 'Lv Bu',
      description: 'Aggressive battle boards.',
      order: 3,
      levels: <String, GameLevel>{
        'lvbu_1': GameLevel(
          id: 'lvbu_1',
          groupId: 'lvbu',
          name: 'Sky Halberd I',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/lvbu/lvbu_1.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_1.png',
          orderInGroup: 1,
        ),
        'lvbu_2': GameLevel(
          id: 'lvbu_2',
          groupId: 'lvbu',
          name: 'Sky Halberd II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/lvbu/lvbu_2.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_2.png',
          orderInGroup: 2,
        ),
        'lvbu_3': GameLevel(
          id: 'lvbu_3',
          groupId: 'lvbu',
          name: 'Sky Halberd III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/lvbu/lvbu_3.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_3.png',
          orderInGroup: 3,
        ),
      },
    ),
    LevelGroup(
      id: 'zhangfei',
      name: 'Zhang Fei',
      description: 'Raw force puzzle boards.',
      order: 4,
      levels: <String, GameLevel>{
        'zhangfei_1': GameLevel(
          id: 'zhangfei_1',
          groupId: 'zhangfei',
          name: 'Black Spear I',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_1.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_1.png',
          orderInGroup: 1,
        ),
        'zhangfei_2': GameLevel(
          id: 'zhangfei_2',
          groupId: 'zhangfei',
          name: 'Black Spear II',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_2.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_2.png',
          orderInGroup: 2,
        ),
        'zhangfei_3': GameLevel(
          id: 'zhangfei_3',
          groupId: 'zhangfei',
          name: 'Black Spear III',
          description: 'Easy mode training board.',
          difficulty: PuzzleDifficulty.easiest,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_3.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_3.png',
          orderInGroup: 3,
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
  //       level.id: group.order * 100 + level.orderInGroup,
  // };
}
