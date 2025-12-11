import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route, BackButton;
import 'package:tilerush/main.dart';
import 'common_widgets.dart';

class GamePage extends DecoratedWorld with HasGameReference<RouterGame> {
  static const int initialSeconds = 5;
  double remaining = initialSeconds.toDouble();
  bool timerRunning = false;

  late final TextComponent timerText;
  late final TextComponent scoreText;
  final double topPadding = 8.0;

  static const int boardSizeConst = 8;
  late BoardComponent board;
  final List<BlockPreview> previews = [];
  final Random rng = Random();
  int score = 0;
  int comboMultiplier = 1;

  int? selectedPreviewIndex;

  final hudComponents = <Component>[];

  bool previewsInitialized = false;

  // Drag & Drop
  int? draggingPreviewIndex;
  DragGhost? dragGhost;
  Vector2? currentPointerViewport;

  @override
  Future<void> onLoad() async {
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );

    timerText = TextComponent(
      text: formatTime(remaining),
      textRenderer: textPaint,
      anchor: Anchor.topCenter,
    );

    scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer: textPaint,
      anchor: Anchor.topRight,
    );

    add(Background(const Color(0xbb2a074f)));
  }

  String formatTime(double seconds) {
    final s = seconds.clamp(0, double.infinity).ceil();
    final min = s ~/ 60;
    final sec = s % 60;
    final mm = min.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void updateTimerPosition(Vector2 gameSize) {
    timerText.position = Vector2(gameSize.x / 2, topPadding);
    scoreText.position = Vector2(gameSize.x - 16.0, topPadding);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.size != Vector2.zero()) updateTimerPosition(game.size);

    if (!timerRunning) return;

    remaining -= dt;
    if (remaining <= 0) {
      remaining = 0;
      if (dragGhost != null) {
        try {
          dragGhost!.removeFromParent();
        } catch (_) {}
        dragGhost = null;
      }
      draggingPreviewIndex = null;
      currentPointerViewport = null;
      selectedPreviewIndex = null;
      for (final p in previews) {
        p.selected = false;
      }
      timerRunning = false;
      game.lastScore = score;
      selectedPreviewIndex = null;
      game.router.pushNamed('game_over');
    }

    timerText.text = formatTime(remaining);
    scoreText.text = 'Score: $score';

    if (draggingPreviewIndex != null &&
        dragGhost != null &&
        currentPointerViewport != null) {
      _updateDragGhost(currentPointerViewport!);
    }
  }

  @override
  void onMount() {
    super.onMount();
    resetGameState();
    remaining = initialSeconds.toDouble();
    timerRunning = true;

    if (!game.camera.viewport.children.contains(timerText)) {
      game.camera.viewport.add(timerText);
    }
    if (!game.camera.viewport.children.contains(scoreText)) {
      game.camera.viewport.add(scoreText);
    }
    hudComponents.addAll([BackButton(), PauseButton()]);
    game.camera.viewport.addAll(hudComponents);

    board = BoardComponent(
      boardSize: boardSizeConst,
      margin: 16,
      onLinesCleared: handleLinesCleared,
    );
    game.camera.viewport.add(board);

    for (int i = 0; i < 3; i++) {
      final p = BlockPreview(index: i);
      previews.add(p);
      game.camera.viewport.add(p);
    }

    board.onLayoutReady = () {
      layoutPreviews();
      if (!previewsInitialized) {
        for (final p in previews) {
          p.resetToNewShape(createRandomShape());
        }
        previewsInitialized = true;
      }
    };

    if (game.size != Vector2.zero()) {
      board.onGameResize(game.size);
    }
  }

  void layoutPreviews() {
    final boardLocalW = board.localRect.width;
    final boardLocalH = board.localRect.height;
    final spacing = 10.0;
    final horizontalPadding = 10.0;
    final usableWidth = max(0.0, boardLocalW - 2 * horizontalPadding);
    double computedPreviewWidth = (usableWidth - spacing * 2) / 3.0;

    final maxPreviewSize = game.size.y * 0.14;
    computedPreviewWidth = min(computedPreviewWidth, maxPreviewSize);
    if (computedPreviewWidth <= 0) {
      computedPreviewWidth = min(boardLocalW / 3.0, maxPreviewSize);
    }

    double previewWidth;
    if (previewsInitialized &&
        previews.isNotEmpty &&
        previews.first.previewArea != Rect.zero) {
      final current = previews.first.previewArea.width;
      if (computedPreviewWidth > current) {
        previewWidth = min(computedPreviewWidth, maxPreviewSize);
      } else {
        if (computedPreviewWidth < current * 0.85) {
          previewWidth = computedPreviewWidth;
        } else {
          previewWidth = current;
        }
        previewWidth = min(previewWidth, maxPreviewSize);
      }
    } else {
      previewWidth = computedPreviewWidth;
    }

    if (previewWidth <= 0) previewWidth = max(24.0, computedPreviewWidth);

    final totalPreviewBlockWidth = previewWidth * 3 + spacing * 2;
    final leftStartLocal = (boardLocalW - totalPreviewBlockWidth) / 2;

    final previewTopLocal = boardLocalH + 8.0;

    for (int i = 0; i < previews.length; i++) {
      final xLocal = leftStartLocal + i * (previewWidth + spacing);
      final posX = board.position.x + xLocal;
      final posY = board.position.y + previewTopLocal;
      previews[i].setViewportPreviewArea(
        Rect.fromLTWH(posX, posY, previewWidth, previewWidth),
      );
    }

    final boardGlobalBottom =
        board.position.y + previewTopLocal + previewWidth + 12.0;
    if (boardGlobalBottom > game.size.y) {
      final overflow = boardGlobalBottom - game.size.y;
      final shiftUp = max(24.0, overflow + 8.0);
      final newY = max(48.0, board.position.y - shiftUp);
      board.position = Vector2(board.position.x, newY);

      for (int i = 0; i < previews.length; i++) {
        final xLocal = leftStartLocal + i * (previewWidth + spacing);
        final posX = board.position.x + xLocal;
        final posY = board.position.y + previewTopLocal;
        previews[i].setViewportPreviewArea(
          Rect.fromLTWH(posX, posY, previewWidth, previewWidth),
        );
      }

      final boardGlobalBottomAfter =
          board.position.y + previewTopLocal + previewWidth + 12.0;
      if (boardGlobalBottomAfter > game.size.y) {
        final still = boardGlobalBottomAfter - game.size.y;
        if (!previewsInitialized) {
          board.reduceSizeByPixels(still + 8.0);
          return;
        } else {
          final shrinkBy = still + 8.0;
          double newPreviewWidth = max(16.0, previewWidth - shrinkBy);
          final newTotalPreviewBlockWidth = newPreviewWidth * 3 + spacing * 2;
          final newLeftStartLocal =
              (board.localRect.width - newTotalPreviewBlockWidth) / 2;
          for (int i = 0; i < previews.length; i++) {
            final xLocal = newLeftStartLocal + i * (newPreviewWidth + spacing);
            final posX = board.position.x + xLocal;
            final posY = board.position.y + previewTopLocal;
            previews[i].setViewportPreviewArea(
              Rect.fromLTWH(posX, posY, newPreviewWidth, newPreviewWidth),
            );
          }
        }
      }
    }
  }

  BlockShape createRandomShape() {
    final base = BlockShape.shapes[rng.nextInt(BlockShape.shapes.length)];
    final color = BlockShape.colors[rng.nextInt(BlockShape.colors.length)];
    return BlockShape(base, color);
  }

  void selectPreview(int index) {
    if (index < 0 || index >= previews.length) return;
    if (previews[index].isEmpty) {
      selectedPreviewIndex = null;
      return;
    }
    selectedPreviewIndex = index;
    for (int i = 0; i < previews.length; i++) {
      previews[i].selected = (i == index);
    }
  }

  void spawnReplacementPreviews() {
    for (final p in previews) {
      if (p.isEmpty) p.resetToNewShape(createRandomShape());
    }
  }

  void handleLinesCleared(int cellsCleared, int linesCleared) {
    final base = cellsCleared;
    final bonus = linesCleared * 8 * comboMultiplier;
    score += base + bonus;
    if (linesCleared > 0) {
      comboMultiplier += 1;
    } else {
      comboMultiplier = 1;
    }
  }

  bool anyMoveAvailable() {
    for (final p in previews) {
      if (!p.isEmpty && board.anyPlacementPossible(p.currentShape!)) {
        return true;
      }
    }
    return false;
  }

  void resetGameState() {
    score = 0;
    comboMultiplier = 1;
    selectedPreviewIndex = null;
    remaining = initialSeconds.toDouble();
    timerRunning = true;

    for (final p in previews) {
      p.consume();
    }
    previews.clear();

    previewsInitialized = false;
    try {
      board.clearBoard();
    } catch (_) {}
  }

  @override
  void onRemove() {
    try {
      game.camera.viewport.removeAll(hudComponents);
    } catch (_) {}
    try {
      game.camera.viewport.remove(timerText);
    } catch (_) {}
    try {
      game.camera.viewport.remove(scoreText);
    } catch (_) {}

    try {
      for (final p in previews) {
        game.camera.viewport.remove(p);
      }
    } catch (_) {}

    try {
      game.camera.viewport.remove(board);
    } catch (_) {}

    if (dragGhost != null) {
      try {
        dragGhost!.removeFromParent();
      } catch (_) {}
      dragGhost = null;
    }

    try {
      final vpChildren = List<Component>.from(game.camera.viewport.children);
      for (final vc in vpChildren) {
        final typeName = vc.runtimeType.toString().toLowerCase();
        if (vc is BoardComponent ||
            typeName.contains('board') ||
            typeName.contains('blockpreview') ||
            typeName.contains('backbutton') ||
            typeName.contains('pausebutton') ||
            typeName.contains('timer') ||
            typeName.contains('score') ||
            typeName.contains('dragghost')) {
          vc.removeFromParent();
        }
      }
    } catch (_) {}

    timerRunning = false;
    super.onRemove();
  }

  void onDragStart(Vector2 widgetPoint) {
    final resolved = _resolveViewportPoint(widgetPoint);
    if (resolved == null) return;
    currentPointerViewport = resolved;

    for (int i = 0; i < previews.length; i++) {
      final p = previews[i];
      if (p.previewArea != Rect.zero &&
          p.previewArea.contains(Offset(resolved.x, resolved.y))) {
        if (p.isEmpty) return;
        draggingPreviewIndex = i;
        selectPreview(i);
        dragGhost = DragGhost(shape: p.currentShape!, board: board);
        dragGhost!
          ..position = Vector2.zero()
          ..size = Vector2(game.size.x, game.size.y);
        game.camera.viewport.add(dragGhost!);

        _updateDragGhost(resolved);
        return;
      }
    }
  }

  void onDragUpdate(Vector2 widgetPoint) {
    final resolved = _resolveViewportPoint(widgetPoint);
    if (resolved == null) return;
    currentPointerViewport = resolved;

    if (draggingPreviewIndex == null || dragGhost == null) return;

    _updateDragGhost(resolved);
  }

  void onDragEnd(Vector2 widgetPoint) {
    final resolved = _resolveViewportPoint(widgetPoint);
    if (resolved != null) currentPointerViewport = resolved;

    if (draggingPreviewIndex == null || dragGhost == null) {
      draggingPreviewIndex = null;
      currentPointerViewport = null;
      selectedPreviewIndex = null;
      for (final p in previews) {
        p.selected = false;
      }
      return;
    }

    if (dragGhost!.onBoard &&
        dragGhost!.validPlacement &&
        dragGhost!.snapGrid != null) {
      final grid = dragGhost!.snapGrid!;
      final preview = previews[draggingPreviewIndex!];
      final shape = preview.currentShape;
      if (shape != null &&
          board.canPlace(shape, grid.x.toInt(), grid.y.toInt())) {
        board.place(shape, grid.x.toInt(), grid.y.toInt());
        preview.consume();
        spawnReplacementPreviews();

        if (!anyMoveAvailable()) {
          game.lastScore = score;
          selectedPreviewIndex = null;
          game.router.pushNamed('game_over');
        }
      }
    }

    if (dragGhost != null) {
      try {
        dragGhost!.removeFromParent();
      } catch (_) {}
    }
    dragGhost = null;
    draggingPreviewIndex = null;
    currentPointerViewport = null;

    selectedPreviewIndex = null;
    for (final p in previews) {
      p.selected = false;
    }
  }

  Vector2? _resolveViewportPoint(Vector2 widgetPoint) {
    try {
      if (widgetPoint.x >= 0 &&
          widgetPoint.y >= 0 &&
          widgetPoint.x <= game.size.x + 1 &&
          widgetPoint.y <= game.size.y + 1) {
        return widgetPoint;
      }

      final v = game.camera.globalToLocal(widgetPoint);
      if (v.x >= 0 &&
          v.y >= 0 &&
          v.x <= game.size.x + 1 &&
          v.y <= game.size.y + 1) {
        return v;
      }
    } catch (_) {}

    return widgetPoint;
  }

  void _updateDragGhost(Vector2 pointForHit) {
    if (dragGhost == null) return;

    // inside board area
    if (board.boardRect != Rect.zero &&
        board.boardRect.contains(Offset(pointForHit.x, pointForHit.y))) {
      final g = board.pixelToGrid(pointForHit);
      final gx = g.x.toInt();
      final gy = g.y.toInt();
      final preview = previews[draggingPreviewIndex!];
      final shape = preview.currentShape;
      if (shape != null) {
        final valid = board.canPlace(shape, gx, gy);
        dragGhost!
          ..onBoard = true
          ..validPlacement = valid
          ..snapGrid = Vector2(gx.toDouble(), gy.toDouble())
          ..topLeft = Vector2(
            board.absolutePosition.x + gx * board.cellSize,
            board.absolutePosition.y + gy * board.cellSize,
          )
          ..cellSize = board.cellSize;
      }
    }
    // outside board area
    else {
      final previewRectSize =
          (previews.isNotEmpty && previews.first.previewArea != Rect.zero)
          ? previews.first.previewArea.width
          : 48.0;
      final topLeft = Vector2(
        pointForHit.x - previewRectSize / 2,
        pointForHit.y - previewRectSize / 2,
      );
      final cellSize = (previewRectSize / (BlockPreview._canonicalGrid));
      dragGhost!
        ..onBoard = false
        ..validPlacement = false
        ..snapGrid = null
        ..topLeft = topLeft
        ..cellSize = cellSize;
    }
  }
}

