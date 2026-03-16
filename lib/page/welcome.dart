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
                'Choose a level',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final GameLevel level in AppConfig.levels)
                      _LevelCard(level: level, controller: controller),
                  ],
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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

    return Card(
      elevation: isSelected ? 6 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
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
                      '${level.name} (${level.difficulty.displaySize})',
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
