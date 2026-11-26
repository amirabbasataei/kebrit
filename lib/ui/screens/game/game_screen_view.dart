/// Stateless gameplay view (MGame.dc.html): everything is drawn from a
/// [GameState] (+ the joystick [drag] and [AppSettings]); no timers, no
/// gestures. Phase 8's `GameScreen` feeds it and owns input.
///
/// Layer order (CSS z-index): backdrop → board (1) → darkness overlay and warm
/// flicker (2) → door glow (3) → HUD, strike button, give-up link (4) →
/// joystick (5) → result overlays (6).
///
/// [started] mirrors the design's `init`: false until the first touch/strike,
/// which only changes the hint text and keeps the strike button enabled.
///
/// Left-handed: the strike button moves to the left corner and the hint line
/// to the right (the design only specifies the button).
library;

import 'package:flutter/widgets.dart';

import '../../../data/settings.dart';
import '../../../game/game_state.dart';
import '../../../theme/tokens.dart';
import '../../kit/light_overlay.dart';
import '../../kit/stone_bg.dart';
import 'board_painter.dart';
import 'hud.dart';
import 'joystick.dart';
import 'overlays.dart';
import 'strike_button.dart';

class GameScreenView extends StatelessWidget {
  const GameScreenView({
    super.key,
    required this.state,
    this.started = true,
    this.drag,
    this.settings = const AppSettings(),
    this.flickerPhase,
    this.animate = true,
    this.onPause,
    this.onStrike,
    this.onContinueEscaped,
    this.onContinueCaught,
    this.onGiveUp,
  });

  final GameState state;
  final bool started;

  /// Non-null while the finger is down (draws the joystick).
  final JoystickDrag? drag;
  final AppSettings settings;

  /// Pins every flame flicker at this 0..1 phase (goldens).
  final double? flickerPhase;

  /// Animate sprite movement (player .15 s, hunters .5 s).
  final bool animate;

  final VoidCallback? onPause;
  final VoidCallback? onStrike;
  final VoidCallback? onContinueEscaped;
  final VoidCallback? onContinueCaught;
  final VoidCallback? onGiveUp;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final center = lightCenter(s.player);
    final reduce = settings.reduceFlicker;
    final showGiveUp = started && s.isOutOfMatches;

    return ColoredBox(
      color: Kc.page,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: Kc.designWidth,
          height: Kc.designHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(child: RadialBackdrop()),
              GameBoard(
                state: s,
                flickerPhase: flickerPhase,
                reduceFlicker: reduce,
                animate: animate,
              ),
              Positioned.fill(
                child: s.lit
                    ? LightOverlay.lit(center: center, burn: s.burn)
                    : LightOverlay.dark(center: center),
              ),
              if (s.lit)
                Positioned.fill(
                  child: WarmFlicker.game(
                    center: center,
                    burn: s.burn,
                    phase: flickerPhase,
                    reduceFlicker: reduce ? true : null,
                  ),
                ),
              Positioned(
                left: boardOrigin.dx + s.level.grid.exit.x * kCell + 20 - 50,
                top: boardOrigin.dy + s.level.grid.exit.y * kCell - 50,
                child: DoorGlow(opacity: s.lit ? .25 : .8),
              ),
              GameTopBar(state: s, onPause: onPause),
              BurnBar(burn: s.burn),
              GameHint(
                text: hintFor(s, started: started),
                mirrored: settings.leftHanded,
              ),
              StrikeButton(
                state: s,
                started: started,
                leftHanded: settings.leftHanded,
                onStrike: onStrike,
                flickerPhase: flickerPhase,
                reduceFlicker: reduce,
              ),
              if (showGiveUp) GiveUpLink(onTap: onGiveUp),
              if (drag != null)
                Positioned.fill(child: JoystickOverlay(drag: drag!)),
              if (s.result == GameResult.escaped)
                ResultOverlay(
                  kind: ResultKind.escaped,
                  levelId: s.level.id,
                  onContinue: onContinueEscaped,
                ),
              if (s.result == GameResult.caught)
                ResultOverlay(
                  kind: ResultKind.caught,
                  levelId: s.level.id,
                  onContinue: onContinueCaught,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
