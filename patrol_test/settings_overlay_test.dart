import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tilerush/settings_overlay.dart';
import 'package:tilerush/locale_notifier.dart';

class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String fullPath, Locale locale) async {
    return {
      "settings": "Settings",
      "language": "Language",
      "reset": "Reset",
      "confirmation": "Are you sure?",
      "cancel": "Cancel",
      "delete": "Delete",
      "pop_up": "Deleted",
      "close": "Close",
      "score": "Score",
    };
  }
}

void main() {
  patrolTest('SettingsOverlay: language toggle and reset flow', ($) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'lang': 'en', 'bestScore': 42});

    LocaleNotifier.instance.value = const Locale('en', 'US');

    await $.pumpWidgetAndSettle(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('pl', 'PL')],
        path: 'assets/translations',
        assetLoader: const TestAssetLoader(),
        startLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (easyCtx) {
            return MaterialApp(
              locale: easyCtx.locale,
              supportedLocales: easyCtx.supportedLocales,
              localizationsDelegates: easyCtx.localizationDelegates,
              home: Scaffold(body: SettingsOverlay()),
            );
          },
        ),
      ),
    );

    await $.pumpAndSettle();

    await expectLater($('PL'), findsOneWidget);
    await expectLater($('EN'), findsOneWidget);

    await $('PL').tap();
    await $.pumpAndSettle();

    // verify SharedPreferences was updated to 'pl'
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang'), 'pl');

    await $('Reset').tap();
    await $.pumpAndSettle();

    await expectLater($('Are you sure?'), findsOneWidget);

    await $('Cancel').tap();
    await $.pumpAndSettle();
    await expectLater($('Are you sure?'), findsNothing);

    await $('Reset').tap();
    await $.pumpAndSettle();
    await $('Delete').tap();
    await $.pumpAndSettle();

    // verify bestScore was removed
    final prefs2 = await SharedPreferences.getInstance();
    expect(prefs2.getInt('bestScore'), isNull);

    // SnackBar with "Deleted" should be visible.
    await expectLater($('Deleted'), findsOneWidget);
  });
}
