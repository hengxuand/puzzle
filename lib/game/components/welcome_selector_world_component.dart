import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:puzzle/models/game_level.dart';
import 'package:puzzle/models/level_group.dart';

enum _DragMode { undecided, horizontal, vertical }

class WelcomeSelectorWorldComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference {
  WelcomeSelectorWorldComponent({
    required this.onGroupChanged,
    required this.onLevelTapped,
    required this.isLocked,
    required this.isCompleted,
  }) : super(anchor: Anchor.topLeft, priority: 1);

  final _log = Logger('WelcomeSelectorWorldComponent');

  final void Function(int groupId) onGroupChanged;
  final void Function(GameLevel level) onLevelTapped;
  final bool Function(int levelId) isLocked;
  final bool Function(int levelId) isCompleted;

  static const double _cardWidthFactor = 0.88;
  static const double _cardHeightFactor = 0.86;
  static const double _cardSpacingFactor = 0.98;
  static const double _levelRowHeight = 90;
  static const double _snapSettleSpeed = 16.0;
  static const double _snapThresholdFactor = 0.13;
  static const int _thumbnailDecodeWidth = 120;
  static const int _thumbnailDecodeHeight = 140;
  static const int _maxTextPainterCacheEntries = 320;

  static const ColorFilter _grayscaleColorFilter = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  List<LevelGroup> _groups = <LevelGroup>[];
  Map<int, List<GameLevel>> _sortedLevelsByGroup = <int, List<GameLevel>>{};
  final Map<int, double> _verticalScrollOffsets = <int, double>{};
  final Map<String, ui.Image> _imageCache = <String, ui.Image>{};
  final Map<String, Future<ui.Image?>> _thumbnailLoadFutures =
      <String, Future<ui.Image?>>{};
  final Map<int, bool> _lockedByLevelId = <int, bool>{};
  final Map<int, bool> _completedByLevelId = <int, bool>{};
  final Map<int, int> _completedLevelCountByGroup = <int, int>{};
  final Map<int, int> _totalLevelCountByGroup = <int, int>{};
  final Map<String, TextPainter> _textPainterCache = <String, TextPainter>{};

  final Paint _plainImagePaint = Paint();
  final Paint _lockedThumbnailPaint = Paint()
    ..colorFilter = _grayscaleColorFilter;

  // Reusable paints to avoid per-frame allocations in render.
  final Paint _reusableFillPaint = Paint();
  final Paint _reusableStrokePaint = Paint()..style = PaintingStyle.stroke;

  int _activeIndex = 0;
  int? _selectedLevelId;

  _DragMode _dragMode = _DragMode.undecided;
  bool _isDragging = false;
  Vector2 _dragStart = Vector2.zero();
  Vector2 _dragDelta = Vector2.zero();
  double _horizontalOffset = 0;
  double _introProgress = 0;
  int? _pendingSnapIndex;
  double _snapTargetOffset = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (size.x <= 1 || size.y <= 1) {
      size = Vector2(game.size.x, game.size.y);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (size.x <= 1 || size.y <= 1) {
      size = Vector2(game.size.x, game.size.y);
    }

    _introProgress = (_introProgress + (dt * 1.4)).clamp(0, 1);

    if (!_isDragging && _horizontalOffset.abs() > 0.01) {
      final double targetOffset = _pendingSnapIndex == null
          ? 0
          : _snapTargetOffset;
      final double step = (dt * _snapSettleSpeed).clamp(0, 1);
      _horizontalOffset =
          ui.lerpDouble(_horizontalOffset, targetOffset, step) ?? 0;

      if ((_horizontalOffset - targetOffset).abs() < 0.8) {
        if (_pendingSnapIndex != null) {
          _activeIndex = _pendingSnapIndex!;
          _pendingSnapIndex = null;
          _snapTargetOffset = 0;
          onGroupChanged(_groups[_activeIndex].id);
        }
        _horizontalOffset = 0;
      }
    }
  }

