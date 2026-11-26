/// Tutorial (MTutorial.dc.html): four steps, each with a looping 4 s demo.
///
/// State: the step index (0–3) lives in the screen; `قبلی` is disabled on the
/// first step, the last step swaps «بعدی» for «ورود به اولین اتاق». Callbacks:
/// [onSkip] («رد شدن»), [onDone] (last-step CTA).
///
/// ## Clock-injection pattern (reused by Phases 9–10)
///
/// Animated visuals are pure functions of a time value. [TutorialScreen.time]
/// pins "time since the current step appeared" (goldens/tests); when it is
/// null a [Ticker] runs the clock, restarting on every step change exactly
/// like the CSS animations restart when the step element is re-mounted.
/// Reduced flicker (`FlickerScope`) freezes each demo at a representative
/// frame ([_frozenPhase]) and stops the ticker.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart' show rgba;
import '../../kit/flicker.dart';
import '../../kit/pill_button.dart';
import '../../kit/stone_bg.dart';
import 'step_door.dart';
import 'step_drag.dart';
import 'step_hunters.dart';
import 'step_match.dart';
import 'tutorial_parts.dart';

class TutorialCopy {
  const TutorialCopy(this.title, this.body);
  final String title;
  final String body;
}

const tutorialSteps = <TutorialCopy>[
  TutorialCopy(
    'برای حرکت، بکش',
    'انگشتت را هر جای صفحه بگذار و به سمتی که می‌خواهی بروی بکش. نگه داری، به راه رفتن ادامه می‌دهی. نه دکمه‌ای لازم است، نه دسته‌ای که دنبالش بگردی.',
  ),
  TutorialCopy(
    'کبریت بزن تا ببینی',
    'اتاق‌ها کاملاً تاریک‌اند. روی کبریت بزن تا همه‌جا چند ثانیه روشن شود — بعد خاموش می‌شود. کبریت‌ها محدودند، پس لحظه‌هایت را خوب انتخاب کن.',
  ),
  TutorialCopy(
    'شکارچی‌ها دنبال نور می‌آیند',
    'شکارچی‌ها در تاریکی بی‌حرکت می‌ایستند. همین که کبریت بزنی، به سمت شعله‌ات راه می‌افتند. بگذار خاموش شود تا بایستند.',
  ),
  TutorialCopy(
    'در را پیدا کن',
    'هر اتاق فقط یک راه خروج دارد و نور از زیر درش بیرون می‌زند. بسته‌های کبریت اضافه در بن‌بست‌ها پنهان‌اند.',
  ),
];

/// Representative loop position per step when motion is reduced.
const _frozenPhase = [.6, .5, .45, 0.0];

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({
    super.key,
    this.initialStep = 0,
    this.onSkip,
    this.onDone,
    this.time,
    this.reduceFlicker,
  }) : assert(initialStep >= 0 && initialStep < 4);

  final int initialStep;
  final VoidCallback? onSkip;
  final VoidCallback? onDone;

  /// Pins the time since the current step appeared (goldens/tests).
  final Duration? time;

  /// Overrides [FlickerScope].
  final bool? reduceFlicker;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late int _step = widget.initialStep;
  Ticker? _ticker;
  double _elapsed = 0; // seconds since the ticker started
  double _stepStart = 0; // `_elapsed` when the current step appeared

  @override
  void initState() {
    super.initState();
    if (widget.time == null) {
      _ticker = createTicker((d) => setState(() => _elapsed = d.inMicroseconds / 1e6))
        ..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _go(int step) => setState(() {
        _step = step.clamp(0, 3);
        _stepStart = _elapsed;
      });

  @override
  Widget build(BuildContext context) {
    final reduce = widget.reduceFlicker ?? FlickerScope.reduceOf(context);
    final ticker = _ticker;
    if (ticker != null) {
      if (reduce && ticker.isActive) ticker.stop();
      if (!reduce && !ticker.isActive) {
        _elapsed = _stepStart = 0; // a restarted ticker counts from zero
        ticker.start();
      }
    }
    final pinned = widget.time != null || reduce;
    final seconds = widget.time != null
        ? widget.time!.inMicroseconds / 1e6
        : _elapsed - _stepStart;
    final p = reduce
        ? _frozenPhase[_step]
        : (seconds / (kTutorialLoop.inMicroseconds / 1e6)) % 1.0;
    final copy = tutorialSteps[_step];
    final last = _step == 3;

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
              const Positioned.fill(child: RadialBackdrop(center: Offset(.5, .35), inner: Kc.radialInner)),
              // Header: counter on the start side, skip on the end side.
              Positioned(
                left: 24,
                right: 24,
                top: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('راه زنده ماندن · ${fa(_step + 1)} از ${fa(4)}', style: KText.caption),
                    PillButton(
                      label: 'رد شدن',
                      variant: PillVariant.text,
                      height: 44,
                      expand: false,
                      horizontalPadding: 0,
                      fontWeight: FontWeight.w500,
                      onPressed: widget.onSkip,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                top: 116,
                child: Semantics(
                  label: copy.title,
                  child: ExcludeSemantics(
                    child: switch (_step) {
                      0 => StepDrag(p: p, pinned: pinned),
                      1 => StepMatch(p: p, pinned: pinned),
                      2 => StepHunters(p: p, pinned: pinned),
                      _ => StepDoor(breath: reduce ? 1 : breathOpacity(seconds)),
                    },
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: 524,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(copy.title, style: KText.h1Serif.copyWith(fontSize: 36)),
                    const SizedBox(height: 12),
                    Text(copy.body, style: KText.body.copyWith(height: 1.5)),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Container(
                            key: ValueKey('dot-$i'),
                            width: i == _step ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i == _step ? Kc.flameDeep : rgba(239, 227, 208, .22),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _BackButton(enabled: _step > 0, onPressed: () => _go(_step - 1)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PillButton(
                            label: last ? 'ورود به اولین اتاق' : 'بعدی',
                            height: 52,
                            fontSize: 15,
                            onPressed: last ? widget.onDone : () => _go(_step + 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «قبلی»: 52 px outline pill with 20 px side padding; when disabled only the
/// text dims (`rgba(239,227,208,.35)`), the border stays.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.enabled, required this.onPressed});
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'قبلی',
      excludeSemantics: true,
      onTap: enabled ? onPressed : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: rgba(239, 227, 208, .24)),
          ),
          child: Text(
            'قبلی',
            style: KText.buttonOutline.copyWith(
              color: enabled ? Kc.text : rgba(239, 227, 208, .35),
            ),
          ),
        ),
      ),
    );
  }
}
