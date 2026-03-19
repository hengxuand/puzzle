import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class PuzzleImageLoader {
  PuzzleImageLoader();

  Future<ui.Image> loadFromAsset(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
}
