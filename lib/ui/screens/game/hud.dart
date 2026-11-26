/// MGame HUD: pause button, level title, match counter, burn bar, the drag
/// hint line and the "give up" link.
library;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../game/game_state.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/match_icon.dart';
import '../../kit/svg_path.dart';
import 'pointer_claim.dart';

/// Hint under the board, by state (MGame `hint`).
String hintFor(GameState s, {required bool started}) {
  if (!started)
    return 'روی کبریت بزن تا اتاق روشن شود. شکارچی‌ها هم نورش را می‌بینند.';
  if (s.lit) return 'شعله‌ات را دیدند. از حرکت نایست.';
  if (s.matches > 0) return 'در تاریکی راهت را پیدا کن، یا کبریت دیگری بزن.';
  return 'کبریتی نمانده. به حافظه‌ات اعتماد کن.';
}

/// Top bar at (16, 52): pause (right in RTL), title, match counter (left).
class GameTopBar extends StatelessWidget {
  const GameTopBar({super.key, required this.state, this.onPause});

  final GameState state;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    final n = state.matches;
    return Positioned(
      left: Kc.gutterHud,
      right: Kc.gutterHud,
      top: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            button: true,
            label: 'توقف',
            excludeSemantics: true,
            onTap: onPause,
            child: PointerClaim(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPause,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: rgba(239, 227, 208, .22)),
                  ),
                  child: const CustomPaint(
                    size: Size(14, 16),
                    painter: _PausePainter(),
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('مرحله‌ی ${fa(state.level.id)}', style: KText.caption),
              const SizedBox(height: 2),
              Text(
                state.level.name,
                style: KText.h1Serif.copyWith(fontSize: 22, color: Kc.heading),
              ),
            ],
          ),
          Semantics(
            label: '${fa(n)} کبریت باقی مانده',
            excludeSemantics: true,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const MatchIcon(),
                  const SizedBox(width: 6),
                  Text(
                    fa(n),
                    style: const TextStyle(
                      fontFamily: KFonts.serif,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: Kc.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PausePainter extends CustomPainter {
  const _PausePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Kc.text;
    for (final x in const [1.0, 9.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 1, 4, 14),
          const Radius.circular(1),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_PausePainter o) => false;
}

/// The 3 px burn bar at (24, 112): orange→yellow fill, anchored at the right
/// (RTL), proportional to `burn`.
class BurnBar extends StatelessWidget {
  const BurnBar({super.key, required this.burn});

  final double burn;

  @override
  Widget build(BuildContext context) => Positioned(
    left: Kc.gutter,
    right: Kc.gutter,
    top: 112,
    height: 3,
    child: CustomPaint(painter: _BurnPainter(burn.clamp(0, 100) / 100)),
  );
}

class _BurnPainter extends CustomPainter {
  _BurnPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.save();
    canvas.clipRRect(track);
    canvas.drawRRect(track, Paint()..color = rgba(255, 230, 200, .1));
    final w = size.width * fraction;
    if (w > 0) {
      // Anchored at the right edge: a block with a width in an RTL box.
      final fill = Rect.fromLTWH(size.width - w, 0, w, size.height);
      paintCssShadow(
        canvas,
        RRect.fromRectXY(fill, 0, 0),
        CssShadow(0, 0, 10, 0, rgba(255, 150, 50, .7)),
      );
      canvas.drawRect(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Kc.flameHot, Kc.flameLight],
          ).createShader(fill),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BurnPainter o) => o.fraction != fraction;
}

/// "Drag anywhere" line + the contextual hint, bottom-left (or bottom-right
/// when the strike button is mirrored to the left).
class GameHint extends StatelessWidget {
  const GameHint({super.key, required this.text, this.mirrored = false});

  final String text;

  /// Left-handed layout: the strike button takes the left corner, so the hint
  /// moves to the right.
  final bool mirrored;

  @override
  Widget build(BuildContext context) => Positioned(
    left: mirrored ? null : 24,
    right: mirrored ? 24 : null,
    bottom: 52,
    width: 210,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const CustomPaint(size: Size(16, 20), painter: _FingerPainter()),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('هر جای صفحه را بکش تا حرکت کنی', style: KText.small),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            fontFamily: KFonts.serif,
            fontSize: 18,
            height: 1.3,
            color: Kc.serifSub,
          ),
        ),
      ],
    ),
  );
}

class _FingerPainter extends CustomPainter {
  const _FingerPainter();

  static final _paths = [
    'M6 9V3a1.5 1.5 0 0 1 3 0v5',
    'M9 8V6.5a1.5 1.5 0 0 1 3 0V10',
    'M6 9 4.5 7.8a1.5 1.5 0 0 0-2.1 2.1L6 14c1 1.5 2.5 4 5 4 2.5 0 3.5-2 3.5-4.5V10a1.5 1.5 0 0 0-3 0',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = Kc.muted;
    for (final d in _paths) {
      canvas.drawPath(parseSvgPath(d), p);
    }
  }

  @override
  bool shouldRepaint(_FingerPainter o) => false;
}

/// "کبریت تمام شد — تسلیم می‌شوی؟" at top 128, right 24.
class GiveUpLink extends StatelessWidget {
  const GiveUpLink({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    right: Kc.gutter,
    // 44 px tap target around the 13 px text line (text top stays at 128).
    top: 128 - 14,
    child: Semantics(
      button: true,
      excludeSemantics: true,
      label: 'کبریت تمام شد — تسلیم می‌شوی؟',
      onTap: onTap,
      child: PointerClaim(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'کبریت تمام شد — تسلیم می‌شوی؟',
              style: TextStyle(
                fontFamily: KFonts.ui,
                fontSize: 13,
                color: Kc.flame,
                decoration: TextDecoration.underline,
                decorationColor: Kc.flame,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