  void syncFromController({
    required List<LevelGroup> groups,
    required int? selectedGroupId,
    required int? selectedLevelId,
  }) {
    _groups = groups;
    _selectedLevelId = selectedLevelId;

    _sortedLevelsByGroup = <int, List<GameLevel>>{
      for (final LevelGroup group in groups)
        group.id: (group.levels.values.toList(growable: false)
          ..sort((a, b) => a.id.compareTo(b.id))),
    };

    _lockedByLevelId.clear();
    _completedByLevelId.clear();
    _completedLevelCountByGroup.clear();
    _totalLevelCountByGroup.clear();

    for (final LevelGroup group in groups) {
      final List<GameLevel> levels =
          _sortedLevelsByGroup[group.id] ?? const <GameLevel>[];
      int completedCount = 0;
      for (final GameLevel level in levels) {
        final bool locked = isLocked(level.id);
        final bool completed = isCompleted(level.id);
        _lockedByLevelId[level.id] = locked;
        _completedByLevelId[level.id] = completed;
        if (completed) {
          completedCount++;
        }
      }
      _completedLevelCountByGroup[group.id] = completedCount;
      _totalLevelCountByGroup[group.id] = levels.length;
    }

    for (final LevelGroup group in groups) {
      _verticalScrollOffsets[group.id] ??= 0;
      _verticalScrollOffsets[group.id] = _verticalScrollOffsets[group.id]!
          .clamp(0, _maxVerticalScrollForGroup(group.id));
    }

    // Preload thumbnails for all levels
    for (final GameLevel level in _sortedLevelsByGroup.values.expand(
      (l) => l,
    )) {
      final String thumbnailPath =
          level.thumbnailAssetPath ?? level.imageAssetPath;
      if (!_imageCache.containsKey(thumbnailPath)) {
        _loadThumbnail(thumbnailPath);
      }
    }

    if (_groups.isEmpty) {
      _activeIndex = 0;
      _horizontalOffset = 0;
      _pendingSnapIndex = null;
      _snapTargetOffset = 0;
      return;
    }

    final int selectedIndex = selectedGroupId == null
        ? 0
        : _groups.indexWhere((group) => group.id == selectedGroupId);
    if (selectedIndex >= 0) {
      _activeIndex = selectedIndex;
    } else {
      _activeIndex = _activeIndex.clamp(0, _groups.length - 1);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (_groups.isEmpty) {
      return;
    }

    final Vector2 local = event.localPosition;
    final int nearestIndex = _nearestCardIndex(local.x);
    if (nearestIndex != _activeIndex) {
      _selectCardIndex(nearestIndex, animateFromTap: true, notify: true);
      return;
    }

    final Rect cardRect = _cardRectForIndex(_activeIndex, withOffset: true);
    if (!cardRect.contains(local.toOffset())) {
      return;
    }

    final Rect listRect = _levelsViewportRect(cardRect);
    if (!listRect.contains(local.toOffset())) {
      return;
    }

    final LevelGroup group = _groups[_activeIndex];
    final List<GameLevel> levels =
        _sortedLevelsByGroup[group.id] ?? const <GameLevel>[];
    final double scrollOffset = _verticalScrollOffsets[group.id] ?? 0;
    final double localY = local.y - listRect.top + scrollOffset;
    final int rowIndex = (localY / _levelRowHeight).floor();

    if (rowIndex < 0 || rowIndex >= levels.length) {
      return;
    }

    final GameLevel tapped = levels[rowIndex];
    if (isLocked(tapped.id)) {
      return;
    }

    onLevelTapped(tapped);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _dragMode = _DragMode.undecided;
    _dragStart = event.localPosition.clone();
    _dragDelta = Vector2.zero();
    _pendingSnapIndex = null;
    _snapTargetOffset = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_groups.isEmpty) {
      return;
    }

    _dragDelta += event.localDelta;
    if (_dragMode == _DragMode.undecided) {
      final double absX = _dragDelta.x.abs();
      final double absY = _dragDelta.y.abs();
      if (absX + absY < 6) {
        return;
      }

      final Rect activeListRect = _levelsViewportRect(
        _cardRectForIndex(_activeIndex, withOffset: true),
      );
      final bool startedInList = activeListRect.contains(_dragStart.toOffset());
      if (startedInList && absY > absX + 2) {
        _dragMode = _DragMode.vertical;
      } else {
        _dragMode = _DragMode.horizontal;
      }
    }

    if (_dragMode == _DragMode.vertical) {
      final LevelGroup group = _groups[_activeIndex];
      final double currentOffset = _verticalScrollOffsets[group.id] ?? 0;
      final double updated = (currentOffset - event.localDelta.y).clamp(
        0,
        _maxVerticalScrollForGroup(group.id),
      );
      _verticalScrollOffsets[group.id] = updated;
      return;
    }

    if (_dragMode == _DragMode.horizontal) {
      double nextOffset = _horizontalOffset + event.localDelta.x;

      final bool overscrollingLeft =
          _activeIndex == _groups.length - 1 && nextOffset < 0;
      final bool overscrollingRight = _activeIndex == 0 && nextOffset > 0;
      if (overscrollingLeft || overscrollingRight) {
        nextOffset = _horizontalOffset + (event.localDelta.x * 0.42);
      }

      final double maxTravel = _cardSpacing * 1.15;
      _horizontalOffset = nextOffset.clamp(-maxTravel, maxTravel);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finishDrag();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _finishDrag();
  }

  void _finishDrag() {
    if (_groups.isEmpty) {
      _isDragging = false;
      _dragMode = _DragMode.undecided;
      _horizontalOffset = 0;
      return;
    }

    if (_dragMode == _DragMode.horizontal) {
      final double threshold = _cardSpacing * _snapThresholdFactor;
      int targetIndex = _activeIndex;
      if (_horizontalOffset <= -threshold) {
        targetIndex = (_activeIndex + 1).clamp(0, _groups.length - 1);
      } else if (_horizontalOffset >= threshold) {
        targetIndex = (_activeIndex - 1).clamp(0, _groups.length - 1);
      }

      if (targetIndex != _activeIndex) {
        _pendingSnapIndex = targetIndex;
        _snapTargetOffset = targetIndex > _activeIndex
            ? -_cardSpacing
            : _cardSpacing;
      }
    }

    _isDragging = false;
    _dragMode = _DragMode.undecided;
    _dragDelta = Vector2.zero();
  }

  void _selectCardIndex(
    int newIndex, {
    required bool animateFromTap,
    required bool notify,
  }) {
    if (_groups.isEmpty) {
      _horizontalOffset = 0;
      _pendingSnapIndex = null;
      _snapTargetOffset = 0;
      return;
    }

    newIndex = newIndex.clamp(0, _groups.length - 1);
    if (newIndex == _activeIndex) {
      return;
    }

    if (animateFromTap) {
      _pendingSnapIndex = newIndex;
      _snapTargetOffset = newIndex > _activeIndex
          ? -_cardSpacing
          : _cardSpacing;
      return;
    }

    _activeIndex = newIndex;
    if (notify) {
      onGroupChanged(_groups[newIndex].id);
    }
  }

  double get _cardWidth => size.x * _cardWidthFactor;

  double get _cardHeight => size.y * _cardHeightFactor;

  double get _cardSpacing => _cardWidth * _cardSpacingFactor;

  double get _visualFocusIndex {
    final double spacing = _cardSpacing == 0 ? 1 : _cardSpacing;
    return _activeIndex - (_horizontalOffset / spacing);
  }

  Rect _cardRectForIndex(int index, {required bool withOffset}) {
    final double centerX =
        (size.x / 2) +
        ((index - _activeIndex) * _cardSpacing) +
        (withOffset ? _horizontalOffset : 0);
    final double centerY = size.y * 0.52;

    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: _cardWidth,
      height: _cardHeight,
    );
  }

