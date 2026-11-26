import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default tolerances (PLAN §3.4): mean per-pixel difference and fraction of
/// 4x4 blocks that differ by more than [blockThreshold].
const kMeanTol = 0.04;
const kBlockTol = 0.015;
const kBlockThreshold = 0.25;

class DesignDiff {
  DesignDiff(this.mean, this.badBlocks, this.diffPng);
  final double mean;
  final double badBlocks;
  final Uint8List diffPng;
}

Future<(int, int, Uint8List)> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final img = frame.image;
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  final r = (img.width, img.height, data!.buffer.asUint8List());
  img.dispose();
  return r;
}

Future<Uint8List> _encode(int w, int h, Uint8List rgba) async {
  final buf = await ui.ImmutableBuffer.fromUint8List(rgba);
  final desc = ui.ImageDescriptor.raw(
    buf,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await desc.instantiateCodec();
  final img = (await codec.getNextFrame()).image;
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return bytes!.buffer.asUint8List();
}

/// Box-filter downscale by [f].
Uint8List _down(int w, int h, Uint8List px, int f, int ow, int oh) {
  final out = Uint8List(ow * oh * 4);
  for (var y = 0; y < oh; y++) {
    for (var x = 0; x < ow; x++) {
      var r = 0, g = 0, b = 0, n = 0;
      for (var dy = 0; dy < f; dy++) {
        for (var dx = 0; dx < f; dx++) {
          final sx = x * f + dx, sy = y * f + dy;
          if (sx >= w || sy >= h) continue;
          final i = (sy * w + sx) * 4;
          r += px[i];
          g += px[i + 1];
          b += px[i + 2];
          n++;
        }
      }
      final o = (y * ow + x) * 4;
      if (n > 0) {
        out[o] = r ~/ n;
        out[o + 1] = g ~/ n;
        out[o + 2] = b ~/ n;
      }
      out[o + 3] = 255;
    }
  }
  return out;
}

/// Pure comparison of two PNGs (must be the same size).
Future<DesignDiff> compareImages(Uint8List a, Uint8List b) async {
  final (wa, ha, pa) = await _decode(a);
  final (wb, hb, pb) = await _decode(b);
  if (wa != wb || ha != hb) {
    throw StateError('Size mismatch: ${wa}x$ha vs ${wb}x$hb');
  }
  const f = 4;
  final ow = (wa / f).ceil(), oh = (ha / f).ceil();
  final da = _down(wa, ha, pa, f, ow, oh);
  final db = _down(wb, hb, pb, f, ow, oh);
  final diff = Uint8List(ow * oh * 4);
  var sum = 0.0;
  var bad = 0;
  for (var i = 0; i < ow * oh; i++) {
    final o = i * 4;
    final d =
        ((da[o] - db[o]).abs() +
            (da[o + 1] - db[o + 1]).abs() +
            (da[o + 2] - db[o + 2]).abs()) /
        (3 * 255);
    sum += d;
    if (d > kBlockThreshold) bad++;
    final v = (d * 255).round().clamp(0, 255);
    diff[o] = v;
    diff[o + 1] = v;
    diff[o + 2] = v;
    diff[o + 3] = 255;
  }
  return DesignDiff(
    sum / (ow * oh),
    bad / (ow * oh),
    await _encode(ow, oh, diff),
  );
}

/// Renders [finder] (a RepaintBoundary, e.g. `find.byKey(goldenKey)`) and
/// compares it with the design reference PNG at [refPath]. Skips (prints a
/// note) when the reference file does not exist. On failure writes
/// `test/failures/<name>_{flutter,design,diff}.png`.
Future<void> expectMatchesDesign(
  WidgetTester tester,
  Finder finder,
  String refPath, {
  double meanTol = kMeanTol,
  double blockTol = kBlockTol,
}) async {
  final ref = File(refPath);
  if (!ref.existsSync()) {
    // ignore: avoid_print
    print('design-compare SKIPPED (missing reference): $refPath');
    return;
  }
  final name = refPath.split(RegExp(r'[\\/]')).last.replaceAll('.png', '');
  final result = await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final mine = data!.buffer.asUint8List();
    final theirs = ref.readAsBytesSync();
    return (mine, theirs, await compareImages(mine, theirs));
  });
  final (mine, theirs, d) = result!;
  final ok = d.mean <= meanTol && d.badBlocks <= blockTol;
  if (!ok) {
    final dir = Directory('test/failures')..createSync(recursive: true);
    File('${dir.path}/${name}_flutter.png').writeAsBytesSync(mine);
    File('${dir.path}/${name}_design.png').writeAsBytesSync(theirs);
    File('${dir.path}/${name}_diff.png').writeAsBytesSync(d.diffPng);
  }
  expect(
    d.mean,
    lessThanOrEqualTo(meanTol),
    reason: 'mean diff for $name (see test/failures)',
  );
  expect(
    d.badBlocks,
    lessThanOrEqualTo(blockTol),
    reason: 'bad blocks for $name (see test/failures)',
  );
}
