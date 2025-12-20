import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route, BackButton;
import 'shapes.dart';
import 'board_component.dart';

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