  Rect _levelsViewportRect(Rect cardRect) {
    final double horizontalPadding = math.max(12, cardRect.width * 0.04);
    final double topInset = math.max(96, cardRect.height * 0.08);
    final double bottomInset = math.max(32, cardRect.height * 0.05);
    final double width = math.max(1, cardRect.width - (horizontalPadding * 2));
    final double height = math.max(1, cardRect.height - topInset - bottomInset);

    return Rect.fromLTWH(
      cardRect.left + horizontalPadding,
      cardRect.top + topInset,
      width,
      height,
    );
  }

  double _maxVerticalScrollForGroup(int groupId) {
    final int count =
        (_sortedLevelsByGroup[groupId] ?? const <GameLevel>[]).length;
    if (count == 0) {
      return 0;
    }

    final Rect rect = _levelsViewportRect(
      _cardRectForIndex(_activeIndex, withOffset: false),
    );
    final double contentHeight = count * _levelRowHeight;
    return math.max(0, contentHeight - rect.height);
  }

  int _nearestCardIndex(double x) {
    if (_groups.isEmpty) {
      return 0;
    }

    int bestIndex = _activeIndex;
    double bestDistance = double.infinity;
    for (int index = 0; index < _groups.length; index++) {
      final Rect rect = _cardRectForIndex(index, withOffset: true);
      final double distance = (x - rect.center.dx).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 1 || size.y <= 1) {
      return;
    }

    if (_groups.isEmpty) {
      _drawCenteredLabel(
        canvas,
        text: 'No stories available yet.',
        style: const TextStyle(
          fontSize: 20,
          color: Color(0xFF1E2E45),
          fontWeight: FontWeight.w700,
        ),
      );
      return;
    }

    final List<int> visibleIndices = <int>[];
    for (int index = 0; index < _groups.length; index++) {
      final Rect baseRect = _cardRectForIndex(index, withOffset: true);
      if (baseRect.right < -40 || baseRect.left > size.x + 40) {
        continue;
      }
      visibleIndices.add(index);
    }

    final double focus = _visualFocusIndex;
    visibleIndices.sort((a, b) {
      final double da = (a - focus).abs();
      final double db = (b - focus).abs();
      return db.compareTo(da);
    });

    for (final int index in visibleIndices) {
      final Rect baseRect = _cardRectForIndex(index, withOffset: true);
      final double normalizedDistance = (index - focus).abs().clamp(0, 1.8);
      final double focusStrength = (1 - normalizedDistance).clamp(0, 1);
      final double scale = (0.82 + (focusStrength * 0.18)).clamp(0.82, 1.0);
      final double alphaFactor = (0.2 + (focusStrength * 0.8)).clamp(0.2, 1.0);
      final double depthYOffset =
          (1 - focusStrength) * (18 + (normalizedDistance * 10));
      final Rect cardRect = Rect.fromCenter(
        center: Offset(baseRect.center.dx, baseRect.center.dy + depthYOffset),
        width: baseRect.width * scale,
        height: baseRect.height * scale,
      );

      _drawGroupCard(
        canvas,
        rect: cardRect,
        group: _groups[index],
        focusStrength: focusStrength,
        alphaFactor: alphaFactor,
      );
    }

    _drawPageIndicators(canvas);
  }

