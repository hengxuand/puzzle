import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class PuzzleImageLoader {
  PuzzleImageLoader();

  Future<ui.Image> loadFromAsset(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    try {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } finally {
      codec.dispose();
    }
  }
}
