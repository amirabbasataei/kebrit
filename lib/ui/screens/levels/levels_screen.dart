/// Level select (MLevels.dc.html): 3 chapters × 5 tiles and a bottom sheet
/// describing the selected level.
///
/// Sheet deviation: the design's line boxes (56 px number at 1.5, stats, 2-line
/// note) add up to more than the 300 px sheet, pushing the CTA off screen, so
/// line heights are tightened (1.1 / 1.3 / 1.4) and the 16 px gaps are 10 px.
///
/// Callbacks only: [onBack] (arrow → title), [onPlay] (sheet CTA, receives
/// the level number; only offered for unlocked levels). Selection is local;
/// it starts at [Progress.currentLevel] (or [initialSelected]).
///
/// The current tile pulses (1.8 s). Goldens/tests pin the phase with
/// [pulsePhase]; under reduced flicker ([FlickerScope] or [reduceFlicker]) the
/// pulse rests at phase 0 and no ticker runs.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../data/levels.dart';
import '../../../data/persian.dart';
import '../../../data/progress.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/dashed.dart';
import '../../kit/flicker.dart';
import '../../kit/pill_button.dart';
import '../../kit/sheet.dart';
import '../../kit/stone_bg.dart';
import 'level_tile.dart';

const _pulseSeconds = 1.8;
const _lockedNumber = Color(0xFF6B5A49);

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({
    super.key,
    required this.progress,
    this.initialSelected,
    this.onBack,
    this.onPlay,
    this.pulsePhase,
    this.reduceFlicker,
  });

  final Progress progress;
  final int? initialSelected;
  final VoidCallback? onBack;
  final void Function(int level)? onPlay;

  /// Pins the current tile's pulse at this 0..1 phase (goldens/tests).
  final double? pulsePhase;

  /// Overrides [FlickerScope].
  final bool? reduceFlicker;

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen>
    with SingleTickerProviderStateMixin {
  late int _sel = (widget.initialSelected ?? widget.progress.currentLevel)
      .clamp(1, Levels.count);
  Ticker? _ticker;
  double _phase = 0;
  bool _reduce = false;

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _syncTicker() {
    final live = widget.pulsePhase == null && !_reduce;
    if (live && _ticker == null) {
      _ticker = createTicker((d) {
        final p = (d.inMicroseconds / 1e6 / _pulseSeconds) % 1;
        setState(() => _phase = p);
      })
        ..start();
    } else if (!live && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = widget.reduceFlicker ?? FlickerScope.reduceOf(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(LevelsScreen old) {
    super.didUpdateWidget(old);
    _reduce = widget.reduceFlicker ?? FlickerScope.reduceOf(context);
    _syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final pulse = widget.pulsePhase ?? (_reduce ? 0.0 : _phase);

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
              const Positioned.fill(child: RadialBackdrop.levels()),
              Positioned(
                left: 16,
                right: 24,
                top: 52,
                child: _Header(progress: p, onBack: widget.onBack),
              ),
              Positioned(
                left: 26,
                right: 26,
                top: 122,
                child: Column(
                  children: [
                    for (var ci = 0; ci < chapters.length; ci++) ...[
                      if (ci > 0) const SizedBox(height: 22),
                      _ChapterRow(
                        index: ci,
                        progress: p,
                        selected: _sel,
                        pulse: pulse,
                        onPick: (n) => setState(() => _sel = n),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SelectionSheet(
                  level: _sel,
                  progress: p,
                  onPlay: widget.onPlay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.progress, this.onBack});

  final Progress progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'بازگشت به منوی اصلی',
          excludeSemantics: true,
          onTap: onBack,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                // Points right = "back" in RTL (`M5 2l5 5-5 5`).
                child: ChevronIcon(size: 16, strokeWidth: 1.6, pointsRight: true),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Text('به سوی اعماق', style: KText.h1Serif)),
        const SizedBox(width: 8),
        Text(
          '${fa(progress.completedCount)} از ${fa(Levels.count)} اتاق\n'
          '${fa(progress.totalEmbers)} از ${fa(Levels.count * 3)} اخگر',
          textAlign: TextAlign.left,
          style: KText.small,
        ),
      ],
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.index,
    required this.progress,
    required this.selected,
    required this.pulse,
    required this.onPick,
  });

  final int index;
  final Progress progress;
  final int selected;
  final double pulse;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final chapter = chapters[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(chapter.label, style: KText.caption),
            const SizedBox(width: 10),
            Text(
              chapter.name,
              style: TextStyle(
                fontFamily: KFonts.serif,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: index <= 1 ? Kc.heading : Kc.dimmer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < levelsPerChapter; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              _tile(index * levelsPerChapter + i + 1),
            ],
          ],
        ),
      ],
    );
  }

  Widget _tile(int n) {
    final level = Levels.byId(n);
    return LevelTile(
      number: n,
      name: level.name,
      status: progress.statusOf(n),
      embers: progress.bestEmbers(n),
      hunted: level.hunterStarts.isNotEmpty,
      selected: selected == n,
      pulse: pulse,
      onTap: () => onPick(n),
    );
  }
}

class _SelectionSheet extends StatelessWidget {
  const _SelectionSheet({required this.level, required this.progress, this.onPlay});

  final int level;
  final Progress progress;
  final void Function(int level)? onPlay;

  @override
  Widget build(BuildContext context) {
    final l = Levels.byId(level);
    final status = progress.statusOf(level);
    final locked = status == LevelStatus.locked;
    final hunters = l.hunterStarts.length;
    final best = progress.bestEmbers(level);
    final chapter = chapters[chapterIndexOf(level)];

    final note = switch (status) {
      LevelStatus.done =>
        'با ${fa(best)} اخگر از ۳ گریختی. کبریت بیشتری نگه دار تا همه را بگیری.',
      LevelStatus.current => hunters > 0
          ? 'شکارچی‌های اینجا بی‌حرکت‌اند — تا وقتی شعله‌ای چشمشان را بگیرد.'
          : 'پیش از تمام شدن کبریت‌ها در را پیدا کن.',
      LevelStatus.locked => 'راه پایین هنوز بسته است.',
    };

    return BottomSheetPanel(
      height: 300,
      child: OverflowBox(
        // The CSS flex column is allowed to overflow its box; do the same.
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fa(level),
                  style: TextStyle(
                    fontFamily: KFonts.serif,
                    fontSize: 56,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: locked ? _lockedNumber : const Color(0xFFF6EAD6),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.name, style: KText.caption),
                    const SizedBox(height: 2),
                    Text(
                      l.name,
                      style: const TextStyle(
                        fontFamily: KFonts.serif,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: Kc.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Stat('کبریت', fa(l.startMatches))),
                const SizedBox(width: 8),
                Expanded(child: _Stat('شکارچی', hunters > 0 ? fa(hunters) : 'ندارد')),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    'بهترین',
                    status == LevelStatus.done ? '${fa(best)} از ۳' : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              note,
              style: const TextStyle(
                fontFamily: KFonts.serif,
                fontSize: 17,
                height: 1.4,
                color: Kc.serifSub,
              ),
            ),
            const SizedBox(height: 10),
            if (!locked)
              PillButton(
                label: status == LevelStatus.done ? 'بازی دوباره' : 'ورود به اتاق',
                height: 56,
                onPressed: onPlay == null ? null : () => onPlay!(level),
              )
            else
              SizedBox(
                height: 56,
                child: DashedBorderBox(
                  color: const Color(0x40EFE3D0), // rgba(239,227,208,.25)
                  radius: 28,
                  child: Center(
                    child: Text(
                      'برای باز شدن، از مرحله‌ی ${fa(level - 1)} بگریز',
                      style: const TextStyle(
                        fontFamily: KFonts.ui,
                        fontSize: 14,
                        color: Kc.dim,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x0DEFE3D0), // rgba(239,227,208,.05)
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: KText.caption.copyWith(height: 1.3)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: KFonts.ui,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: Kc.text,
            ),
          ),
        ],
      ),
    );
  }
}
