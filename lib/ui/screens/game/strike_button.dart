/// The 92 px strike button (MGame): a ring that is a solid orange gradient
/// when a match can be struck, a conic progress ring while the flame burns and
/// a dim grey ring when out of matches.
library;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../game/game_state.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/match_icon.dart';
import 'pointer_claim.dart';

class StrikeButton extends StatelessWidget {
  const StrikeButton({
    super.key,
    required this.state,
    this.started = true,
    this.leftHanded = false,
    this.onStrike,
    this.flickerPhase,
    this.reduceFlicker = false,
  });

  final GameState state;

  /// False before the first interaction (the button is always enabled then).
  final bool started;
  final bool leftHanded;

  /// Null = disabled (the design's `disabled` attribute; look is unchanged).
  final VoidCallback? onStrike;
  final double? flickerPhase;
  final bool reduceFlicker;

  /// MGame `canStrike`: playing, has matches and no flame yet.
  bool get canStrike =>
      state.isPlaying && state.matches > 0 && !(state.lit && started);

  @override
  Widget build(BuildContext context) {
    final s = state;
    final label = s.lit ? '${fa(s.secondsLeft)} ثانیه' : 'روشن کن';
    final enabled = onStrike != null && (canStrike || !started);
    return Positioned(
      left: leftHanded ? 22 : null,
      right: leftHanded ? null : 22,
      bottom: 40,
      width: 92,
      height: 92,
      child: Semantics(
        button: true,
        enabled: enabled,
        excludeSemantics: true,
        label: s.lit ? 'کبریت در حال سوختن' : 'کبریت بزن',
        onTap: enabled ? onStrike : null,
        child: PointerClaim(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onStrike : null,
            child: CustomPaint(
              painter: _RingPainter(_ring(s)),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: DecoratedBox(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: CustomPaint(
                    painter: const _FacePainter(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MatchStrikeIcon(
                          lit: s.lit,
                          phase: flickerPhase,
                          reduceFlicker: reduceFlicker ? true : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: KFonts.ui,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Kc.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Gradient _ring(GameState s) {
    if (s.lit) {
      return cssConicProgress(
        on: Kc.flame,
        off: rgba(239, 227, 208, .14),
        degrees: (s.burn * 3.6).roundToDouble(),
      );
    }
    if (s.matches > 0) return Kc.primaryButton;
    final dim = rgba(239, 227, 208, .14);
    return LinearGradient(colors: [dim, dim]);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.gradient);
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.gradient != gradient;
}

/// 82 px face: `radial-gradient(circle at 50% 40%, #3a2a1e, #1a120d)` plus the
/// `inset 0 1px 0 rgba(255,220,170,.15)` rim along the top.
class _FacePainter extends CustomPainter {
  const _FacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect);
    canvas.save();
    canvas.clipPath(circle);
    canvas.drawRect(rect, Paint()..color = rgba(255, 220, 170, .15));
    final g = cssRadialFarthestCorner(
      box: size,
      center: Offset(size.width / 2, size.height * .4),
      stops: const [
        CssStop(Color(0xFF3A2A1E), 0),
        CssStop(Color(0xFF1A120D), 1),
      ],
    );
    canvas.drawOval(
      rect.shift(const Offset(0, 1)),
      Paint()..shader = g.createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FacePainter o) => false;
}
