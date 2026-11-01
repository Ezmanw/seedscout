import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedscout/finder/finder.dart';
import 'package:seedscout/main.dart';

void main() {
  test('every feature searches without throwing in every version', () {
    for (final v in McVersion.values) {
      final f = SeedFinder(Int64(12345), v);
      for (final feat in features.where((e) => v.atLeast(e.since))) {
        final hits = f.find(feat, 100, -200);
        if (feat.kind == Kind.ore) {
          expect(oreInfo(feat.id, v), isNotNull);
        } else {
          expect(hits, isNotEmpty, reason: '${feat.id} ${v.label}');
        }
      }
    }
  });

  testWidgets('search shows results and the map', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SeedScoutApp());
    await tester.enterText(find.byType(TextField).first, '12345');
    await tester.tap(find.text('Find nearest'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nearest villages'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.content_copy), findsNWidgets(10));
  });

  testWidgets('narrow layout and ore view render', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SeedScoutApp());
    await tester.enterText(find.byType(TextField).first, 'hello');
    final menuField = find.byType(TextField).at(4);
    await tester.tap(menuField);
    await tester.pumpAndSettle();
    await tester.enterText(menuField, 'diam');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diamond ore').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Find nearest'));
    await tester.tap(find.text('Find nearest'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('Y -59'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
