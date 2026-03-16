class AppConfig {
  const AppConfig._();

  static const List<PuzzleDifficulty> difficultyPresets = <PuzzleDifficulty>[
    PuzzleDifficulty.easiest,
    PuzzleDifficulty.mid,
    PuzzleDifficulty.hardest,
  ];
  static const PuzzleDifficulty defaultDifficulty = PuzzleDifficulty.easiest;
  static const String puzzleImagePath = 'assets/guanyu2.png';

  static const List<GameLevel> levels = <GameLevel>[
    GameLevel(
      id: 'level_1',
      name: 'Opening Trial',
      description: 'A gentle warm-up puzzle.',
      difficulty: PuzzleDifficulty.easiest,
      imageAssetPath: 'assets/guanyu2.png',
      thumbnailAssetPath: 'assets/guanyu2.png',
      order: 1,
    ),
    GameLevel(
      id: 'level_2',
      name: 'Fierce Focus',
      description: 'More tiles and tighter grouping.',
      difficulty: PuzzleDifficulty.mid,
      imageAssetPath: 'assets/guanyu.png',
      thumbnailAssetPath: 'assets/guanyu.png',
      order: 2,
    ),
    GameLevel(
      id: 'level_3',
      name: 'Master Board',
      description: 'Maximum board complexity.',
      difficulty: PuzzleDifficulty.hardest,
      imageAssetPath: 'assets/guanyu2.png',
      thumbnailAssetPath: 'assets/guanyu2.png',
      order: 3,
    ),
  ];

  static const String defaultLevelId = 'level_1';
}

class GameLevel {
  const GameLevel({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.imageAssetPath,
    this.thumbnailAssetPath,
    required this.order,
  });

  final String id;
  final String name;
  final String description;
  final PuzzleDifficulty difficulty;
  final String imageAssetPath;
  final String? thumbnailAssetPath;
  final int order;
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
