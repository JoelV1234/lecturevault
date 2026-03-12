import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lecturevault/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LectureVaultApp());
    expect(find.text('LectureVault'), findsAny);
  });
}