class BoardComponent extends PositionComponent {
  final int boardSize;
  final double margin;
  late double cellSize;
  late Rect localRect;
  late List<List<Color?>> occupied;
  VoidCallback? onLayoutReady;
  final void Function(int, int) onLinesCleared;
  static const double hudReserve = 56.0;

  BoardComponent({
    required this.boardSize,
    required this.margin,
    required this.onLinesCleared,
  });

  Rect get boardRect => Rect.fromLTWH(
    absolutePosition.x,
    absolutePosition.y,
    localRect.width,
    localRect.height,
  );

  @override
  Future<void> onLoad() async {
    occupied = List.generate(
      boardSize,
      (_) => List.generate(boardSize, (_) => null),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final previewReservedHeight = max(100.0, size.y * 0.16);
    final maxWidth = max(0.0, size.x - margin * 2);
    final availableHeightForBoard = max(
      0.0,
      size.y - margin * 2 - previewReservedHeight - hudReserve,
    );
    double boardPixelSize = min(maxWidth, availableHeightForBoard);
    if (boardPixelSize <= 0) {
      boardPixelSize = max(64.0, size.x * 0.6);
    }

    final left = (size.x - boardPixelSize) / 2;
    final totalUsedHeight = boardPixelSize + previewReservedHeight;
    final double desiredTop = (size.y - totalUsedHeight) / 2;
    final double minTop = margin + hudReserve;
    final double maxTopCandidate =
        size.y - boardPixelSize - previewReservedHeight - margin;
    final double maxTop = max(minTop, maxTopCandidate);
    final double desiredLeft = left;
    final double minLeft = margin;
    final double maxLeftCandidate = size.x - boardPixelSize - margin;
    final double maxLeft = max(minLeft, maxLeftCandidate);

    final clampedLeft = desiredLeft.clamp(minLeft, maxLeft);
    final clampedTop = desiredTop.clamp(minTop, maxTop);

    position = Vector2(clampedLeft.toDouble(), clampedTop.toDouble());
    size = Vector2(boardPixelSize, boardPixelSize);
    localRect = Rect.fromLTWH(0, 0, boardPixelSize, boardPixelSize);
    cellSize = boardPixelSize / boardSize;

    onLayoutReady?.call();
  }

  void reduceSizeByPixels(double px) {
    final newSize = max(64.0, size.x - px);
    size = Vector2(newSize, newSize);
    localRect = Rect.fromLTWH(0, 0, newSize, newSize);
    cellSize = newSize / boardSize;
    onLayoutReady?.call();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xff2b2b2b);
    canvas.drawRect(localRect, paint);

    final gridPaint = Paint()
      ..color = const Color(0xff444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int r = 0; r < boardSize; r++) {
      for (int cIdx = 0; cIdx < boardSize; cIdx++) {
        final cellRect = Rect.fromLTWH(
          cIdx * cellSize,
          r * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(cellRect, gridPaint);
        final cellColor = occupied[r][cIdx];
        if (cellColor != null) {
          final fill = Paint()..color = cellColor;
          canvas.drawRect(cellRect.deflate(2.0), fill);
        }
      }
    }
  }

  Vector2 pixelToGrid(Vector2 worldPos) {
    final localX = worldPos.x - absolutePosition.x;
    final localY = worldPos.y - absolutePosition.y;
    final gx = (localX / cellSize).floor().clamp(0, boardSize - 1);
    final gy = (localY / cellSize).floor().clamp(0, boardSize - 1);
    return Vector2(gx.toDouble(), gy.toDouble());
  }

  Vector2 gridToCellCenter(int gridX, int gridY) {
    final cx = absolutePosition.x + gridX * cellSize + cellSize / 2;
    final cy = absolutePosition.y + gridY * cellSize + cellSize / 2;
    return Vector2(cx, cy);
  }

  bool canPlace(BlockShape shape, int gridX, int gridY) {
    for (final p in shape.cells) {
      final x = gridX + p.x;
      final y = gridY + p.y;
      if (x < 0 || x >= boardSize || y < 0 || y >= boardSize) return false;
      if (occupied[y][x] != null) return false;
    }
    return true;
  }

  void place(BlockShape shape, int gridX, int gridY) {
    int cellsPlaced = 0;
    for (final p in shape.cells) {
      final x = gridX + p.x;
      final y = gridY + p.y;
      if (x >= 0 && x < boardSize && y >= 0 && y < boardSize) {
        if (occupied[y][x] == null) {
          occupied[y][x] = shape.color;
          cellsPlaced++;
        }
      }
    }

    final rowsToClear = <int>[];
    final colsToClear = <int>[];

    for (int r = 0; r < boardSize; r++) {
      if (occupied[r].every((e) => e != null)) rowsToClear.add(r);
    }
    for (int c = 0; c < boardSize; c++) {
      bool full = true;
      for (int r = 0; r < boardSize; r++) {
        if (occupied[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) colsToClear.add(c);
    }

    for (final r in rowsToClear) {
      for (int c = 0; c < boardSize; c++) {
        occupied[r][c] = null;
      }
    }
    for (final c in colsToClear) {
      for (int r = 0; r < boardSize; r++) {
        occupied[r][c] = null;
      }
    }

    final totalCleared = rowsToClear.length + colsToClear.length;
    onLinesCleared(cellsPlaced, totalCleared);
  }

  bool anyPlacementPossible(BlockShape shape) {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (canPlace(shape, c, r)) return true;
      }
    }
    return false;
  }

  void clearBoard() {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        occupied[r][c] = null;
      }
    }
  }
}

