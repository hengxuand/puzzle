import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class ClusterDragGhostComponent extends PositionComponent {
  ClusterDragGhostComponent() : super(anchor: Anchor.topLeft, priority: 10);

  void setFromData({
    required Vector2 anchorPosition,
    required List<GhostPieceData> pieces,
  }) {
    position = anchorPosition;
    for (final Component child in children.toList()) {
      child.removeFromParent();
    }

    for (final GhostPieceData piece in pieces) {
      final _GhostTileComponent tile = _GhostTileComponent(
        sprite: piece.sprite,
        position: piece.relativeOffset,
        size: piece.size,
        roundTopLeft: piece.roundTopLeft,
        roundTopRight: piece.roundTopRight,
        roundBottomRight: piece.roundBottomRight,
        roundBottomLeft: piece.roundBottomLeft,
      );

      add(tile);
    }

    scale = Vector2.all(0.96);
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.11, curve: Curves.easeOutCubic),
      ),
    );
  }

  void setAnchorWithDelta({required Vector2 anchor, required Vector2 delta}) {
    position = anchor + delta;
  }
}

class GhostPieceData {
  const GhostPieceData({
    required this.sprite,
    required this.relativeOffset,
    required this.size,
    required this.roundTopLeft,
    required this.roundTopRight,
    required this.roundBottomRight,
    required this.roundBottomLeft,
  });

  final Sprite sprite;
  final Vector2 relativeOffset;
  final Vector2 size;
  final bool roundTopLeft;
  final bool roundTopRight;
  final bool roundBottomRight;
  final bool roundBottomLeft;
}

class _GhostTileComponent extends SpriteComponent {
  _GhostTileComponent({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    required bool roundTopLeft,
    required bool roundTopRight,
    required bool roundBottomRight,
    required bool roundBottomLeft,
  }) : super(
         sprite: sprite,
         position: position,
         size: size,
         anchor: Anchor.topLeft,
       ) {
    _roundTopLeft = roundTopLeft;
    _roundTopRight = roundTopRight;
    _roundBottomRight = roundBottomRight;
    _roundBottomLeft = roundBottomLeft;
    opacity = 0.96;
  }

  static const double _cornerRadius = 2.0;
  late final bool _roundTopLeft;
  late final bool _roundTopRight;
  late final bool _roundBottomRight;
  late final bool _roundBottomLeft;

  @override
  void render(Canvas canvas) {
    final RRect roundedRect = RRect.fromRectAndCorners(
      size.toRect(),
      topLeft: Radius.circular(_roundTopLeft ? _cornerRadius : 0),
      topRight: Radius.circular(_roundTopRight ? _cornerRadius : 0),
      bottomRight: Radius.circular(_roundBottomRight ? _cornerRadius : 0),
      bottomLeft: Radius.circular(_roundBottomLeft ? _cornerRadius : 0),
    );

    canvas.save();
    canvas.clipRRect(roundedRect);
    super.render(canvas);
    canvas.restore();
  }
}
