import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/easy_localization.dart' as app_context;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';

import 'locale_notifier.dart';

class AppSettings {
  AppSettings._private();
  static final AppSettings _i = AppSettings._private();
  factory AppSettings() => _i;
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en', 'US'));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final l = prefs.getString('lang') ?? 'en';
    locale.value = Locale(l);
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    locale.value = Locale(lang);
  }

  Future<void> resetBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bestScore');
  }
}

class SettingsOverlay extends StatefulWidget {
  final FlameGame? game;
  const SettingsOverlay({super.key, this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  String _lang = 'en';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('lang') ?? 'en';
      _loading = false;
    });
  }

  Future<void> _setLang(String lang) async {
    await AppSettings().setLanguage(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);

    if (lang == 'en') {
      // ignore: use_build_context_synchronously
      context.setLocale(Locale('en', 'US'));
      LocaleNotifier.instance.value = const Locale('en', 'US');
    } else if (lang == 'pl') {
      // ignore: use_build_context_synchronously
      context.setLocale(Locale('pl', 'PL'));
      LocaleNotifier.instance.value = const Locale('pl', 'PL');
    }
    setState(() => _lang = lang);
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr("reset")),
        content: Text(context.tr("confirmation")),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr("cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr("delete")),
          ),
        ],
      ),
    );

    if (ok == true) {
      await AppSettings().resetBestScore();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            // ignore: use_build_context_synchronously
            context.tr("pop_up"),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          minWidth: 240,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr("settings"),
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.tr("language"),
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: ToggleButtons(
                            isSelected: [_lang == 'pl', _lang == 'en'],
                            onPressed: (idx) =>
                                _setLang(idx == 0 ? 'pl' : 'en'),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('PL'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('EN'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _confirmReset,
                    child: Text(context.tr("reset")),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      if (widget.game != null) {
                        widget.game!.overlays.remove('SettingsOverlay');
                        try {
                          (widget.game as dynamic).router.pushReplacementNamed(
                            'home',
                          );
                        } catch (_) {}
                      } else {
                        Navigator.of(context, rootNavigator: true).maybePop();
                      }
                    },
                    child: Text(context.tr("close")),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