  void _drawGroupCard(
    Canvas canvas, {
    required Rect rect,
    required LevelGroup group,
    required double focusStrength,
    required double alphaFactor,
  }) {
    final int alpha = (255 * alphaFactor).round();
    final double appear = Curves.easeOutCubic.transform(_introProgress);
    final Rect animatedRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * (0.95 + (appear * 0.05)),
      height: rect.height * (0.95 + (appear * 0.05)),
    );
    final RRect cardShape = RRect.fromRectAndRadius(
      animatedRect,
      const Radius.circular(8),
    );

    _reusableFillPaint
      ..shader = null
      ..colorFilter = null
      ..color = Color.fromARGB((40 * alphaFactor).round(), 60, 60, 80);
    canvas.drawRRect(cardShape.shift(const Offset(0, 4)), _reusableFillPaint);

    _reusableFillPaint
      ..shader = null
      ..color = Color.fromARGB(alpha, 255, 255, 255);
    canvas.drawRRect(cardShape, _reusableFillPaint);

    _reusableStrokePaint
      ..strokeWidth = ui.lerpDouble(1.0, 1.6, focusStrength) ?? 1.2
      ..color = Color.fromARGB((alpha * 0.25).round(), 80, 100, 130);
    canvas.drawRRect(cardShape, _reusableStrokePaint);

    final Rect headerRect = Rect.fromLTWH(
      animatedRect.left + 16,
      animatedRect.top + 16,
      animatedRect.width - 32,
      44,
    );

    _drawSingleLineText(
      canvas,
      text: group.name,
      rect: headerRect,
      style: TextStyle(
        fontSize: ui.lerpDouble(22, 26, focusStrength) ?? 24,
        color: const Color(0xFF1A2B3C),
        fontWeight: FontWeight.w800,
      ),
    );

