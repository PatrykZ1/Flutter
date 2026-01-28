import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ClearCellEffect extends PositionComponent {
  final Color baseColor;
  final double cellSize;
  final double duration; // seconds
  final double scaleAmount;
  final double hueShiftSpeed; // degrees per second

  double _elapsed = 0;
  final double _hueOffset;

  ClearCellEffect({
    required this.baseColor,
    required Vector2 localTopLeft, // local coords inside BoardComponent
    required this.cellSize,
    this.duration = 0.6,
    this.scaleAmount = 0.18,
    this.hueShiftSpeed = 420.0, // how fast the rainbow cycles
  }) : _hueOffset = Random().nextDouble() * 360.0,
       super(position: localTopLeft, size: Vector2(cellSize, cellSize));

  bool get shouldRemove => _elapsed >= duration;

  static double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  static double _easeInQuad(double t) => t * t;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final prog = (_elapsed / duration).clamp(0.0, 1.0);
    final scale = 1.0 + scaleAmount * _easeOutCubic(prog);
    final opacity = (1.0 - _easeInQuad(prog)).clamp(0.0, 1.0);

    // base rectangle
    final cx = size.x / 2;
    final cy = size.y / 2;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale, scale);

    // base color with fading alpha
    final basePaint = Paint()
      ..color = baseColor.withAlpha((opacity * 255).toInt())
      ..style = PaintingStyle.fill;
    final halfW = size.x / 2;
    final halfH = size.y / 2;
    final rect = Rect.fromLTWH(-halfW, -halfH, size.x, size.y);
    canvas.drawRect(rect, basePaint);

    // compute dynamic hue
    final hue = (_hueOffset + prog * hueShiftSpeed) % 360;
    final hsv = HSVColor.fromAHSV(opacity * 0.85, hue, 0.95, 0.95);
    final overlay = Paint()
      ..color = hsv.toColor()
      ..blendMode = BlendMode.plus;

    // colorful edge
    final inset = size.x * 0.08;
    final rectOverlay = rect.deflate(inset);
    canvas.drawRect(rectOverlay, overlay);

    // soft border that also fades
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, size.x * 0.06)
      ..color = Colors.white.withAlpha((opacity * 0.18 * 255).toInt());
    canvas.drawRect(rect.deflate(size.x * 0.03), borderPaint);

    canvas.restore();
  }
}
