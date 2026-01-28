import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route, BackButton;
import 'common_widgets.dart';
import 'shapes.dart';
import 'package:flame/extensions.dart';

class SettingsPage extends DecoratedWorld with HasGameReference {
  BlockSpawner? _spawner;

  @override
  Future<void> onLoad() async {
    addAll([Background(const Color(0xff052b44))]);
  }

  final hudComponents = <Component>[];

  @override
  void onMount() {
    if (!game.overlays.isActive('SettingsOverlay')) {
      game.overlays.add('SettingsOverlay');
    }

    if (children.whereType<BlockSpawner>().isEmpty) {
      _spawner = BlockSpawner();
      add(_spawner!);
    }

    super.onMount();
  }

  @override
  void onRemove() {
    if (game.overlays.isActive('SettingsOverlay')) {
      game.overlays.remove('SettingsOverlay');
    }

    _spawner?.removeFromParent();
    _spawner = null;

    children.whereType<FallingBlock>().forEach((c) => c.removeFromParent());

    game.camera.viewport.removeAll(hudComponents);
    super.onRemove();
  }
}

class FallingBlock extends Component with HasGameReference {
  final BlockShape shape;
  final double cellSize;
  Vector2 position;
  late final Vector2 size;
  double angle;
  final double angularVelocity;
  final double fallSpeed;
  final Paint _paint = Paint();

  late final int minX, minY, maxX, maxY;
  late final int widthCells, heightCells;

  double _age = 0.0;
  final double maxLifetime = 30.0;

  FallingBlock({
    required this.shape,
    required this.position,
    this.cellSize = 20.0,
    required this.fallSpeed,
    required this.angularVelocity,
    double initialAngle = 0.0,
  }) : angle = initialAngle {
    minX = shape.cells.map((p) => p.x).reduce(min);
    minY = shape.cells.map((p) => p.y).reduce(min);
    maxX = shape.cells.map((p) => p.x).reduce(max);
    maxY = shape.cells.map((p) => p.y).reduce(max);
    widthCells = maxX - minX + 1;
    heightCells = maxY - minY + 1;
    size = Vector2(widthCells * cellSize, heightCells * cellSize);
  }

  @override
  void update(double dt) {
    _age += dt;
    position = position + Vector2(0, fallSpeed * dt);
    angle += angularVelocity * dt;

    final visible = game.camera.visibleWorldRect;
    final bottom = visible.bottom;
    if (_age > maxLifetime || position.y - size.y > bottom + 50) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    final cx = position.x + size.x / 2;
    final cy = position.y + size.y / 2;
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final offsetX = -size.x / 2;
    final offsetY = -size.y / 2;

    for (final p in shape.cells) {
      final cellX = (p.x - minX) * cellSize + offsetX;
      final cellY = (p.y - minY) * cellSize + offsetY;
      final rect = Rect.fromLTWH(cellX, cellY, cellSize * 0.9, cellSize * 0.9);
      _paint.color = shape.color;
      canvas.drawRect(rect, _paint);

      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.black.withAlpha(100);
      canvas.drawRect(rect.deflate(0.5), border);
    }

    canvas.restore();
  }
}

class BlockSpawner extends Component with HasGameReference {
  final Random _rnd = Random();
  double _acc = 0.0;
  double _nextSpawn = 0.8;

  final double baseCellSize = 18.0;
  final double minFallSpeed = 18.0;
  final double maxFallSpeed = 45.0;
  final double maxAngularVel = pi / 6;
  final double minAngularVel = -pi / 6;

  @override
  void update(double dt) {
    _acc += dt;
    if (_acc >= _nextSpawn) {
      _acc = 0.0;
      _spawnOnce();
      _nextSpawn = 0.6 + _rnd.nextDouble() * 1.4;
    }
  }

  void _spawnOnce() {
    final si = _rnd.nextInt(BlockShape.shapes.length);
    final cells = BlockShape.shapes[si];
    final color = BlockShape.colors[_rnd.nextInt(BlockShape.colors.length)];
    final shape = BlockShape(cells, color);

    final visible = game.camera.visibleWorldRect;
    final screenW = visible.width;
    final screenH = visible.height;

    if (screenW <= 0 || screenH <= 0) {
      _nextSpawn = 0.1;
      return;
    }

    final minX = shape.cells.map((p) => p.x).reduce(min);
    final maxX = shape.cells.map((p) => p.x).reduce(max);
    final minY = shape.cells.map((p) => p.y).reduce(min);
    final maxY = shape.cells.map((p) => p.y).reduce(max);

    final widthCells = maxX - minX + 1;
    final heightCells = maxY - minY + 1;

    final blockPixelWidth = widthCells * baseCellSize;
    final blockPixelHeight = heightCells * baseCellSize;

    final topLeft = Vector2(visible.left, visible.top);

    double x;
    const double margin = 10.0;

    if (blockPixelWidth >= screenW) {
      x = topLeft.x + (screenW - blockPixelWidth) / 2.0;
    } else {
      final minXpos = topLeft.x - margin;
      final maxXpos = topLeft.x + screenW - blockPixelWidth + margin;
      x = minXpos + _rnd.nextDouble() * (maxXpos - minXpos);
    }

    final y = topLeft.y - blockPixelHeight - 2.0;

    final fallSpeed =
        minFallSpeed + _rnd.nextDouble() * (maxFallSpeed - minFallSpeed);
    final angular =
        minAngularVel + _rnd.nextDouble() * (maxAngularVel - minAngularVel);
    final initialAngle = (_rnd.nextDouble() - 0.5) * 0.6;

    final block = FallingBlock(
      shape: shape,
      position: Vector2(x, y),
      cellSize: baseCellSize,
      fallSpeed: fallSpeed,
      angularVelocity: angular,
      initialAngle: initialAngle,
    );

    parent?.add(block);
  }
}
