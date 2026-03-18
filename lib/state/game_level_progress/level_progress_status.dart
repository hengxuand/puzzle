enum LevelProgressStatus { locked, unlocked, inProgress, completed }

extension LevelProgressStatusWire on LevelProgressStatus {
  String get wireValue {
    switch (this) {
      case LevelProgressStatus.locked:
        return 'locked';
      case LevelProgressStatus.unlocked:
        return 'unlocked';
      case LevelProgressStatus.inProgress:
        return 'in_progress';
      case LevelProgressStatus.completed:
        return 'completed';
    }
  }

  static LevelProgressStatus fromWire(String? value) {
    switch (value) {
      case 'unlocked':
        return LevelProgressStatus.unlocked;
      case 'in_progress':
        return LevelProgressStatus.inProgress;
      case 'completed':
        return LevelProgressStatus.completed;
      case 'locked':
      default:
        return LevelProgressStatus.locked;
    }
  }
}
