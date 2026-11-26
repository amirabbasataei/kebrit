/// Title screen (MTitle.dc.html): tilted lit match, logo, menu.
///
/// Layers bottom-up: stone wall, vignette ([LightOverlay.title]), warm
/// flicker ([WarmFlicker.title], 1.6 s), the match at (186,190), the logo
/// block at top 420 and the menu pinned 44 px above the bottom.
///
/// Callbacks only: [onContinue] (ادامه), [onTutorial], [onLevels],
/// [onSettings] (design links it to the pause/settings screen). The continue
/// subtitle comes from [progress] (current level number + name).
library;

import 'package:flutter/widgets.dart';

import '../../../data/levels.dart';
import '../../../data/persian.dart';
import '../../../data/progress.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/flicker.dart';
import '../../kit/light_overlay.dart';
import '../../kit/match_icon.dart';
import '../../kit/pill_button.dart';
import '../../kit/stone_bg.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({
    super.key,
    this.progress,
    this.onContinue,
    this.onTutorial,
    this.onLevels,
    this.onSettings,
    this.flickerPhase,
    this.reduceFlicker,
  });

  /// Null = fresh install (level 1).
  final Progress? progress;
  final VoidCallback? onContinue;
  final VoidCallback? onTutorial;
  final VoidCallback? onLevels;
  final VoidCallback? onSettings;

  /// Pins every flicker (flame pose + warm layer) at this 0..1 phase.
  final double? flickerPhase;

  /// Overrides [FlickerScope].
  final bool? reduceFlicker;

  @override
  Widget build(BuildContext context) {
    final level = Levels.byId((progress ?? Progress()).currentLevel);
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
              const Positioned.fill(child: StoneBackground()),
              Positioned.fill(child: LightOverlay.title()),
              Positioned.fill(
                child: WarmFlicker.title(
                  phase: flickerPhase,
                  reduceFlicker: reduceFlicker,
                ),
              ),
              Positioned(
                left: 186,
                top: 190,
                child: ExcludeSemantics(
                  child: MatchStick(phase: flickerPhase, reduceFlicker: reduceFlicker),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('بازی نور و هراس', style: KText.caption),
                    const SizedBox(height: 10),
                    const Text('کبریت', style: KText.logoTitle),
                    const SizedBox(height: 10),
                    Text(
                      'هر شعله راه را نشانت می‌دهد —\nو جای تو را به آن‌ها.',
                      textAlign: TextAlign.center,
                      style: KText.tagline.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 44,
                child: Semantics(
                  container: true,
                  label: 'منوی اصلی',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PillButton(
                        label: 'ادامه',
                        subLabel: 'مرحله‌ی ${fa(level.id)} · ${level.name}',
                        height: 60,
                        onPressed: onContinue,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: PillButton(
                              label: 'آموزش بازی',
                              variant: PillVariant.outline,
                              height: 52,
                              fillColor: kOutlineFillTitle,
                              onPressed: onTutorial,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PillButton(
                              label: 'مراحل',
                              variant: PillVariant.outline,
                              height: 52,
                              fillColor: kOutlineFillTitle,
                              onPressed: onLevels,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PillButton(
                        label: 'تنظیمات',
                        variant: PillVariant.text,
                        height: 44,
                        onPressed: onSettings,
                      ),
                    ],
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
