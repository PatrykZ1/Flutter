import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  
  patrolTest('minimal', ($) async {
    await $.pumpWidgetAndSettle(
      MaterialApp(home: Scaffold(body: Center(child: Text('app')))),
    );
    expect($('app'), findsOneWidget);
  });
}
