// Smoke test — verify app entry point can be imported without compile errors.
//
// Real widget tests would require mocking Supabase + Firebase (out of scope
// for current iteration). This test catches import errors and class
// definition issues that would crash on app launch.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_bendahara/main.dart';

void main() {
  testWidgets('App entry point is importable', (WidgetTester tester) async {
    // Verify that the app class exists and is constructible.
    // We don't pump it because it requires Supabase.initializeApp()
    // + Firebase.initializeApp() to be called first.
    expect(Mobile_bendaharaApp.new, isA<Function>());
  });
}
