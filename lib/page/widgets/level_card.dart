import 'package:flutter/material.dart';
import 'package:puzzle/models/game_level.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.isSelected,
    required this.isLocked,
    required this.isCompleted,
    required this.onTap,
  });

  final GameLevel level;
  final bool isSelected;
  final bool isLocked;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = !isLocked;
    final BorderRadius cardBorderRadius = BorderRadius.circular(12);

    return Card(
      elevation: isSelected ? 8 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(128),
                width: 3,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: cardBorderRadius,
        onTap: isLocked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: ColorFiltered(
                    colorFilter: isUnlocked
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.srcOver,
                          )
                        : const ColorFilter.mode(
                            Color(0x88000000),
                            BlendMode.srcATop,
                          ),
                    child: Image.asset(
                      level.thumbnailAssetPath ?? level.imageAssetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${level.name} (Easy ${level.difficulty.displaySize})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (isLocked)
                const Icon(Icons.lock_outline, color: Colors.grey)
              else if (isSelected)
                const Icon(Icons.radio_button_checked)
              else
                const Icon(Icons.radio_button_unchecked),
            ],
          ),
        ),
      ),
    );
  }
}
