import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/page/game.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';
import 'package:puzzle/state/game_level_progress/game_level_controller.dart';
import 'package:puzzle/state/game_level_progress/level_status_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final PuzzleGameController puzzleController =
        Get.find<PuzzleGameController>();
    final GameLevelController gameLevelController =
        Get.find<GameLevelController>();
    final LevelStatusController levelStatusController =
        Get.find<LevelStatusController>();

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Obx(() {
            final GameLevel? selectedLevel =
                gameLevelController.selectedLevel.value;

            final List<LevelGroup> groups =
                (gameLevelController.progressSnapshot.value?.groups.values
                          .toList(growable: false) ??
                      <LevelGroup>[])
                  ..sort((a, b) => a.id.compareTo(b.id));

            if (groups.isEmpty) {
              return const SizedBox.shrink();
            }

            final int selectedGroupId =
                gameLevelController.selectedGroupId.value ?? groups.first.id;

            final LevelGroup selectedGroup = groups.firstWhere(
              (group) => group.id == selectedGroupId,
              orElse: () => groups.first,
            );

            final List<GameLevel> levels = selectedGroup.levels.values.toList()
              ..sort((a, b) => a.id.compareTo(b.id));

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Puzzle',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a group, then a level',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 70,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final LevelGroup group = groups[index];
                              final bool isSelected =
                                  selectedGroup.id == group.id;

                              return ChoiceChip(
                                selected: isSelected,
                                label: Text(group.name),
                                onSelected: (_) {
                                  gameLevelController.selectGroup(group.id);
                                },
                              );
                            },
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: 8),
                            itemCount: groups.length,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            selectedGroup.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              for (final GameLevel level in levels)
                                _LevelCard(
                                  level: level,
                                  isSelected: selectedLevel?.id == level.id,
                                  isLocked: levelStatusController.isLocked(
                                    level.id,
                                  ),
                                  isCompleted: levelStatusController
                                      .isCompleted(level.id),
                                  onTap: () {
                                    gameLevelController.selectLevel(level);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selectedLevel == null
                      ? null
                      : () {
                          Get.to(() => GamePage(selectedLevel: selectedLevel));
                        },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Text('Start Game', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final bool? confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Reset Level Progress?'),
                        content: const Text(
                          'This will clear completed levels and lock all levels except the first one.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await puzzleController.resetLevelProgress();
                      gameLevelController.clearSelection();
                    }
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Levels'),
                ),
                const SizedBox(height: 32),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
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
    final isUnlocked = !isLocked;
    final cardBorderRadius = BorderRadius.circular(12);

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
