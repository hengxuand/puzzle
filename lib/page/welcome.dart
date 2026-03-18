import 'package:discovery_puzzle/models/game_level.dart';
import 'package:discovery_puzzle/models/level_group.dart';
import 'package:discovery_puzzle/page/game.dart';
import 'package:discovery_puzzle/state/game/puzzle_game_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/game_level_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_status_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PuzzleGameController _puzzleController =
      Get.find<PuzzleGameController>();
  final GameLevelController _gameLevelController =
      Get.find<GameLevelController>();
  final LevelStatusController _levelStatusController =
      Get.find<LevelStatusController>();

  String? _selectedGroupId;
  String? _selectedLevelId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Center(
        child: Obx(() {
          final List<LevelGroup> groups =
              (_gameLevelController.progressSnapshot.value?.groups.values
                        .toList(growable: false) ??
                    <LevelGroup>[])
                ..sort((a, b) => a.order.compareTo(b.order));

          if (groups.isEmpty) {
            return const SizedBox.shrink();
          }

          final String selectedGroupId =
              groups.any((group) => group.id == _selectedGroupId)
              ? _selectedGroupId!
              : groups.first.id;

          final LevelGroup selectedGroup = groups.firstWhere(
            (group) => group.id == selectedGroupId,
          );

          final List<GameLevel> levels = selectedGroup.levels.values.toList()
            ..sort((a, b) => a.orderInGroup.compareTo(b.orderInGroup));

          final GameLevel? selectedLevel = levels
              .where((level) => level.id == _selectedLevelId)
              .cast<GameLevel?>()
              .firstOrNull;

          return Column(
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
                  child: Column(
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
                                setState(() {
                                  _selectedGroupId = group.id;
                                  _selectedLevelId = null;
                                });
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
                                isSelected: _selectedLevelId == level.id,
                                isLocked: _levelStatusController.isLocked(
                                  level.id,
                                ),
                                isCompleted: _levelStatusController.isCompleted(
                                  level.id,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedLevelId = level.id;
                                  });
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
                        Get.offAll(
                          () => GamePage(selectedLevel: selectedLevel),
                        );
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
                    await _puzzleController.resetLevelProgress();
                    setState(() {
                      _selectedGroupId = null;
                      _selectedLevelId = null;
                    });
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
    final bool isUnlocked = !isLocked;
    final BorderRadius cardBorderRadius = BorderRadius.circular(12);

    return Card(
      elevation: isSelected ? 12 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
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
