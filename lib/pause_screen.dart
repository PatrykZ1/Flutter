import 'package:easy_localization/easy_localization.dart' as context;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';

import 'main.dart';
import 'common_widgets.dart';

class PauseRoute extends Route {
  PauseRoute() : super(PausePage.new, transparent: true);

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

class PausePage extends Component
    with TapCallbacks, HasGameReference<RouterGame> {
  @override
  Future<void> onLoad() async {
    final game = findGame()!;
    addAll([
      TextComponent(
        text: context.tr("pause"),
        position: game.canvasSize / 2,
        anchor: Anchor.center,
        children: [
          ScaleEffect.to(
            Vector2.all(1.1),
            EffectController(duration: 0.3, alternate: true, infinite: true),
          ),
        ],
      ),
    ]);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    event.continuePropagation = false;
  }

  @override
  void onTapUp(TapUpEvent event) {
    event.continuePropagation = false;
    game.router.pop();
  }
}