class BlockShape {
  final List<Point<int>> cells;
  final Color color;
  BlockShape(this.cells, this.color);

  static final List<Color> colors = [
    const Color(0xffFF6B6B),
    const Color(0xff6BCB77),
    const Color(0xff4D96FF),
    const Color(0xffFFD166),
    const Color(0xff845EC2),
  ];

  static final List<List<Point<int>>> shapes = [
    [Point(0, 0)], // single
    [Point(0, 0), Point(1, 0)], // two horizontal
    [Point(0, 0), Point(0, 1)], // two vertical
    [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)], // 2x2
    [Point(0, 0), Point(1, 0), Point(2, 0)], // 3 horizontal
    [Point(0, 0), Point(0, 1), Point(0, 2)], // 3 vertical
    [Point(0, 0), Point(1, 0), Point(2, 0), Point(1, 1)], // T-ish
    [Point(0, 0), Point(1, 0), Point(1, 1)], // small L
    [Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0)], // 4 horizontal
  ];
}

class BlockPreview extends PositionComponent {
  final int index;

  Rect previewArea = Rect.zero;
  BlockShape? currentShape;
  bool isEmpty = true;
  bool selected = false;

  BlockPreview({required this.index});

  static final int _canonicalGrid = _computeCanonicalGrid();

  static int _computeCanonicalGrid() {
    int maxSpan = 1;
    for (final shape in BlockShape.shapes) {
      int minX = shape.first.x, maxX = shape.first.x;
      int minY = shape.first.y, maxY = shape.first.y;
      for (final p in shape) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      final cols = maxX - minX + 1;
      final rows = maxY - minY + 1;
      maxSpan = max(maxSpan, max(cols, rows));
    }
    return maxSpan;
  }

