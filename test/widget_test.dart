import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock SharedPreferences before initializing easy_localization
    SharedPreferences.setMockInitialValues({'lang': 'en', 'bestScore': 42});

    LocaleNotifier.instance.value = const Locale('en', 'US');

    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    // Reset prefs and notifier before each test
    SharedPreferences.setMockInitialValues({'lang': 'en', 'bestScore': 42});
    LocaleNotifier.instance.value = const Locale('en', 'US');
  });

  testWidgets('SettingsOverlay loads and toggles language and reset flow', (
    tester,
  ) async {
    await tester.pumpWidget(
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

    await tester.pumpAndSettle();

    // Verify language toggle buttons are visible
    expect(find.text('PL'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);

    // Tap 'PL' to switch language
    await tester.tap(find.text('PL'));
    await tester.pumpAndSettle();

    // Verify SharedPreferences updated
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang'), 'pl');

    // Reset flow: open confirmation dialog
    final resetButton = find.widgetWithText(ElevatedButton, 'Reset');
    expect(resetButton, findsOneWidget);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('Are you sure?'), findsOneWidget);

    // Press Cancel - dialog should close
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure?'), findsNothing);

    // Open again - press Delete - bestScore removed - SnackBar shown
    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final prefs2 = await SharedPreferences.getInstance();
    expect(prefs2.getInt('bestScore'), isNull);

    // SnackBar with "Deleted" should be visible
    expect(find.text('Deleted'), findsOneWidget);
  });
}
