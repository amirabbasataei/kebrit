/// Playable gameplay screen: [GameController] ↔ [GameScreenView].
///
/// A screen-wide [Listener] turns touches into joystick input (design-space
/// coordinates: the 390×844 view is `FittedBox(contain)`-scaled, so pointer
/// positions are mapped back). Pointers that start on a HUD button are
/// claimed by it ([PointerClaim]) and never move the player. The app going to
/// the background pauses the run; the owner calls `controller.resume()`.
library;

import 'package:flutter/widgets.dart';

import '../../../data/settings.dart';
import '../../../game/level.dart';
import '../../../services/haptics.dart';
import '../../../theme/tokens.dart';
import 'game_controller.dart';
import 'game_screen_view.dart';
import 'pointer_claim.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.level,
    this.controller,
    this.settings = const AppSettings(),
    this.haptics = const NoopHaptics(),
    this.timerFactory,
    this.flickerPhase,
    this.animate = true,
    this.onPause,
    this.onEscaped,
    this.onCaught,
    this.onGiveUp,
  }) : assert(level != null || controller != null);

  /// Level to play (a controller is created and owned). Ignored when
  /// [controller] is given — then the caller owns and disposes it.
  final Level? level;
  final GameController? controller;
  final AppSettings settings;
  final Haptics haptics;
  final PeriodicTimerFactory? timerFactory;
  final double? flickerPhase;
  final bool animate;

  /// Pause button; the controller is paused first. Call `resume()` to go on.
  final VoidCallback? onPause;

  /// Continue buttons of the result overlays and the give-up link.
  final void Function(GameStats stats)? onEscaped;
  final void Function(GameStats stats)? onCaught;
  final void Function(GameStats stats)? onGiveUp;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameController _c;
  late bool _owns;
  final Set<int> _claimed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bind();
  }

  void _bind() {
    _owns = widget.controller == null;
    _c =
        widget.controller ??
        GameController(
          widget.level!,
          haptics: widget.haptics,
          settings: widget.settings,
          timerFactory: widget.timerFactory,
        );
    _c.settings = widget.settings;
  }

  @override
  void didUpdateWidget(GameScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (_owns) _c.dispose();
      _bind();
    }
    _c.settings = widget.settings;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed && _c.started && _c.state.isPlaying) {
      _c.pause();
      widget.onPause?.call();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_owns) _c.dispose();
    super.dispose();
  }

  Offset _toDesign(Offset local, Size size) {
    final s = (size.width / Kc.designWidth) < (size.height / Kc.designHeight)
        ? size.width / Kc.designWidth
        : size.height / Kc.designHeight;
    final dx = (size.width - Kc.designWidth * s) / 2;
    final dy = (size.height - Kc.designHeight * s) / 2;
    return Offset((local.dx - dx) / s, (local.dy - dy) / s);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        return PointerClaims(
          claimed: _claimed,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              if (_claimed.contains(e.pointer)) return;
              final p = _toDesign(e.localPosition, size);
              _c.pointerDown(p.dx, p.dy);
            },
            onPointerMove: (e) {
              if (_claimed.contains(e.pointer)) return;
              final p = _toDesign(e.localPosition, size);
              _c.pointerMove(p.dx, p.dy);
            },
            onPointerUp: (e) {
              if (!_claimed.remove(e.pointer)) _c.pointerUp();
            },
            onPointerCancel: (e) {
              if (!_claimed.remove(e.pointer)) _c.pointerUp();
            },
            child: ListenableBuilder(
              listenable: _c,
              builder: (context, _) {
                final s = _c.state;
                return GameScreenView(
                  state: s,
                  started: _c.started,
                  drag: _c.drag,
                  settings: widget.settings,
                  flickerPhase: widget.flickerPhase,
                  animate: widget.animate,
                  onPause: () {
                    _c.pause();
                    widget.onPause?.call();
                  },
                  onStrike: _c.strike,
                  onContinueEscaped: () => widget.onEscaped?.call(_c.stats),
                  onContinueCaught: () => widget.onCaught?.call(_c.stats),
                  onGiveUp: () {
                    _c.giveUp();
                    widget.onGiveUp?.call(_c.stats);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
