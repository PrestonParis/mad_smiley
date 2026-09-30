// In-Class Activity 06 — Drawing with Flutter
// Student: Preston Paris
// Date: September 30, 2026

import 'dart:math' show Random, pi;

import 'package:flutter/material.dart';

void main() => runApp(const SmileyApp());

class SmileyApp extends StatelessWidget {
  const SmileyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smiley Painter Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DrawingPlayground(),
    );
  }
}

// Level 3: named face designs, passed into one painter.
enum FaceType { classic, sleepy, surprised }

extension FaceTypeLabel on FaceType {
  String get label => switch (this) {
    FaceType.classic => 'Classic',
    FaceType.sleepy => 'Sleepy',
    FaceType.surprised => 'Surprised',
  };
}

// Level 2: face color reacts to mood bands.
Color colorForMood(double mood) {
  if (mood < 0.35) return Colors.lightBlue.shade300; // cool / sad
  if (mood <= 0.7) return Colors.yellow.shade600; // neutral
  return Colors.orange.shade400; // warm / happy
}

// Bonus: one snapshot of everything the painter draws, used by the undo stack.
class FaceConfig {
  const FaceConfig({
    required this.mood,
    required this.faceColor,
    required this.faceType,
    required this.eyeScale,
    required this.showBlush,
    required this.showHat,
    required this.showGlasses,
    required this.showMustache,
  });

  final double mood; // 0.0 sad → 1.0 happy
  final Color faceColor;
  final FaceType faceType;
  final double eyeScale; // multiplier on the base eye radius
  final bool showBlush;
  final bool showHat;
  final bool showGlasses;
  final bool showMustache;

  FaceConfig copyWith({
    double? mood,
    Color? faceColor,
    FaceType? faceType,
    double? eyeScale,
    bool? showBlush,
    bool? showHat,
    bool? showGlasses,
    bool? showMustache,
  }) {
    return FaceConfig(
      mood: mood ?? this.mood,
      faceColor: faceColor ?? this.faceColor,
      faceType: faceType ?? this.faceType,
      eyeScale: eyeScale ?? this.eyeScale,
      showBlush: showBlush ?? this.showBlush,
      showHat: showHat ?? this.showHat,
      showGlasses: showGlasses ?? this.showGlasses,
      showMustache: showMustache ?? this.showMustache,
    );
  }
}

class DrawingPlayground extends StatefulWidget {
  const DrawingPlayground({super.key});

  @override
  State<DrawingPlayground> createState() => _DrawingPlaygroundState();
}

class _DrawingPlaygroundState extends State<DrawingPlayground> {
  // Drawing "state" — changing this + setState() triggers shouldRepaint
  FaceConfig face = FaceConfig(
    mood: 0.8,
    faceColor: colorForMood(0.8),
    faceType: FaceType.classic,
    eyeScale: 1.0,
    showBlush: false,
    showHat: false,
    showGlasses: false,
    showMustache: false,
  );

  final List<FaceConfig> undoStack = [];
  final Random random = Random();

  // Save the current face before a change so Undo can restore it.
  void saveForUndo() {
    undoStack.add(face);
    if (undoStack.length > 50) undoStack.removeAt(0);
  }

  void applyChange(FaceConfig next) {
    saveForUndo();
    setState(() => face = next);
  }

  void undo() {
    if (undoStack.isEmpty) return;
    setState(() => face = undoStack.removeLast());
    showMessage('Undo: restored previous face');
  }

  // Level 4: clear the old SnackBar before showing the next one.
  void showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  void cycleFace() {
    final types = FaceType.values;
    final next = types[(face.faceType.index + 1) % types.length];
    applyChange(face.copyWith(faceType: next));
    showMessage('Tap: switched to ${next.label} face');
  }

