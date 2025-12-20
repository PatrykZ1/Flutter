import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'shapes.dart';
import 'clear_animations.dart';

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

    // Collect unique cells to clear (avoid double-clearing intersections twice)
    final cellsToClear = <Point<int>>{};

    for (final r in rowsToClear) {
      for (int c = 0; c < boardSize; c++) {
        cellsToClear.add(Point(c, r));
      }
    }
    for (final c in colsToClear) {
      for (int r = 0; r < boardSize; r++) {
        cellsToClear.add(Point(c, r));
      }
    }

    // For each cell: capture color, set occupied to null for game logic, spawn visual effect
    for (final pt in cellsToClear) {
      final x = pt.x;
      final y = pt.y;
      final cellColor = occupied[y][x];
      if (cellColor == null) continue; // skip if already empty

      // set to null so game logic sees cleared board immediately
      occupied[y][x] = null;

      // spawn clear effect as a child of the board so it draws in board-local coords
      final localTopLeft = Vector2(x * cellSize, y * cellSize);
      final effect = ClearCellEffect(
        baseColor: cellColor,
        localTopLeft: localTopLeft,
        cellSize: cellSize,
        duration: 0.65,
        scaleAmount: 0.16,
        hueShiftSpeed: 420.0,
      );

      add(effect);
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
