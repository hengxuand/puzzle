enum PuzzleDifficulty {
  easiest._(label: 'Easy', rows: 3, columns: 2),
  mid._(label: 'Medium', rows: 3, columns: 2),
  hardest._(label: 'Hard', rows: 3, columns: 2);

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
      case 'easiest':
        return PuzzleDifficulty.easiest;
      case 'mid':
        return PuzzleDifficulty.mid;
      case 'hardest':
        return PuzzleDifficulty.hardest;
      default:
        return fromLabel(value);
    }
  }

  static PuzzleDifficulty fromLabel(String? value) {
    switch (value) {
      case 'Easy':
        return PuzzleDifficulty.easiest;
      case 'Medium':
        return PuzzleDifficulty.mid;
      case 'Hard':
        return PuzzleDifficulty.hardest;
      default:
        return PuzzleDifficulty.easiest;
    }
  }

  String get displaySize => '${rows}x$columns';
}
