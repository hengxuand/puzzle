import 'package:discovery_puzzle/logic/puzzle_logic.dart';
import 'package:discovery_puzzle/service/progress_storage_service.dart';
import 'package:discovery_puzzle/service/puzzle_image_loader.dart';
import 'package:discovery_puzzle/state/game/puzzle_game_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/game_level_controller.dart';
import 'package:discovery_puzzle/state/game_level_progress/level_status_controller.dart';
import 'package:get/get.dart';

class PuzzleDependenciesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ProgressStorageService(), permanent: true);
    Get.put(PuzzleLogic(), permanent: true);
    Get.put(GameLevelController(), permanent: true);
    Get.put(LevelStatusController(), permanent: true);
    Get.put(const PuzzleImageLoader(), permanent: true);
    Get.put(PuzzleGameController(), permanent: true);
  }
}