  void randomizeFace() {
    final mood = random.nextDouble();
    final color = HSVColor.fromAHSV(
      1,
      random.nextDouble() * 360,
      0.55,
      0.95,
    ).toColor();
    applyChange(face.copyWith(mood: mood, faceColor: color));
    showMessage(
      'Long-press: random mood ${mood.toStringAsFixed(2)} + new color',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvas = LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: GestureDetector(
            onTap: cycleFace,
            onLongPress: randomizeFace,
            child: CustomPaint(
              size: Size.square(side),
              painter: SmileyPainter(
                mood: face.mood,
                faceColor: face.faceColor,
                faceType: face.faceType,
                eyeScale: face.eyeScale,
                showBlush: face.showBlush,
                showHat: face.showHat,
                showGlasses: face.showGlasses,
                showMustache: face.showMustache,
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomPainter Smiley Lab'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: undoStack.isEmpty ? null : undo,
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: canvas,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(child: buildControls()),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: canvas,
                  ),
                ),
                Flexible(child: SingleChildScrollView(child: buildControls())),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tap face: next design · Long-press: randomize',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          SegmentedButton<FaceType>(
            segments: [
              for (final type in FaceType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {face.faceType},
            onSelectionChanged: (selection) =>
                applyChange(face.copyWith(faceType: selection.first)),
          ),
          const SizedBox(height: 8),
          Text('Mood: ${face.mood.toStringAsFixed(2)}'),
          Slider(
            value: face.mood,
            // Save once per drag, not on every frame of the drag.
            onChangeStart: (_) => saveForUndo(),
            onChanged: (double v) => setState(
              () => face = face.copyWith(mood: v, faceColor: colorForMood(v)),
            ),
          ),
          Text('Eye size: ${face.eyeScale.toStringAsFixed(2)}x'),
          Slider(
            value: face.eyeScale,
            min: 0.5,
            max: 1.6,
            onChangeStart: (_) => saveForUndo(),
            onChanged: (double v) =>
                setState(() => face = face.copyWith(eyeScale: v)),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              FilterChip(
                label: const Text('Blush'),
                selected: face.showBlush,
                onSelected: (on) => applyChange(face.copyWith(showBlush: on)),
              ),
              IconButton.filledTonal(
                tooltip: 'Hat',
                isSelected: face.showHat,
                icon: const Icon(Icons.school_outlined),
                selectedIcon: const Icon(Icons.school),
                onPressed: () =>
                    applyChange(face.copyWith(showHat: !face.showHat)),
              ),
              IconButton.filledTonal(
                tooltip: 'Glasses',
                isSelected: face.showGlasses,
                icon: const Icon(Icons.visibility_outlined),
                selectedIcon: const Icon(Icons.visibility),
                onPressed: () =>
                    applyChange(face.copyWith(showGlasses: !face.showGlasses)),
              ),
              IconButton.filledTonal(
                tooltip: 'Mustache',
                isSelected: face.showMustache,
                icon: const Icon(Icons.face_outlined),
                selectedIcon: const Icon(Icons.face),
                onPressed: () => applyChange(
                  face.copyWith(showMustache: !face.showMustache),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SmileyPainter extends CustomPainter {
  SmileyPainter({
    required this.mood,
    required this.faceColor,
    required this.faceType,
    required this.eyeScale,
    required this.showBlush,
    required this.showHat,
    required this.showGlasses,
    required this.showMustache,
  });

  final double mood;
  final Color faceColor;
  final FaceType faceType;
  final double eyeScale;
  final bool showBlush;
  final bool showHat;
  final bool showGlasses;
  final bool showMustache;

  static const ink = Colors.black87;

  @override
  void paint(Canvas canvas, Size size) {
    // Every position below is based on the center and radius, never fixed pixels.
    final c = Offset(size.width / 2, size.height / 2);
    // Leave room above the face for the hat.
    final r = size.shortestSide * 0.36;
    final center = c + Offset(0, r * 0.08);

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = ink;

    // 1) Face fill, 2) face border
    canvas.drawCircle(center, r, Paint()..color = faceColor);
    canvas.drawCircle(center, r, stroke);

    // 3) Blush (drawn before eyes/mouth so they stay on top)
    if (showBlush) {
      final blush = Paint()..color = Colors.pink.withValues(alpha: 0.35);
      for (final side in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(side * r * 0.55, r * 0.15),
            width: r * 0.3,
            height: r * 0.16,
          ),
          blush,
        );
      }
    }

    // 4) Eyes + 5) mouth, depending on the selected design
    final eyeY = center.dy - r * 0.2;
    final eyeDx = r * 0.35;
    final eyeRadius = r * 0.09 * eyeScale;
    final eyes = [
      Offset(center.dx - eyeDx, eyeY),
      Offset(center.dx + eyeDx, eyeY),
    ];

    switch (faceType) {
      case FaceType.classic:
        for (final eye in eyes) {
          canvas.drawCircle(eye, eyeRadius, fill);
        }
        _drawMoodMouth(canvas, center, r, stroke, fill);
      case FaceType.sleepy:
        // Closed eyes: the lower half of a small oval, like "‿"
        for (final eye in eyes) {
          canvas.drawArc(
            Rect.fromCenter(
              center: eye,
              width: eyeRadius * 2.6,
              height: eyeRadius * 1.6,
            ),
            0,
            pi,
            false,
            stroke,
          );
        }
        // Soft, small smile
        canvas.drawArc(
          Rect.fromCenter(
            center: center + Offset(0, r * 0.3),
            width: r * 0.45,
            height: r * 0.2,
          ),
          0.2 * pi,
          0.6 * pi,
          false,
          stroke,
        );
        _drawZzz(canvas, center, r, stroke);
      case FaceType.surprised:
        final bigEye = eyeRadius * 1.5;
        final highlight = Paint()..color = Colors.white;
        for (final eye in eyes) {
          canvas.drawCircle(eye, bigEye, fill);
          canvas.drawCircle(
            eye + Offset(-bigEye * 0.35, -bigEye * 0.35),
            bigEye * 0.3,
            highlight,
          );
          // Raised, arched brows (top of a small oval above each eye)
          canvas.drawArc(
            Rect.fromCenter(
              center: eye + Offset(0, -bigEye * 1.9),
              width: bigEye * 2.4,
              height: bigEye * 1.2,
            ),
            1.15 * pi,
            0.7 * pi,
            false,
            stroke,
          );
        }
        // Round open mouth
        final mouth = Rect.fromCenter(
          center: center + Offset(0, r * 0.42),
          width: r * 0.3,
          height: r * 0.38,
        );
        canvas.drawOval(mouth, fill);
    }

    // 6) Accessories last so they sit on top of everything
    if (showMustache) _drawMustache(canvas, center, r, fill);
    if (showGlasses) _drawGlasses(canvas, eyes, r, stroke);
    if (showHat) _drawHat(canvas, center, r);
  }

  // Level 2: mood bands drive the mouth shape.
  //   < 0.35  → frown
  //   0.35–0.7 → soft smile
  //   > 0.7   → big open smile (filled)
  void _drawMoodMouth(
    Canvas canvas,
    Offset center,
    double r,
    Paint stroke,
    Paint fill,
  ) {
    final width = r * 1.0;
    if (mood < 0.35) {
      // Sadder mood → taller frown arc
      final height = r * (0.15 + (0.35 - mood) * 1.5);
      final top = center.dy + r * 0.35;
      final frownRect = Rect.fromLTWH(
        center.dx - width / 2,
        top,
        width,
        height,
      );
      canvas.drawArc(frownRect, 1.15 * pi, 0.70 * pi, false, stroke);
    } else if (mood <= 0.7) {
      // Happier mood → deeper smile arc
      final height = r * (0.15 + (mood - 0.35) * 1.2);
      final mouthRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.2),
        width: width,
        height: height,
      );
      canvas.drawArc(mouthRect, 0.15 * pi, 0.70 * pi, false, stroke);
    } else {
      // Big open smile: a filled half-oval (useCenter: true)
      final height = r * (0.5 + (mood - 0.7) * 1.0);
      final mouthRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.12),
        width: width,
        height: height,
      );
      canvas.drawArc(mouthRect, 0, pi, true, fill);
      final tongue = Paint()..color = Colors.red.shade300;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, mouthRect.bottom - height * 0.12),
          width: width * 0.4,
          height: height * 0.18,
        ),
        tongue,
      );
    }
  }

  void _drawZzz(Canvas canvas, Offset center, double r, Paint stroke) {
    final thin = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth * 0.7
      ..strokeJoin = StrokeJoin.round;
    var origin = center + Offset(r * 0.75, -r * 0.8);
    var s = r * 0.14;
    for (var i = 0; i < 3; i++) {
      final z = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(origin.dx + s, origin.dy)
        ..lineTo(origin.dx, origin.dy + s)
        ..lineTo(origin.dx + s, origin.dy + s);
      canvas.drawPath(z, thin);
      origin += Offset(s * 1.1, -s * 1.1);
      s *= 0.8;
    }
  }

  void _drawMustache(Canvas canvas, Offset center, double r, Paint fill) {
    final top = center.dy + r * 0.1;
    final path = Path()..moveTo(center.dx, top);
    for (final side in [-1, 1]) {
      path
        ..moveTo(center.dx, top)
        ..quadraticBezierTo(
          center.dx + side * r * 0.2,
          top - r * 0.08,
          center.dx + side * r * 0.42,
          top + r * 0.02,
        )
        ..quadraticBezierTo(
          center.dx + side * r * 0.2,
          top + r * 0.16,
          center.dx,
          top + r * 0.06,
        )
        ..close();
    }
    canvas.drawPath(path, Paint()..color = Colors.brown.shade800);
  }

  void _drawGlasses(Canvas canvas, List<Offset> eyes, double r, Paint stroke) {
    final lensRadius = r * 0.2;
    final lens = Paint()..color = Colors.lightBlue.withValues(alpha: 0.2);
    for (final eye in eyes) {
      canvas.drawCircle(eye, lensRadius, lens);
      canvas.drawCircle(eye, lensRadius, stroke);
    }
    // Bridge between the lenses
    canvas.drawLine(
      eyes[0] + Offset(lensRadius, 0),
      eyes[1] - Offset(lensRadius, 0),
      stroke,
    );
  }

  void _drawHat(Canvas canvas, Offset center, double r) {
    final hatPaint = Paint()..color = Colors.indigo.shade800;
    final faceTop = center.dy - r;
    // Brim sits across the top of the face
    final brim = Rect.fromCenter(
      center: Offset(center.dx, faceTop + r * 0.12),
      width: r * 1.5,
      height: r * 0.14,
    );
    final crown = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - r * 0.5,
        faceTop - r * 0.45,
        center.dx + r * 0.5,
        brim.top + 1,
      ),
      Radius.circular(r * 0.08),
    );
    canvas.drawRRect(crown, hatPaint);
    canvas.drawRect(
      Rect.fromLTRB(crown.left, brim.top - r * 0.14, crown.right, brim.top),
      Paint()..color = Colors.red.shade400, // hat band
    );
    canvas.drawRect(brim, hatPaint);
  }

  @override
  bool shouldRepaint(covariant SmileyPainter oldDelegate) {
    // Repaint only when an input that affects the drawing actually changed.
    return oldDelegate.mood != mood ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.faceType != faceType ||
        oldDelegate.eyeScale != eyeScale ||
        oldDelegate.showBlush != showBlush ||
        oldDelegate.showHat != showHat ||
        oldDelegate.showGlasses != showGlasses ||
        oldDelegate.showMustache != showMustache;
  }
}
