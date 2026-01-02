// patrol_test/settings_overlay_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tilerush/settings_overlay.dart'; // adjust import path if needed
import 'package:tilerush/locale_notifier.dart'; // adjust import path if needed

// Test asset loader used only in tests — prevents reading real translation files.
class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();

  // Use the signature matching common easy_localization versions.
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
  // A patrolTest provides a PatrolTester ($) that wraps the usual tester functionality.
  patrolTest(
    'SettingsOverlay: language toggle and reset flow',
    ($) async {
      // Mock SharedPreferences BEFORE pumping the widget tree.
      
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        'lang': 'en',
        'bestScore': 42,
      });

      // Ensure LocaleNotifier initial state matches mocked prefs.
      LocaleNotifier.instance.value = const Locale('en', 'US');

      // Pump the app widget under EasyLocalization and MaterialApp.
      // IMPORTANT: MaterialApp must receive EasyLocalization delegates and locale.
      await $.pumpWidgetAndSettle(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('pl', 'PL')],
          path: 'assets/translations',
          assetLoader: const TestAssetLoader(),
          startLocale: const Locale('en', 'US'),
          child: Builder(builder: (easyCtx) {
            return MaterialApp(
              locale: easyCtx.locale,
              supportedLocales: easyCtx.supportedLocales,
              localizationsDelegates: easyCtx.localizationDelegates,
              home: Scaffold(
                body: SettingsOverlay(),
              ),
            );
          }),
        ),
      );

      // Ensure all animations/microtasks completed.
      await $.pumpAndSettle();

      // Verify language buttons exist (PL and EN).
      await expectLater($('PL'), findsOneWidget);
      await expectLater($('EN'), findsOneWidget);

      // Tap PL to change language to Polish.
      await $('PL').tap();
      await $.pumpAndSettle();

      // Verify SharedPreferences was updated to 'pl'.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lang'), 'pl');

      // Find and tap the Reset button to open confirmation dialog.
      await $('Reset').tap();
      await $.pumpAndSettle();

      // Confirmation dialog should appear with the "Are you sure?" text.
      await expectLater($('Are you sure?'), findsOneWidget);

      // Press Cancel — dialog should close.
      await $('Cancel').tap();
      await $.pumpAndSettle();
      await expectLater($('Are you sure?'), findsNothing);

      // Open dialog again and press Delete to perform the reset.
      await $('Reset').tap();
      await $.pumpAndSettle();
      await $('Delete').tap();
      await $.pumpAndSettle();

      // Verify bestScore was removed from prefs.
      final prefs2 = await SharedPreferences.getInstance();
      expect(prefs2.getInt('bestScore'), isNull);

      // SnackBar with "Deleted" should be visible.
      await expectLater($('Deleted'), findsOneWidget);
    },
  );
}
