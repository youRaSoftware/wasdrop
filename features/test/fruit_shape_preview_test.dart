// Рисует физическую форму каждого фрукта поверх его спрайта — для проверки
// новых ассетов глазами. Пропускается, пока не задана папка вывода:
//
//   cd features && flutter test test/fruit_shape_preview_test.dart \
//       --dart-define=shapesOut=/tmp/fruit_shapes
//
// В папку кладутся t{N}.png (спрайт, тело — зелёным, круг номинального
// радиуса — оранжевым пунктиром, центр тела — крестом) и shapes.txt с
// числами (вершины, скругление, габариты).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:features/game/engine/fruit_sprites.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _outDir = String.fromEnvironment('shapesOut');

void main() {
  testWidgets(
    'render fitted bodies over the fruit sprites',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        final Directory out = Directory(_outDir)..createSync(recursive: true);
        final StringBuffer report = StringBuffer();
        for (final BallTier tier in BallTier.values) {
          final File file =
              File('assets/images/fruits/t${tier.number}_idle.png');
          if (!file.existsSync()) continue;
          final ui.Image image =
              await decodeImageFromList(await file.readAsBytes());
          final FruitBodyFit fit = await FruitSprites.measureBody(image);
          report.writeln(_describe(tier, fit));
          final ui.Image preview = await _render(image, fit);
          final ByteData? png =
              await preview.toByteData(format: ui.ImageByteFormat.png);
          File('${out.path}/t${tier.number}.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
        File('${out.path}/shapes.txt').writeAsStringSync(report.toString());
      });
    },
    skip: _outDir.isEmpty,
  );
}

String _describe(BallTier tier, FruitBodyFit fit) {
  final double nominal = AppDimens.ballRadii[tier.index];
  final double k = nominal / fit.radiusPx;
  final StringBuffer b = StringBuffer('t${tier.number}: ');
  final List<Vector2>? hull = fit.hull;
  if (hull == null) {
    b.write('circle r=${fit.radiusPx.toStringAsFixed(1)}px '
        'center=(${fit.center.x.toStringAsFixed(1)}, '
        '${fit.center.y.toStringAsFixed(1)})');
    return b.toString();
  }
  b.writeln('rounded polygon, ${hull.length} vertices, '
      'rounding=${fit.roundingPx.toStringAsFixed(1)}px '
      '(${(fit.roundingPx * k).toStringAsFixed(1)} units), '
      'extent max=${fit.maxExtentPx.toStringAsFixed(1)} '
      'min=${fit.minExtentPx.toStringAsFixed(1)}px '
      '(${(fit.maxExtentPx * k).toStringAsFixed(1)}/'
      '${(fit.minExtentPx * k).toStringAsFixed(1)} units), '
      'nominal r=$nominal units = ${fit.radiusPx.toStringAsFixed(1)}px');
  for (final Vector2 v in hull) {
    b.writeln('    (${v.x.toStringAsFixed(1)}, ${v.y.toStringAsFixed(1)}) px '
        '→ (${(v.x * k).toStringAsFixed(1)}, ${(v.y * k).toStringAsFixed(1)})'
        ' units');
  }
  return b.toString();
}

Future<ui.Image> _render(ui.Image image, FruitBodyFit fit) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final double w = image.width.toDouble();
  final double h = image.height.toDouble();
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
  canvas.drawImage(image, Offset.zero, Paint());

  final Offset c = Offset(fit.center.x, fit.center.y);
  final Paint body = Paint()
    ..color = const Color(0xFF00C853)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint bodyFill = Paint()..color = const Color(0x3300C853);
  final List<Vector2>? hull = fit.hull;
  if (hull == null) {
    canvas.drawCircle(c, fit.radiusPx, bodyFill);
    canvas.drawCircle(c, fit.radiusPx, body);
  } else {
    // Форма Box2D = выпуклая оболочка ⊕ круг ρ: обводка шириной 2ρ со
    // скруглёнными углами даёт ровно её.
    final Path path = Path()..moveTo(c.dx + hull.first.x, c.dy + hull.first.y);
    for (final Vector2 v in hull.skip(1)) {
      path.lineTo(c.dx + v.x, c.dy + v.y);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x3300C853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.roundingPx * 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, bodyFill);
    // Внешняя граница скруглённой формы.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00C853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.roundingPx * 2 + 3
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.srcOver
        ..color = const Color(0x8000C853),
    );
    // Голый многоугольник (вершины) — тонкой линией.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (final Vector2 v in hull) {
      canvas.drawCircle(
        Offset(c.dx + v.x, c.dy + v.y),
        4,
        Paint()..color = const Color(0xFF1B5E20),
      );
    }
  }
  // Круг номинального радиуса (с ним сравнивают соседи) — пунктиром.
  final Paint nominal = Paint()
    ..color = const Color(0xFFF76B15)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  const int dashes = 48;
  for (int i = 0; i < dashes; i += 2) {
    final double a0 = 2 * math.pi * i / dashes;
    final double a1 = 2 * math.pi * (i + 1) / dashes;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: fit.radiusPx),
      a0,
      a1 - a0,
      false,
      nominal,
    );
  }
  canvas.drawLine(c - const Offset(8, 0), c + const Offset(8, 0), nominal);
  canvas.drawLine(c - const Offset(0, 8), c + const Offset(0, 8), nominal);
  return recorder.endRecording().toImage(image.width, image.height);
}
