import 'package:easy_localization/easy_localization.dart' as context;
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'common_widgets.dart';
import 'main.dart';

class StartPage extends Component with HasGameReference<RouterGame> {
  StartPage() {
    addAll([
      _logo = TextComponent(
        text: 'TileRush',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 64,
            color: Color(0xFFC8FFF5),
            fontWeight: FontWeight.w800,
          ),
        ),
        anchor: Anchor.center,
      ),
      _button1 = RoundedButton(
        text: context.tr("start"),
        action: () => game.router.pushNamed('game'),
        color: const Color(0xffadde6c),
        borderColor: const Color(0xffedffab),
      ),
      _button2 = RoundedButton(
        text: context.tr("settings"),
        action: () => game.router.pushNamed('settings'),
        color: const Color(0xffdebe6c),
        borderColor: const Color(0xfffff4c7),
      ),
    ]);
  }

  late final TextComponent _logo;
  late final RoundedButton _button1;
  late final RoundedButton _button2;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _logo.position = Vector2(size.x / 2, size.y / 3);
    _button1.position = Vector2(size.x / 2, _logo.y + 80);
    _button2.position = Vector2(size.x / 2, _logo.y + 140);
  }
}
