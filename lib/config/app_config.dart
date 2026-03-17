class AppConfig {
  const AppConfig._();

  static const List<PuzzleDifficulty> difficultyPresets = <PuzzleDifficulty>[
    PuzzleDifficulty.easiest,
  ];
  static const PuzzleDifficulty developmentDifficulty =
      PuzzleDifficulty.easiest;
  static const PuzzleDifficulty defaultDifficulty = PuzzleDifficulty.easiest;
  static const String puzzleImagePath = 'assets/levels/guanyu/guanyu_1.png';

  static const List<LevelGroup> levelGroups = <LevelGroup>[
    LevelGroup(
      id: 'guanyu',
      name: 'Guan Yu',
      description: 'Steady tactical boards.',
      order: 1,
      levels: <GameLevel>[
        GameLevel(
          id: 'guanyu_1',
          groupId: 'guanyu',
          name: 'Green Dragon I',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/guanyu/guanyu_1.png',
          thumbnailAssetPath: 'assets/levels/guanyu/guanyu_1.png',
          orderInGroup: 1,
        ),
        GameLevel(
          id: 'guanyu_2',
          groupId: 'guanyu',
          name: 'Green Dragon II',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/guanyu/guanyu_2.png',
          thumbnailAssetPath: 'assets/levels/guanyu/guanyu_2.png',
          orderInGroup: 2,
        ),
        GameLevel(
          id: 'guanyu_3',
          groupId: 'guanyu',
          name: 'Green Dragon III',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/guanyu/guanyu_3.png',
          thumbnailAssetPath: 'assets/levels/guanyu/guanyu_3.png',
          orderInGroup: 3,
        ),
      ],
    ),
    LevelGroup(
      id: 'caocao',
      name: 'Cao Cao',
      description: 'Balanced strategic boards.',
      order: 2,
      levels: <GameLevel>[
        GameLevel(
          id: 'caocao_1',
          groupId: 'caocao',
          name: 'Wei Vanguard I',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/caocao/caocao_1.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_1.png',
          orderInGroup: 1,
        ),
        GameLevel(
          id: 'caocao_2',
          groupId: 'caocao',
          name: 'Wei Vanguard II',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/caocao/caocao_2.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_2.png',
          orderInGroup: 2,
        ),
        GameLevel(
          id: 'caocao_3',
          groupId: 'caocao',
          name: 'Wei Vanguard III',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/caocao/caocao_3.png',
          thumbnailAssetPath: 'assets/levels/caocao/caocao_3.png',
          orderInGroup: 3,
        ),
      ],
    ),
    LevelGroup(
      id: 'lvbu',
      name: 'Lv Bu',
      description: 'Aggressive battle boards.',
      order: 3,
      levels: <GameLevel>[
        GameLevel(
          id: 'lvbu_1',
          groupId: 'lvbu',
          name: 'Sky Halberd I',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/lvbu/lvbu_1.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_1.png',
          orderInGroup: 1,
        ),
        GameLevel(
          id: 'lvbu_2',
          groupId: 'lvbu',
          name: 'Sky Halberd II',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/lvbu/lvbu_2.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_2.png',
          orderInGroup: 2,
        ),
        GameLevel(
          id: 'lvbu_3',
          groupId: 'lvbu',
          name: 'Sky Halberd III',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/lvbu/lvbu_3.png',
          thumbnailAssetPath: 'assets/levels/lvbu/lvbu_3.png',
          orderInGroup: 3,
        ),
      ],
    ),
    LevelGroup(
      id: 'zhangfei',
      name: 'Zhang Fei',
      description: 'Raw force puzzle boards.',
      order: 4,
      levels: <GameLevel>[
        GameLevel(
          id: 'zhangfei_1',
          groupId: 'zhangfei',
          name: 'Black Spear I',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_1.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_1.png',
          orderInGroup: 1,
        ),
        GameLevel(
          id: 'zhangfei_2',
          groupId: 'zhangfei',
          name: 'Black Spear II',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_2.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_2.png',
          orderInGroup: 2,
        ),
        GameLevel(
          id: 'zhangfei_3',
          groupId: 'zhangfei',
          name: 'Black Spear III',
          description: 'Easy mode training board.',
          difficulty: developmentDifficulty,
          imageAssetPath: 'assets/levels/zhangfei/zhangfei_3.png',
          thumbnailAssetPath: 'assets/levels/zhangfei/zhangfei_3.png',
          orderInGroup: 3,
        ),
      ],
    ),
  ];

  static final List<GameLevel> levels = <GameLevel>[
    for (final LevelGroup group in levelGroups) ...group.levels,
  ];

  static final Map<String, int> levelSortOrderById = <String, int>{
    for (final LevelGroup group in levelGroups)
      for (final GameLevel level in group.levels)
        level.id: group.order * 100 + level.orderInGroup,
  };

  static const String defaultLevelId = 'guanyu_1';
}

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
  final List<GameLevel> levels;
}

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
  });

  final String id;
  final String groupId;
  final String name;
  final String description;
  final PuzzleDifficulty difficulty;
  final String imageAssetPath;
  final String? thumbnailAssetPath;
  final int orderInGroup;
}

class PuzzleDifficulty {
  const PuzzleDifficulty._({
    required this.label,
    required this.rows,
    required this.columns,
  });

  final String label;
  final int rows;
  final int columns;

  static const PuzzleDifficulty easiest = PuzzleDifficulty._(
    label: 'Easy',
    rows: 3,
    columns: 2,
  );
  static const PuzzleDifficulty mid = PuzzleDifficulty._(
    label: 'Medium',
    rows: 3,
    columns: 2,
  );
  static const PuzzleDifficulty hardest = PuzzleDifficulty._(
    label: 'Hard',
    rows: 3,
    columns: 2,
  );

  String get displaySize => '${rows}x$columns';
}
