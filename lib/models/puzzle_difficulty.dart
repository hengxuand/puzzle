enum PuzzleDifficulty {
  easy._(label: 'Easy', rows: 5, columns: 4),
  mid._(label: 'Medium', rows: 7, columns: 6),
  hard._(label: 'Hard', rows: 9, columns: 8);

  const PuzzleDifficulty._({
    required this.label,
    required this.rows,
    required this.columns,
  });

  final String label;
  final int rows;
  final int columns;

  static PuzzleDifficulty fromWire(String? value) {
    switch (value) {
      case 'easy':
        return PuzzleDifficulty.easy;
      case 'mid':
        return PuzzleDifficulty.mid;
      case 'hard':
        return PuzzleDifficulty.hard;
      default:
        return fromLabel(value);
    }
  }

  static PuzzleDifficulty fromLabel(String? value) {
    switch (value) {
      case 'Easy':
        return PuzzleDifficulty.easy;
      case 'Medium':
        return PuzzleDifficulty.mid;
      case 'Hard':
        return PuzzleDifficulty.hard;
      default:
        return PuzzleDifficulty.easy;
    }
  }

  String get displaySize => '${columns}x$rows';
}
