import 'package:get/get.dart';
import 'package:puzzle/logic/puzzle_logic.dart';
import 'package:puzzle/service/progress_storage_service.dart';
import 'package:puzzle/service/puzzle_image_loader.dart';
import 'package:puzzle/state/game/puzzle_game_controller.dart';

class PuzzleDependenciesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ProgressStorageService(), permanent: true);
    Get.put(PuzzleLogic(), permanent: true);
    Get.put(PuzzleImageLoader(), permanent: true);
    Get.put(PuzzleGameController(), permanent: true);
  }
}
