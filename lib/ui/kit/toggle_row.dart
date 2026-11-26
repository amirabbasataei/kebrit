/// Settings toggle row from MPause.
///
/// ```css
/// row:   min-height 56px; padding 6px 12px; margin 0 -12px; radius 8px;
///        hover background rgba(255,210,150,.06)
/// label: 15px/500    desc: 12px #a48d72
/// track: 48×28 radius 14, on #ff8a2b / off rgba(239,227,208,.2)
/// knob:  22×22 #f6ead6 at top 3px, `left: 3px` (on) / `23px` (off), .15 s
/// ```
///
/// `left` is physical, so the knob sits on the physical left when on, even in
/// RTL – exactly as in the design. `padding: 6px 12px; margin: 0 -12px` nets
/// out to no horizontal padding; the pressed background is painted 12 px
/// outside the row's box to reproduce the negative margin.
library;

import 'package:flutter/widgets.dart';

import '../../theme/text_styles.dart';
import '../../theme/tokens.dart';
import 'css.dart';

/// The bare 48×28 switch.
class KToggle extends StatelessWidget {
  const KToggle({super.key, required this.value});
  final bool value;

  static const trackOn = Kc.flameDeep;
  static final trackOff = rgba(239, 227, 208, .2);
  static const knobColor = Color(0xFFF6EAD6);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: value ? trackOn : trackOff,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.ease,
            top: 3,
            left: value ? 3 : 23,
            width: 22,
            height: 22,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: knobColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ToggleRow extends StatefulWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<ToggleRow> {
  bool _pressed = false;

  void _press(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        // CSS: padding 6px 12px + margin 0 -12px → net horizontal padding 0.
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: KFonts.ui,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Kc.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontFamily: KFonts.ui,
                      fontSize: 12,
                      color: Kc.dim,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            KToggle(value: widget.value),
          ],
        ),
      ),
    );

    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      label: widget.label,
      hint: widget.description,
      excludeSemantics: true,
      onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _press(true) : null,
        onTapUp: enabled ? (_) => _press(false) : null,
        onTapCancel: enabled ? () => _press(false) : null,
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -12,
              right: -12,
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _pressed ? rgba(255, 210, 150, .06) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            row,
          ],
        ),
      ),
    );
  }
}
