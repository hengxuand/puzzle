import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class ResetLevelsButton extends StatelessWidget {
  const ResetLevelsButton({super.key, required this.puzzleController});

  final PuzzleGameController puzzleController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset Levels'),
        ),
      ],
    );
  }
}
