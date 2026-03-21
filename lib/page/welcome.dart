import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:puzzle/config/app_config.dart';
import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_group.dart';
import 'package:puzzle/page/game.dart';
import 'package:puzzle/page/widgets/level_card.dart';
import 'package:puzzle/page/widgets/reset_levels_button.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final PuzzleGameController puzzleController =
        Get.find<PuzzleGameController>();

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Obx(() {
            final GameLevel? selectedLevel =
                puzzleController.selectedLevel.value;

            final List<LevelGroup> groups =
                (puzzleController.progressSnapshot.value?.groups.values.toList(
                        growable: false,
                      ) ??
                      <LevelGroup>[])
                  ..sort((a, b) => a.id.compareTo(b.id));

            if (groups.isEmpty) {
              return const SizedBox.shrink();
            }

            final int selectedGroupId =
                puzzleController.selectedGroupId.value ?? groups.first.id;

            final LevelGroup selectedGroup = groups.firstWhere(
              (group) => group.id == selectedGroupId,
              orElse: () => groups.first,
            );

            final List<GameLevel> levels = selectedGroup.levels.values.toList()
              ..sort((a, b) => a.id.compareTo(b.id));

            final bool isSelectedLevelCompleted =
                selectedLevel != null &&
                puzzleController.isCompleted(selectedLevel.id);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Story Puzzle',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a story to start your puzzle adventure!',
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
                                  puzzleController.selectGroup(group.id);
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
                                LevelCard(
                                  level: level,
                                  isSelected: selectedLevel?.id == level.id,
                                  isLocked: puzzleController.isLocked(level.id),
                                  isCompleted: puzzleController.isCompleted(
                                    level.id,
                                  ),
                                  onTap: () {
                                    puzzleController.selectLevel(level);
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
                      : () async {
                          await puzzleController.openLevel(
                            selectedLevel,
                            reshuffle: !isSelectedLevelCompleted,
                          );
                          Get.to(() => GamePage());
                        },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Text(
                      isSelectedLevelCompleted
                          ? 'View the puzzle'
                          : 'Solve the Puzzle',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                if (kDebugMode)
                  ResetLevelsButton(puzzleController: puzzleController),
                const SizedBox(height: 32),
              ],
            );
          }),
        ),
      ),
    );
  }
}
