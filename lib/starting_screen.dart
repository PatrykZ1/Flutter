import 'package:easy_localization/easy_localization.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'package:shared_preferences/shared_preferences.dart';
import 'common_widgets.dart';
import 'main.dart';

class StartPage extends Component with HasGameReference<RouterGame> {
  late SharedPreferences prefs;
  StartPage() {
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
    );

    _scoreText = TextComponent(
      text: 'best_score'.tr(),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Color.fromARGB(255, 255, 255, 255),
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.center,
    );
    _button1 = RoundedButton(
      text: 'start'.tr(),
      action: () => game.router.pushNamed('game'),
      color: const Color(0xffadde6c),
      borderColor: const Color(0xffedffab),
    );

    _button2 = RoundedButton(
      text: 'settings'.tr(),
      action: () => game.router.pushNamed('settings'),
      color: const Color(0xffdebe6c),
      borderColor: const Color(0xfffff4c7),
    );

    addAll([_logo, _button1, _button2]);
  }

  late TextComponent _logo;
  late TextComponent _scoreText;
  late RoundedButton _button1;
  late RoundedButton _button2;

  @override
  void onMount() async {
    super.onMount();
    _button1.removeFromParent();
    _button2.removeFromParent();
    _scoreText.removeFromParent();
    prefs = await SharedPreferences.getInstance();
    int bestScore = prefs.getInt('bestScore') ?? 0;
    _scoreText.text = '${'best_score'.tr()}$bestScore';

    _button1 = RoundedButton(
      text: 'start'.tr(),
      action: () => game.router.pushNamed('game'),
      color: const Color(0xffadde6c),
      borderColor: const Color(0xffedffab),
    );
    _button2 = RoundedButton(
      text: 'settings'.tr(),
      action: () => game.router.pushNamed('settings'),
      color: const Color(0xffdebe6c),
      borderColor: const Color(0xfffff4c7),
    );

    add(_scoreText);
    add(_button1);
    add(_button2);
    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    double centerX = size.x / 2;
    double logoY = size.y / 5;
    double positionOffset = 60;
    _logo.position = Vector2(centerX, logoY);
    _button1.position = Vector2(centerX, logoY + positionOffset * 2);
    _button2.position = Vector2(centerX, logoY + positionOffset * 3);
    _scoreText.position = Vector2(centerX, logoY + positionOffset * 4);
  }
}
