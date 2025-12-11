import 'package:flame/components.dart';

import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route, BackButton;

import 'common_widgets.dart';

class SettingsPage extends DecoratedWorld with HasGameReference {
  @override
  Future<void> onLoad() async {
    addAll([Background(const Color(0xff052b44))]);
  }

  final hudComponents = <Component>[];

  @override
  void onMount() {
    // hudComponents.addAll([BackButton(), PauseButton()]);
    // game.camera.viewport.addAll(hudComponents);

    game.overlays.add('SettingsOverlay');
  }

  @override
  void onRemove() {
    if (game.overlays.isActive('SettingsOverlay')) {
      game.overlays.remove('SettingsOverlay');
    }
    game.camera.viewport.removeAll(hudComponents);
    super.onRemove();
  }
}
