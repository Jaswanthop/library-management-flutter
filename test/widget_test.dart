import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfwise/app.dart';

void main() {
  testWidgets('shows the dashboard and navigates to the catalogue',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShelfwiseApp());
    await tester.pumpAndSettle();

    expect(find.text('Shelfwise'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Issue a book'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('nav-catalogue')));
    await tester.pumpAndSettle();

    expect(find.text('Catalogue'), findsWidgets);
    expect(find.text('The Pragmatic Programmer'), findsWidgets);
    expect(find.text('Add book'), findsOneWidget);
  });

  testWidgets('opens the issue-loan dialog from the loans screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShelfwiseApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('nav-loans')));
    await tester.pumpAndSettle();

    expect(find.text('Loans'), findsWidgets);
    await tester.tap(find.text('Issue a book').first);
    await tester.pumpAndSettle();

    expect(find.text('Issue a book'), findsWidgets);
    expect(find.text('Loan period'), findsOneWidget);
  });
}
