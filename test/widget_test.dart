// // test/settings_overlay_widget_test.dart
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:tilerush/settings_overlay.dart'; // popraw ścieżkę jeśli potrzeba

// class TestAssetLoader extends AssetLoader {
//   const TestAssetLoader();
//   @override
//   Future<Map<String, dynamic>> load(String fullPath, Locale locale) async {
//     return {
//       "settings": "Settings",
//       "language": "Language",
//       "reset": "Reset",
//       "confirmation": "Are you sure?",
//       "cancel": "Cancel",
//       "delete": "Delete",
//       "pop_up": "Deleted",
//       "close": "Close",
//       "score": "Score",
//     };
//   }
// }

// void main() {
//   // upewnij się, że binding testowy jest zainicjalizowany
//   TestWidgetsFlutterBinding.ensureInitialized();

//   setUpAll(() async {
//     // IMPORTANT: najpierw mock SharedPreferences, potem inicjalizacja easy_localization
//     SharedPreferences.setMockInitialValues({
//       // domyślne wartości używane w testach
//       'lang': 'en',
//       'bestScore': 42,
//     });

//     // teraz można bezpiecznie wywołać ensureInitialized
//     await EasyLocalization.ensureInitialized();
//   });

//   setUp(() async {
//     // jeżeli chcesz resetować prefsy przed każdym testem:
//     SharedPreferences.setMockInitialValues({'lang': 'en', 'bestScore': 42});
//   });

//   testWidgets('SettingsOverlay loads and toggles language and reset flow', (tester) async {
//     await tester.pumpWidget(
//       EasyLocalization(
//         supportedLocales: const [Locale('en', 'US'), Locale('pl', 'PL')],
//         path: 'assets/translations',
//         assetLoader: const TestAssetLoader(),
//         startLocale: const Locale('en', 'US'),
//         child: MaterialApp(
//           home: Builder(builder: (context) {
//             return Scaffold(
//               body: SettingsOverlay(),
//             );
//           }),
//         ),
//       ),
//     );

//     await tester.pumpAndSettle();

//     expect(find.text('PL'), findsOneWidget);
//     expect(find.text('EN'), findsOneWidget);

//     await tester.tap(find.text('PL'));
//     await tester.pumpAndSettle();

//     final prefs = await SharedPreferences.getInstance();
//     expect(prefs.getString('lang'), 'pl');

//     final resetButton = find.widgetWithText(ElevatedButton, 'Reset');
//     expect(resetButton, findsOneWidget);
//     await tester.tap(resetButton);
//     await tester.pumpAndSettle();

//     expect(find.text('Are you sure?'), findsOneWidget);

//     await tester.tap(find.text('Cancel'));
//     await tester.pumpAndSettle();
//     expect(find.text('Are you sure?'), findsNothing);

//     await tester.tap(resetButton);
//     await tester.pumpAndSettle();
//     await tester.tap(find.text('Delete'));
//     await tester.pumpAndSettle();

//     final prefs2 = await SharedPreferences.getInstance();
//     expect(prefs2.getInt('bestScore'), isNull);

//     expect(find.text('Deleted'), findsOneWidget);
//   });
// }
