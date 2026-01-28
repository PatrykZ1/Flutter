import 'dart:math';
import 'package:easy_localization/easy_localization.dart' as context;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart' hide Route;
import 'main.dart';
import 'common_widgets.dart';

class GameOverRoute extends Route {
  GameOverRoute() : super(GameOverPage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    if (previousRoute is WorldRoute && previousRoute.world is DecoratedWorld) {
      (previousRoute.world! as DecoratedWorld).timeScale = 0;
      (previousRoute.world! as DecoratedWorld).decorator =
          PaintDecorator.grayscale(opacity: 0.5)..addBlur(3.0);
    }
  }

  @override
  void onPop(Route nextRoute) {
    if (nextRoute is WorldRoute && nextRoute.world is DecoratedWorld) {
      (nextRoute.world! as DecoratedWorld).timeScale = 1;
      (nextRoute.world! as DecoratedWorld).decorator = null;
    }
  }
}

class GameOverPage extends Component
    with TapCallbacks, HasGameReference<RouterGame> {
  int lastScore = 0;
  int bestScore = 0;

  bool _locked = true;
  double _lockedTimer = 2.0;

  TextComponent? _textComponent;
  TextComponent? _hintText;

  double _lastFontSize = 0.0;

  static const double minFont = 12.0;
  static const double maxFont = 96.0;
  static const double sizeFactor = 0.08;

  @override
  void onMount() {
    super.onMount();
    lastScore = game.lastScore;
    _lockedTimer = 2.0;
    _locked = true;
    _hintText?.text = "";
    if (_textComponent != null) {
      _textComponent!.text = 'game_over'.tr(args: [lastScore.toString()]);
      _updateTextStyleAndPosition(game.canvasSize);
    }
  }

  @override
  Future<void> onLoad() async {
    _textComponent = TextComponent(
      text: 'game_over'.tr(args: ['0']), // placeholder
      anchor: Anchor.center,
    );

    _textComponent!.add(
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(duration: 0.3, alternate: true, infinite: true),
      ),
    );

    _hintText = TextComponent(
      text: "",
      anchor: Anchor.topCenter,
      position: Vector2(0, 0),
    );

    _updateTextStyleAndPosition(game.canvasSize);

    add(_textComponent!);
  }

  void _updateTextStyleAndPosition(Vector2 canvasSize) {
    if (_textComponent == null) return;

    final smaller = min(canvasSize.x, canvasSize.y);

    double fontSize = smaller * sizeFactor;
    fontSize = max(minFont, min(fontSize, maxFont));
    _lastFontSize = fontSize;

    _textComponent!.textRenderer = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );

    _textComponent!.text = 'game_over'.tr(args: [lastScore.toString()]);

    _textComponent!.position = canvasSize / 2;

    if (_hintText != null && !_locked && children.contains(_hintText)) {
      _hintText!.textRenderer = TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: max(12.0, fontSize * 0.45),
          fontWeight: FontWeight.w500,
        ),
      );
      _hintText!.position =
          _textComponent!.position + Vector2(0, _lastFontSize * 0.9);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateTextStyleAndPosition(size);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void update(double dt) {
    super.update(dt);
    if (_locked) {
      _lockedTimer -= dt;
      if (_lockedTimer <= 0) {
        _locked = false;
        _showHintAndEnableClick();
      }
    }
  }

  void _showHintAndEnableClick() {
    if (_hintText == null) return;

    _hintText!.textRenderer = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: max(12.0, _lastFontSize * 0.45),
        fontWeight: FontWeight.w500,
      ),
    );

    _hintText!.text = 'click_to_return'.tr();
    if (_textComponent != null) {
      _hintText!.position =
          _textComponent!.position + Vector2(0, _lastFontSize * 0.9);
    } else {
      _hintText!.position =
          game.canvasSize / 2 + Vector2(0, _lastFontSize * 0.9);
    }

    if (!children.contains(_hintText)) {
      add(_hintText as Component);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_locked) return;

    game.router.pop();
    game.router.pushReplacementNamed('home');
  }
}
