/// Pause + settings (MPause.dc.html): the blurred maze, a dark vignette, the
/// level caption/status and a bottom sheet with the four toggles and the
/// Continue / Restart / Tutorial / Levels buttons.
///
/// Stateless: the owner keeps the [AppSettings] and applies
/// [onSettingsChanged] (Phase 11 persists them). [state] is the paused game
/// (null when opened from the title: no status line, the board is [level]'s
/// map).
library;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../data/settings.dart';
import '../../../game/game_state.dart';
import '../../../game/level.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/design_frame.dart';
import '../../kit/light_overlay.dart';
import '../../kit/pill_button.dart';
import '../../kit/sheet.dart';
import '../../kit/stone_wall.dart';
import '../../kit/toggle_row.dart';

/// «شعله‌ات …» line of the pause header.
String pauseStatus(GameState s) {
  final matches = '${fa(s.matches)} کبریت در دست.';
  if (s.lit) {
    return 'شعله‌ات با ${fa(s.secondsLeft)} ثانیه‌ی باقی‌مانده منتظر است · $matches';
  }
  return 'شعله‌ات خاموش است · $matches';
}

class PauseScreen extends StatelessWidget {
  const PauseScreen({
    super.key,
    required this.level,
    this.state,
    this.settings = const AppSettings(),
    this.onSettingsChanged,
    this.onContinue,
    this.onRestart,
    this.onTutorial,
    this.onLevels,
  });

  final Level level;
  final GameState? state;
  final AppSettings settings;
  final ValueChanged<AppSettings>? onSettingsChanged;
  final VoidCallback? onContinue;
  final VoidCallback? onRestart;
  final VoidCallback? onTutorial;
  final VoidCallback? onLevels;

  static final _outline = rgba(239, 227, 208, .24);

  @override
  Widget build(BuildContext context) {
    void change(AppSettings s) => onSettingsChanged?.call(s);
    final toggles = <(String, String, bool, AppSettings Function(bool))>[
      (
        'صدا',
        'صدای قدم‌ها، کبریت و نفس شکارچی‌ها',
        settings.sound,
        (v) => settings.copyWith(sound: v),
      ),
      (
        'لرزش گوشی',
        'لرزشی کوتاه وقتی شکارچی راه می‌افتد',
        settings.haptics,
        (v) => settings.copyWith(haptics: v),
      ),
      (
        'کاهش سوسو',
        'نور ثابت به‌جای شعله‌ی لرزان',
        settings.reduceFlicker,
        (v) => settings.copyWith(reduceFlicker: v),
      ),
      (
        'دکمه‌ی کبریت در سمت چپ',
        'برای بازی با دست چپ',
        settings.leftHanded,
        (v) => settings.copyWith(leftHanded: v),
      ),
    ];

    return DesignFrame(
      children: [
        // Blurred board snapshot.
        Positioned(
          left: 15,
          top: 150,
          width: 360,
          height: 520,
          child: ExcludeSemantics(
            child: CssBlur(
              px: 3,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: ColoredBox(color: Kc.floor)),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: MazeWalls(grid: level.grid),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: LightOverlay.pause()),
        Positioned(
          left: 24,
          right: 24,
          top: 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحله‌ی ${fa(level.id)} · ${level.name}',
                style: KText.caption,
              ),
              const SizedBox(height: 6),
              const Text(
                'توقف',
                style: TextStyle(
                  fontFamily: KFonts.serif,
                  fontSize: 52,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Color(0xFFF3E6D2),
                ),
              ),
              if (state != null) ...[
                const SizedBox(height: 6),
                Text(
                  pauseStatus(state!),
                  style: const TextStyle(
                    fontFamily: KFonts.ui,
                    fontSize: 14,
                    color: Color(0xFFC9B393),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomSheetPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('تنظیمات', style: KText.caption),
                ),
                for (var i = 0; i < toggles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 2),
                  ToggleRow(
                    label: toggles[i].$1,
                    description: toggles[i].$2,
                    value: toggles[i].$3,
                    onChanged: onSettingsChanged == null
                        ? null
                        : (v) => change(toggles[i].$4(v)),
                  ),
                ],
                const SizedBox(height: 20),
                PillButton(
                  label: 'ادامه',
                  height: 56,
                  glowAlpha: .3,
                  onPressed: onContinue,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (i, b) in [
                      ('از نو', onRestart),
                      ('آموزش', onTutorial),
                      ('مراحل', onLevels),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: PillButton(
                          label: b.$1,
                          variant: PillVariant.outline,
                          height: 48,
                          fontSize: 13,
                          borderColor: _outline,
                          onPressed: b.$2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
