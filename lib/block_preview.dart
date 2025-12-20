import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route, BackButton;
import 'shapes.dart';

class BlockPreview extends PositionComponent {
  final int index;

  Rect previewArea = Rect.zero;
  BlockShape? currentShape;
  bool isEmpty = true;
  bool selected = false;

  BlockPreview({required this.index});

  static final int canonicalGrid = _computeCanonicalGrid();

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
      final double cellSize = avail / canonicalGrid;
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
      )..layout();
      final dx = contentRect.left + (contentRect.width - txt.width) / 2;
      final dy = contentRect.top + (contentRect.height - txt.height) / 2;
      txt.paint(canvas, Offset(dx, dy));
    }
  }
}
