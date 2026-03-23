import 'dart:ui';

import 'package:flame/components.dart';

class BoardSlotComponent extends PositionComponent {
  BoardSlotComponent({required this.boardIndex})
    : super(anchor: Anchor.topLeft, priority: 1);

  final int boardIndex;

  void setHovered(bool value) {
    // Intentionally no-op: board uses a uniform background color.
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color.fromARGB(77, 111, 126, 111);

    canvas.drawRect(size.toRect(), fillPaint);
  }
}
