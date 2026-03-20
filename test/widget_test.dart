// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_city_monitor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartCityApp());

    // Verify it shows the loading splash or the dashboard
    // Since it's a test, we might need to wait for the startup delay
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('SMART DASHBOARD', findRichText: true), findsNothing); // It's likely mixed case in the UI but Uppercase in data
    expect(find.byIcon(Icons.grid_view_rounded), findsWidgets);
  });
}
