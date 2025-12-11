import 'package:flutter/material.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier._private() : super(const Locale('en', 'US'));
  static final LocaleNotifier instance = LocaleNotifier._private();
}
