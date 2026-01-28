import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route, BackButton;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilerush/main.dart';
import 'common_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'board_component.dart';
import 'block_preview.dart';
import 'drag_ghost.dart';
import 'shapes.dart';

class GamePage extends DecoratedWorld with HasGameReference<RouterGame> {
  static const int initialSeconds = 3;
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
      text: '${'score'.tr()}: 0',
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
  Future<void> update(double dt) async {
    super.update(dt);
    if (game.size != Vector2.zero()) updateTimerPosition(game.size);

    if (!timerRunning) return;

    remaining -= dt;
    if (remaining <= 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('bestScore', max(score, prefs.getInt('bestScore') ?? 0));
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
    scoreText.text = '${'score'.tr()}: $score';

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

  // needed for intenationalization changes
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

  Future<void> onDragEnd(Vector2 widgetPoint) async {
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
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setInt('bestScore', max(score, prefs.getInt('bestScore') ?? 0));
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
      final cellSize = (previewRectSize / (BlockPreview.canonicalGrid));
      dragGhost!
        ..onBoard = false
        ..validPlacement = false
        ..snapGrid = null
        ..topLeft = topLeft
        ..cellSize = cellSize;
    }
  }
}
