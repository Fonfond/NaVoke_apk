// This is a basic Flutter widget test for the NaVoke app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:navoke_app/main.dart';

void main() {
  testWidgets('NaVoke app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const NavokeApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
