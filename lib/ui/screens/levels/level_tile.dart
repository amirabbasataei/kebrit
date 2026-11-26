/// One level tile of MLevels: 58×54 stone top + 10 px front, number, embers
/// (or a lock), hunter-eye dot, selection ring and the "current" glow pulse.
///
/// Shadow rules of the CSS (the inline `box-shadow` is *replaced* by the
/// `.current` animation, so a selected current tile shows the pulse and no ring):
///
/// * selected: `inset 0 0 0 2px #ffd27a, 0 0 18px rgba(255,170,80,.35)`
/// * otherwise: `inset 0 1px 0 rgba(255,225,190,.16)` (top highlight)
/// * current: `pulse` 1.8 s, `0 0 12px 1px rgba(255,150,50,.35)` ↔
///   `0 0 22px 4px rgba(255,150,50,.6)`, CSS `ease` per half-cycle.
library;

import 'dart:ui' show ClipOp;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../data/progress.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/ember_icon.dart';
import '../../kit/stone_wall.dart';

const _lockStroke = Color(0xFF7D6A57);
const _lockedNumber = Color(0xFF6B5A49);
const _eyeLocked = Color(0xFF5E4D3E);

/// Glow of the current tile at pulse phase [p] (0..1 of the 1.8 s loop).
CssShadow pulseShadow(double p) {
  final half = p < .5 ? p * 2 : (1 - p) * 2; // 0 → 1 → 0
  final e = Curves.ease.transform(half.clamp(0.0, 1.0));
  double l(double a, double b) => a + (b - a) * e;
  return CssShadow(0, 0, l(12, 22), l(1, 4), rgba(255, 150, 50, l(.35, .6)));
}

class LevelTile extends StatelessWidget {
  const LevelTile({
    super.key,
    required this.number,
    required this.name,
    required this.status,
    required this.embers,
    required this.hunted,
    required this.selected,
    required this.pulse,
    this.onTap,
  });

  final int number;
  final String name;
  final LevelStatus status;

  /// 0..3 lit embers (only shown for done levels).
  final int embers;
  final bool hunted;
  final bool selected;

  /// Pulse phase 0..1 (only used when [status] is current).
  final double pulse;
  final VoidCallback? onTap;

  static const width = 58.0, height = 64.0, topHeight = 54.0;

  static String statusLabel(LevelStatus s) => switch (s) {
        LevelStatus.done => 'گذرانده‌شده',
        LevelStatus.current => 'مرحله‌ی فعلی',
        LevelStatus.locked => 'قفل',
      };

  @override
  Widget build(BuildContext context) {
    final locked = status == LevelStatus.locked;
    return Semantics(
      button: true,
      selected: selected,
      label: 'مرحله‌ی ${fa(number)}، $name، ${statusLabel(status)}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TilePainter(
                    status: status,
                    selected: selected,
                    pulse: pulse,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: topHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fa(number),
                      style: TextStyle(
                        fontFamily: KFonts.serif,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: locked ? _lockedNumber : const Color(0xFFF6EAD6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (locked)
                      const SizedBox(
                        width: 10,
                        height: 12,
                        child: CustomPaint(painter: _LockPainter()),
                      )
                    else
                      EmberRow(
                        count: status == LevelStatus.done ? embers : 0,
                      ),
                  ],
                ),
              ),
              if (hunted)
                Positioned(
                  right: 4,
                  top: 4,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: locked ? _eyeLocked : Kc.danger,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  _TilePainter({
    required this.status,
    required this.selected,
    required this.pulse,
  });

  final LevelStatus status;
  final bool selected;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final locked = status == LevelStatus.locked;
    final current = status == LevelStatus.current;
    final top = const Rect.fromLTWH(0, 0, LevelTile.width, LevelTile.topHeight);
    final topRRect = RRect.fromRectXY(top, 0, 0);

    var style = WallStyle.levelTile;
    if (locked) style = style.copyWith(frontColor: const Color(0xFF17110D));
    final hasRing = selected && !current;
    // The inline shadow is overridden by the pulse on the current tile.
    if (hasRing || current) style = style.copyWith(topHighlight: 0);

    final colors = locked
        ? const [Color(0xFF2C231C), Color(0xFF221A15)]
        : current
            ? const [Color(0xFF8A6C50), Color(0xFF6B523D)]
            : const [Color(0xFF6E5A48), Color(0xFF55453A)];
    final gradient = cssLinear(deg: 165, box: top.size, colors: colors);

    // Outer glow is a shadow of the top face painted after the front face.
    final glow = current
        ? pulseShadow(pulse)
        : hasRing
            ? CssShadow(0, 0, 18, 0, rgba(255, 170, 80, .35))
            : null;
    if (glow != null) {
      // Front face first, then glow, then the top face (CSS sibling order).
      paintStoneWall(canvas, top, style.copyWith(topHighlight: 0), gradient);
      canvas.save();
      canvas.clipRect(top, clipOp: ClipOp.difference);
      paintCssShadow(canvas, topRRect, glow);
      canvas.restore();
      canvas.drawRect(top, Paint()..shader = gradient.createShader(top));
    } else {
      paintStoneWall(canvas, top, style, gradient);
    }

    if (hasRing) {
      canvas.drawDRRect(
        topRRect,
        topRRect.deflate(2),
        Paint()..color = Kc.flameLight,
      );
    }
  }

  @override
  bool shouldRepaint(_TilePainter o) =>
      o.status != status || o.selected != selected || o.pulse != pulse;
}

/// MLevels lock: `viewBox 0 0 14 16`, stroke `#7d6a57` 1.8, drawn at 10×12.
class _LockPainter extends CustomPainter {
  const _LockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 14; // meet: limited by width
    canvas.save();
    canvas.translate(0, (size.height - 16 * k) / 2);
    canvas.scale(k);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = _lockStroke;
    canvas.drawRRect(
      RRect.fromRectXY(const Rect.fromLTWH(1.5, 7, 11, 8), 1.5, 1.5),
      p,
    );
    final shackle = Path()
      ..moveTo(4, 7)
      ..lineTo(4, 5)
      ..arcToPoint(const Offset(10, 5),
          radius: const Radius.circular(3), clockwise: true)
      ..lineTo(10, 7);
    canvas.drawPath(shackle, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LockPainter o) => false;
}
