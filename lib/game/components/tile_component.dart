import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

class TileComponent extends SpriteComponent with DragCallbacks {
  TileComponent({
    required this.pieceIndex,
    required this.boardIndex,
    required this.onDragStartRequested,
    required this.onDragDeltaRequested,
    required this.onDragEndRequested,
  }) : super(anchor: Anchor.topLeft, priority: 2);

  final int pieceIndex;
  int boardIndex;

  final void Function(TileComponent tile) onDragStartRequested;
  final void Function(Vector2 delta) onDragDeltaRequested;
  final void Function() onDragEndRequested;

  bool _showTopBorder = true;
  bool _showRightBorder = true;
  bool _showBottomBorder = true;
  bool _showLeftBorder = true;
  bool _roundTopLeft = false;
  bool _roundTopRight = false;
  bool _roundBottomRight = false;
  bool _roundBottomLeft = false;
  bool _showDragPlaceholder = false;

  static const double _cornerRadius = 2.0;

  void syncFrame({
    required Sprite sprite,
    required int newBoardIndex,
    required Vector2 tileSize,
  }) {
    this.sprite = sprite;
    boardIndex = newBoardIndex;
    size = tileSize;
  }

  void applyVisualState({
    required bool isInActiveCluster,
    required bool isDragging,
    required bool showTopBorder,
    required bool showRightBorder,
    required bool showBottomBorder,
    required bool showLeftBorder,
    required bool roundTopLeft,
    required bool roundTopRight,
    required bool roundBottomRight,
    required bool roundBottomLeft,
    required bool showDragPlaceholder,
  }) {
    _showTopBorder = showTopBorder;
    _showRightBorder = showRightBorder;
    _showBottomBorder = showBottomBorder;
    _showLeftBorder = showLeftBorder;
    _roundTopLeft = roundTopLeft;
    _roundTopRight = roundTopRight;
    _roundBottomRight = roundBottomRight;
    _roundBottomLeft = roundBottomLeft;
    _showDragPlaceholder = showDragPlaceholder;
    opacity = isDragging ? 0.82 : (isInActiveCluster ? 0.16 : 1.0);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    onDragStartRequested(this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    onDragDeltaRequested(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    onDragEndRequested();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    onDragEndRequested();
  }

  @override
  void render(Canvas canvas) {
    if (_showDragPlaceholder) {
      return;
    }

    final RRect tileShape = RRect.fromRectAndCorners(
      size.toRect(),
      topLeft: Radius.circular(_roundTopLeft ? _cornerRadius : 0),
      topRight: Radius.circular(_roundTopRight ? _cornerRadius : 0),
      bottomRight: Radius.circular(_roundBottomRight ? _cornerRadius : 0),
      bottomLeft: Radius.circular(_roundBottomLeft ? _cornerRadius : 0),
    );

    canvas.save();
    canvas.clipRRect(tileShape);
    super.render(canvas);
    canvas.restore();

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x00000000);

    final double width = size.x;
    final double height = size.y;
    final double topLeftInset = _roundTopLeft ? _cornerRadius : 0;
    final double topRightInset = _roundTopRight ? _cornerRadius : 0;
    final double bottomRightInset = _roundBottomRight ? _cornerRadius : 0;
    final double bottomLeftInset = _roundBottomLeft ? _cornerRadius : 0;

    if (_showTopBorder) {
      canvas.drawLine(
        Offset(topLeftInset, 0),
        Offset(width - topRightInset, 0),
        borderPaint,
      );
    }
    if (_showRightBorder) {
      canvas.drawLine(
        Offset(width, topRightInset),
        Offset(width, height - bottomRightInset),
        borderPaint,
      );
    }
    if (_showBottomBorder) {
      canvas.drawLine(
        Offset(bottomLeftInset, height),
        Offset(width - bottomRightInset, height),
        borderPaint,
      );
    }
    if (_showLeftBorder) {
      canvas.drawLine(
        Offset(0, topLeftInset),
        Offset(0, height - bottomLeftInset),
        borderPaint,
      );
    }
  }
}
