import 'package:discovery_puzzle/config/app_config.dart';
import 'package:discovery_puzzle/page/game.dart';
import 'package:discovery_puzzle/state/puzzle_providers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final PuzzleGameController controller = Get.find<PuzzleGameController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Center(
        child: Obx(
          () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Discovery Puzzle',
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
                  child: _GroupedLevelSelector(controller: controller),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.selectedLevel.value == null
                    ? null
                    : () {
                        Get.offAll(() => const GamePage());
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
                    await controller.resetLevelProgress();
                  }
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset Levels'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupedLevelSelector extends StatelessWidget {
  const _GroupedLevelSelector({required this.controller});

  final PuzzleGameController controller;

  @override
  Widget build(BuildContext context) {
    final List<LevelGroup> groups = controller.groups;
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    final String selectedGroupId =
        controller.selectedGroupId.value ?? groups.first.id;
    final List<GameLevel> levels = controller.levelsForGroup(selectedGroupId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final LevelGroup group = groups[index];
              final bool isSelected = selectedGroupId == group.id;
              return ChoiceChip(
                selected: isSelected,
                label: Text(group.name),
                onSelected: (_) {
                  controller.setSelectedGroup(group.id);
                },
              );
            },
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemCount: groups.length,
          ),
        ),
        const SizedBox(height: 8),
        for (final LevelGroup group in groups)
          if (group.id == selectedGroupId)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        Expanded(
          child: ListView(
            children: [
              for (final GameLevel level in levels)
                _LevelCard(level: level, controller: controller),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.controller});

  final GameLevel level;
  final PuzzleGameController controller;

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = controller.isLevelUnlocked(level.id);
    final bool isCompleted = controller.isLevelCompleted(level.id);
    final bool isSelected = controller.selectedLevel.value?.id == level.id;
    final BorderRadius cardBorderRadius = BorderRadius.circular(12);

    return Card(
      elevation: isSelected ? 12 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: InkWell(
        borderRadius: cardBorderRadius,
        onTap: isUnlocked
            ? () {
                controller.selectLevel(level);
              }
            : null,
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
              if (!isUnlocked)
                const Icon(Icons.lock_outline, color: Colors.grey)
              else if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                const Icon(Icons.radio_button_unchecked),
            ],
          ),
        ),
      ),
    );
  }
}