    final Rect descriptionRect = Rect.fromLTWH(
      animatedRect.left + 16,
      animatedRect.top + 66,
      animatedRect.width - 32,
      48,
    );
    _drawParagraphText(
      canvas,
      text: group.description,
      rect: descriptionRect,
      style: TextStyle(
        fontSize: ui.lerpDouble(12.5, 14, focusStrength) ?? 13,
        color: const Color(0xFF5A6A7A),
        fontWeight: FontWeight.w500,
      ),
      maxLines: 2,
    );

    final Rect listRect = _levelsViewportRect(animatedRect);
    final RRect listShape = RRect.fromRectAndRadius(
      listRect,
      const Radius.circular(8),
    );
    _reusableFillPaint
      ..shader = null
      ..color = Color.fromARGB(alpha, 245, 247, 250);
    canvas.drawRRect(listShape, _reusableFillPaint);

    canvas.save();
    canvas.clipRRect(listShape);
    _drawLevelsList(canvas, group: group, listRect: listRect, alpha: alpha);
    canvas.restore();

    final String hint = focusStrength > 0.65
        ? 'Swipe left/right to change story'
        : 'Tap card to focus';
    _drawSingleLineText(
      canvas,
      text: hint,
      rect: Rect.fromLTWH(
        animatedRect.left + 16,
        animatedRect.bottom - 26,
        animatedRect.width - 32,
        20,
      ),
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF8899AA),
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );

    final int totalLevels =
        _totalLevelCountByGroup[group.id] ??
        (_sortedLevelsByGroup[group.id] ?? const <GameLevel>[]).length;
    final int completedLevels =
        _completedLevelCountByGroup[group.id] ??
        (_sortedLevelsByGroup[group.id] ?? const <GameLevel>[])
            .where((level) => _completedByLevelId[level.id] ?? false)
            .length;
    _drawSingleLineText(
      canvas,
      text: '$completedLevels/$totalLevels completed',
      rect: Rect.fromLTWH(
        animatedRect.right - 150,
        animatedRect.top + 28,
        134,
        18,
      ),
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF8899AA),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.right,
    );
  }

  void _drawLevelsList(
    Canvas canvas, {
    required LevelGroup group,
    required Rect listRect,
    required int alpha,
  }) {
    final List<GameLevel> levels =
        _sortedLevelsByGroup[group.id] ?? const <GameLevel>[];
    final double scrollOffset = _verticalScrollOffsets[group.id] ?? 0;

    if (levels.isEmpty) {
      _drawSingleLineText(
        canvas,
        text: 'No levels',
        rect: listRect,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      );
      return;
    }

    final int firstRow = (scrollOffset / _levelRowHeight).floor();
    final double yStart = listRect.top - (scrollOffset % _levelRowHeight);
    final int visibleRows = (listRect.height / _levelRowHeight).ceil() + 2;

    for (int i = 0; i < visibleRows; i++) {
      final int rowIndex = firstRow + i;
      if (rowIndex < 0 || rowIndex >= levels.length) {
        continue;
      }

      final GameLevel level = levels[rowIndex];
      final double top = yStart + (i * _levelRowHeight);
      final Rect rowRect = Rect.fromLTWH(
        listRect.left + 10,
        top + 10,
        listRect.width - 20,
        _levelRowHeight - 10,
      );

      final bool locked = _lockedByLevelId[level.id] ?? isLocked(level.id);
      final bool completed =
          _completedByLevelId[level.id] ?? isCompleted(level.id);
      final bool selected = _selectedLevelId == level.id;

      final Color rowColor = selected
          ? const Color(0xFFE8F0FE)
          : (locked ? const Color(0xFFF0F0F2) : const Color(0xFFFFFFFF));
      final RRect rowShape = RRect.fromRectAndRadius(
        rowRect,
        const Radius.circular(8),
      );
      _reusableFillPaint
        ..shader = null
        ..colorFilter = null
        ..color = rowColor.withAlpha(alpha);
      canvas.drawRRect(rowShape, _reusableFillPaint);
      _reusableStrokePaint
        ..strokeWidth = 1
        ..color = (selected ? const Color(0xFF4A90D9) : const Color(0xFFDDE1E6))
            .withAlpha(alpha);
      canvas.drawRRect(rowShape, _reusableStrokePaint);

      final String leading = locked ? 'LOCK' : (completed ? 'DONE' : 'PLAY');

      // Draw thumbnail
      final String thumbnailPath =
          level.thumbnailAssetPath ?? level.imageAssetPath;
      final ui.Image? thumbnail = _imageCache[thumbnailPath];
      if (thumbnail != null) {
        final Rect thumbnailRect = Rect.fromLTWH(
          rowRect.left + 10,
          rowRect.top + (rowRect.height - 70) / 2,
          60,
          70,
        );

        // Apply grayscale filter for locked levels
        if (locked) {
          canvas.drawImageRect(
            thumbnail,
            Rect.fromLTWH(
              0.0,
              0.0,
              thumbnail.width.toDouble(),
              thumbnail.height.toDouble(),
            ),
            thumbnailRect,
            _lockedThumbnailPaint,
          );
        } else {
          canvas.drawImageRect(
            thumbnail,
            Rect.fromLTWH(
              0.0,
              0.0,
              thumbnail.width.toDouble(),
              thumbnail.height.toDouble(),
            ),
            thumbnailRect,
            _plainImagePaint,
          );
        }
      } else {
        // Load thumbnail asynchronously
        _loadThumbnail(thumbnailPath);

        // Draw placeholder
        _reusableFillPaint
          ..shader = null
          ..colorFilter = null
          ..color = locked ? const Color(0xFFE0E0E0) : const Color(0xFFF0F0F0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rowRect.left + 10,
              rowRect.top + (rowRect.height - 36) / 2,
              36,
              36,
            ),
            const Radius.circular(4),
          ),
          _reusableFillPaint,
        );
      }

      // Layout constants for text columns
      final double textLeft = rowRect.left + 82;
      final double statusWidth = 48;
      final double textWidth = rowRect.width - 82 - statusWidth - 8;

      final String subtitle = level.difficulty.displaySize;
      _drawSingleLineText(
        canvas,
        text: level.name,
        rect: Rect.fromLTWH(textLeft, rowRect.top + 12, textWidth, 20),
        style: TextStyle(
          fontSize: 14,
          color: locked ? const Color(0xFF8899AA) : const Color(0xFF1A2B3C),
          fontWeight: FontWeight.w700,
        ),
      );
      _drawSingleLineText(
        canvas,
        text: subtitle,
        rect: Rect.fromLTWH(textLeft, rowRect.top + 36, textWidth, 18),
        style: TextStyle(
          fontSize: 12,
          color: locked ? const Color(0xFFAAB4BE) : const Color(0xFF5A6A7A),
          fontWeight: FontWeight.w500,
        ),
      );
      _drawSingleLineText(
        canvas,
        text: leading,
        rect: Rect.fromLTWH(
          rowRect.right - statusWidth - 4,
          rowRect.top + (rowRect.height - 18) / 2,
          statusWidth,
          18,
        ),
        style: TextStyle(
          fontSize: 11,
          color: locked
              ? const Color(0xFFAAB0B8)
              : (completed ? const Color(0xFF2E8B57) : const Color(0xFF4A90D9)),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      );
    }

    final double maxScroll = _maxVerticalScrollForGroup(group.id);
    if (maxScroll > 0.5) {
      final double thumbHeight = math.max(28, listRect.height * 0.18);
      final double trackTop = listRect.top + 6;
      final double trackHeight = listRect.height - 12;
      final double t = (scrollOffset / maxScroll).clamp(0, 1);
      final double thumbTop = trackTop + ((trackHeight - thumbHeight) * t);
      final Rect thumbRect = Rect.fromLTWH(
        listRect.right - 5,
        thumbTop,
        3,
        thumbHeight,
      );
      _reusableFillPaint
        ..shader = null
        ..colorFilter = null
        ..color = const Color(0x8876879A);
      canvas.drawRRect(
        RRect.fromRectAndRadius(thumbRect, const Radius.circular(3)),
        _reusableFillPaint,
      );
    }
  }

  void _drawPageIndicators(Canvas canvas) {
    if (_groups.length <= 1) {
      return;
    }

    final double y = size.y - 14;
    final double spacing = 13;
    final double totalWidth = ((_groups.length - 1) * spacing) + 10;
    final double startX = (size.x - totalWidth) / 2;

    for (int i = 0; i < _groups.length; i++) {
      final double t = (1 - (i - _visualFocusIndex).abs()).clamp(0, 1);
      final double radius = ui.lerpDouble(3.0, 4.4, t) ?? 3.0;
      _reusableFillPaint
        ..shader = null
        ..colorFilter = null
        ..color =
            Color.lerp(
              const ui.Color.fromARGB(102, 20, 108, 196),
              const Color(0xFF4A90D9),
              t,
            ) ??
            const Color(0x66A0B0C0);
      canvas.drawCircle(
        Offset(startX + (i * spacing), y),
        radius,
        _reusableFillPaint,
      );
    }
  }

  void _drawCenteredLabel(
    Canvas canvas, {
    required String text,
    required TextStyle style,
  }) {
    _drawSingleLineText(
      canvas,
      text: text,
      rect: Rect.fromLTWH(0, (size.y / 2) - 20, size.x, 40),
      style: style,
      textAlign: TextAlign.center,
    );
  }

  void _drawParagraphText(
    Canvas canvas, {
    required String text,
    required Rect rect,
    required TextStyle style,
    int maxLines = 2,
  }) {
    final TextPainter painter = _obtainTextPainter(
      text: text,
      style: style,
      maxWidth: rect.width,
      maxLines: maxLines,
      textAlign: TextAlign.left,
    );

    painter.paint(canvas, Offset(rect.left, rect.top));
  }

  void _drawSingleLineText(
    Canvas canvas, {
    required String text,
    required Rect rect,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
  }) {
    final TextPainter painter = _obtainTextPainter(
      text: text,
      style: style,
      maxWidth: rect.width,
      maxLines: 1,
      textAlign: textAlign,
    );

    final double dx;
    switch (textAlign) {
      case TextAlign.center:
        dx = rect.left + ((rect.width - painter.width) / 2);
        break;
      case TextAlign.right:
      case TextAlign.end:
        dx = rect.right - painter.width;
        break;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        dx = rect.left;
        break;
    }

    painter.paint(canvas, Offset(dx, rect.top));
  }

  TextPainter _obtainTextPainter({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int maxLines,
    required TextAlign textAlign,
  }) {
    final double normalizedWidth = math.max(1, maxWidth);
    final String key = _textPainterKey(
      text: text,
      style: style,
      maxWidth: normalizedWidth,
      maxLines: maxLines,
      textAlign: textAlign,
    );
    final TextPainter? cached = _textPainterCache[key];
    if (cached != null) {
      return cached;
    }

    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '...',
      textAlign: textAlign,
    )..layout(maxWidth: normalizedWidth);

    if (_textPainterCache.length >= _maxTextPainterCacheEntries) {
      _textPainterCache.clear();
    }
    _textPainterCache[key] = painter;
    return painter;
  }

  String _textPainterKey({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int maxLines,
    required TextAlign textAlign,
  }) {
    return '$text|${maxWidth.round()}|$maxLines|${textAlign.index}|'
        '${style.fontSize?.toStringAsFixed(2) ?? ''}|${style.fontWeight?.value ?? 0}|'
        '${style.letterSpacing?.toStringAsFixed(2) ?? ''}|${style.height?.toStringAsFixed(2) ?? ''}|'
        '${style.color?.toARGB32() ?? 0}|${style.fontStyle?.index ?? 0}';
  }

  Future<ui.Image?> _loadThumbnail(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath];
    }

    final Future<ui.Image?>? pending = _thumbnailLoadFutures[assetPath];
    if (pending != null) {
      return pending;
    }

    final Future<ui.Image?> loadFuture = () async {
      try {
        final ByteData data = await rootBundle.load(assetPath);
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: _thumbnailDecodeWidth,
          targetHeight: _thumbnailDecodeHeight,
        );

        try {
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          final ui.Image image = frameInfo.image;
          _imageCache[assetPath] = image;
          return image;
        } finally {
          codec.dispose();
        }
      } catch (e) {
        _log.warning('Failed to load thumbnail: $assetPath', e);
        return null;
      } finally {
        _thumbnailLoadFutures.remove(assetPath);
      }
    }();

    _thumbnailLoadFutures[assetPath] = loadFuture;
    return loadFuture;
  }
}