  void setViewportPreviewArea(Rect rect) {
    previewArea = rect;
    position = Vector2(rect.left, rect.top);
    size = Vector2(rect.width, rect.height);
  }

  void resetToNewShape(BlockShape shape) {
    currentShape = shape;
    isEmpty = false;
  }

  void consume() {
    currentShape = null;
    isEmpty = true;
  }

  @override
  void render(Canvas canvas) {
    if (previewArea == Rect.zero) return;

    final w = previewArea.width;
    final h = previewArea.height;
    final double highlightSize = min(w, h) * 0.9;
    final double highlightLeft = (w - highlightSize) / 2;
    final double highlightTop = (h - highlightSize) / 2;
    final Rect contentRect = Rect.fromLTWH(
      highlightLeft,
      highlightTop,
      highlightSize,
      highlightSize,
    );

    if (selected) {
      final selPaint = Paint()..color = Colors.white.withValues(alpha: 0.12);
      canvas.drawRect(contentRect, selPaint);
      final border = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(contentRect.deflate(1.0), border);
    }

    if (currentShape != null) {
      final shape = currentShape!;
      int minX = shape.cells.first.x;
      int maxX = shape.cells.first.x;
      int minY = shape.cells.first.y;
      int maxY = shape.cells.first.y;
      for (final p in shape.cells) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      final int cols = maxX - minX + 1;
      final int rows = maxY - minY + 1;
      final double padding = contentRect.width * 0.08;
      final double avail = contentRect.width - 2 * padding;
      final double cellSize = avail / _canonicalGrid;
      final double startX =
          contentRect.left + (contentRect.width - (cellSize * cols)) / 2;
      final double startY =
          contentRect.top + (contentRect.height - (cellSize * rows)) / 2;

      final fill = Paint()..color = shape.color;
      for (final p in shape.cells) {
        final rx = startX + (p.x - minX) * cellSize;
        final ry = startY + (p.y - minY) * cellSize;
        final rect = Rect.fromLTWH(rx, ry, cellSize * 0.9, cellSize * 0.9);
        canvas.drawRect(rect, fill);
      }
    } else {
      final txt = TextPainter(
        text: const TextSpan(
          text: 'EMPTY',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = contentRect.left + (contentRect.width - txt.width) / 2;
      final dy = contentRect.top + (contentRect.height - txt.height) / 2;
      txt.paint(canvas, Offset(dx, dy));
    }
  }
}

class DragGhost extends PositionComponent {
  BlockShape shape;
  BoardComponent board;
  Vector2 topLeft = Vector2.zero();
  double cellSize = 16.0;
  bool onBoard = false;
  bool validPlacement = false;
  Vector2? snapGrid;

  DragGhost({required this.shape, required this.board});

  @override
  void render(Canvas canvas) {
    for (final p in shape.cells) {
      final rx = topLeft.x + p.x * cellSize;
      final ry = topLeft.y + p.y * cellSize;
      final rect = Rect.fromLTWH(rx, ry, cellSize * 0.9, cellSize * 0.9);
      final paint = Paint()
        ..color = shape.color.withValues(
          alpha: onBoard ? (validPlacement ? 0.9 : 0.35) : 0.75,
        );
      canvas.drawRect(rect, paint);
      if (onBoard && !validPlacement) {
        final border = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.red.withValues(alpha: 0.9);
        canvas.drawRect(rect.deflate(1.0), border);
      } else if (onBoard && validPlacement) {
        final border = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.08);
        canvas.drawRect(rect.deflate(1.0), border);
      }
    }
  }
}
