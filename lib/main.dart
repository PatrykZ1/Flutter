import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:tilerush/game_over_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'starting_screen.dart';
import 'game_screen.dart';
import 'pause_screen.dart';
import 'settings_screen.dart';
import 'settings_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', 'US'), Locale('pl', 'PL')],
      path: 'assets/translations',
      fallbackLocale: Locale('en', 'US'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final RouterGame _game = RouterGame();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, Widget Function(BuildContext, RouterGame)> overlayMap = {
      'SettingsOverlay': (BuildContext ctx, RouterGame game) {
        return SettingsOverlay(game: game);
      },
    };

    return MaterialApp(
      title: 'TileRush',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(
        body: GameGestureWrapper(
          game: _game,
          overlayBuilderMap: overlayMap,
          initialActiveOverlays: const <String>[],
        ),
      ),
    );
  }
}

class GameGestureWrapper extends StatefulWidget {
  final RouterGame game;
  final Map<String, Widget Function(BuildContext, RouterGame)>?
  overlayBuilderMap;
  final List<String>? initialActiveOverlays;

  const GameGestureWrapper({
    super.key,
    required this.game,
    this.overlayBuilderMap,
    this.initialActiveOverlays,
  });

  @override
  State<GameGestureWrapper> createState() => _GameGestureWrapperState();
}

class _GameGestureWrapperState extends State<GameGestureWrapper> {
  Vector2? _lastLocal;

  GamePage? _findGamePage() {
    GamePage? found;

    void search(Component c) {
      if (found != null) return;
      if (c is GamePage) {
        found = c;
        return;
      }
      for (final child in c.children) {
        search(child);
        if (found != null) return;
      }
    }

    try {
      for (final c in widget.game.children) {
        search(c);
        if (found != null) break;
      }
    } catch (_) {
      return null;
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        final local = details.localPosition;
        final v = Vector2(local.dx, local.dy);
        _lastLocal = v;
        final page = _findGamePage();
        if (page != null) page.onDragStart(v);
      },
      onPanUpdate: (details) {
        final local = details.localPosition;
        final v = Vector2(local.dx, local.dy);
        _lastLocal = v;
        final page = _findGamePage();
        if (page != null) page.onDragUpdate(v);
      },
      onPanEnd: (details) {
        final page = _findGamePage();
        if (page != null) {
          if (_lastLocal != null) {
            page.onDragEnd(_lastLocal!);
          } else {
            page.onDragEnd(Vector2.zero());
          }
        }
        _lastLocal = null;
      },
      onPanCancel: () {
        final page = _findGamePage();
        if (page != null) {
          if (_lastLocal != null) {
            page.onDragEnd(_lastLocal!);
          } else {
            page.onDragEnd(Vector2.zero());
          }
        }
        _lastLocal = null;
      },
      child: GameWidget<RouterGame>(
        game: widget.game,
        overlayBuilderMap:
            widget.overlayBuilderMap ??
            <String, Widget Function(BuildContext, RouterGame)>{},
        initialActiveOverlays: widget.initialActiveOverlays ?? const <String>[],
      ),
    );
  }
}

class RouterGame extends FlameGame {
  late final RouterComponent router;
  int lastScore = 0;
  @override
  Future<void> onLoad() async {
    add(
      router = RouterComponent(
        routes: {
          'home': Route(StartPage.new, maintainState: false),
          'game': WorldRoute(GamePage.new, maintainState: false),
          'settings': WorldRoute(SettingsPage.new, maintainState: true),
          'pause': PauseRoute(),
          'game_over': GameOverRoute(),
        },
        initialRoute: 'home',
      ),
    );
  }
}
