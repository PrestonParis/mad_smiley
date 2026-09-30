import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smiley_painter/main.dart';

void main() {
  testWidgets('tap cycles faces and undo restores', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmileyApp());
    expect(find.text('Mood: 0.80'), findsOneWidget);

    SmileyPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is SmileyPainter,
                  ),
                )
                .painter
            as SmileyPainter;

    expect(painter().faceType, FaceType.classic);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    expect(painter().faceType, FaceType.sleepy);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(painter().faceType, FaceType.classic);
  });

  test('shouldRepaint only when inputs change', () {
    SmileyPainter make(double mood) => SmileyPainter(
      mood: mood,
      faceColor: colorForMood(mood),
      faceType: FaceType.classic,
      eyeScale: 1,
      showBlush: false,
      showHat: false,
      showGlasses: false,
      showMustache: false,
    );
    expect(make(0.5).shouldRepaint(make(0.5)), isFalse);
    expect(make(0.5).shouldRepaint(make(0.9)), isTrue);
  });
}
