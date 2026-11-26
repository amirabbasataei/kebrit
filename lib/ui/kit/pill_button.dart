/// Pill buttons from MTitle / MLevels / MPause / MComplete / MGame.
///
/// Heights 60/58/56/52/50/48/44, radius = height / 2.
///
/// * primary – `linear-gradient(#ffb45a, #ff8a2b)`, text `#1c0e05`, glow
///   `0 0 24–28px rgba(255,140,40,.3–.35)`.
/// * outline – `1px solid rgba(239,227,208,.26)`, optional translucent fill
///   (`rgba(10,7,6,.4)` on the title screen).
/// * text – a muted link (`#bfa688`, 14 px, 44 px tall).
///
/// The design has no pressed state (CSS only has `a:hover{color:#ffd27a}` and
/// `:focus-visible{outline:2px solid #ffd27a;outline-offset:3px}`), so the
/// pressed look is derived: scale .97, primary gradient 12 % darker with half
/// the glow, outline gets the `rgba(255,210,150,.06)` row-hover fill, text
/// turns `#ffd27a`. The focus ring is painted only for keyboard focus.
library;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../theme/text_styles.dart';
import '../../theme/tokens.dart';
import 'css.dart';

enum PillVariant { primary, outline, text }

/// Translucent fill of the outline buttons on the title screen.
const kOutlineFillTitle = Color(0x660A0706); // rgba(10,7,6,.4)

class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    this.subLabel,
    this.onPressed,
    this.variant = PillVariant.primary,
    this.height = 56,
    this.fontSize,
    this.fontWeight,
    this.icon,
    this.iconGap = 10,
    this.horizontalPadding = 32,
    this.expand = true,
    this.borderColor,
    this.fillColor,
    this.glowBlur,
    this.glowAlpha,
    this.semanticLabel,
    this.autofocus = false,
    this.focusNode,
  }) : assert(height >= 44 && height <= 60);

  final String label;

  /// Second, smaller line (primary only): MTitle «ادامه» / «مرحله‌ی ۷ · …».
  final String? subLabel;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final double height;
  final double? fontSize;
  final FontWeight? fontWeight;

  /// Widget shown after the label (visually on the left in RTL).
  final Widget? icon;
  final double iconGap;

  /// Used when [expand] is false (`padding: 0 32px`).
  final double horizontalPadding;

  /// Fill the available width (default) or hug the content.
  final bool expand;
  final Color? borderColor;
  final Color? fillColor;
  final double? glowBlur;
  final double? glowAlpha;
  final String? semanticLabel;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  TextStyle get _textStyle {
    final fs = widget.fontSize;
    final fw = widget.fontWeight;
    switch (widget.variant) {
      case PillVariant.primary:
        return KText.button.copyWith(fontSize: fs, fontWeight: fw);
      case PillVariant.outline:
        return KText.buttonOutline.copyWith(fontSize: fs, fontWeight: fw);
      case PillVariant.text:
        return KText.link.copyWith(
          fontSize: fs,
          fontWeight: fw,
          color: _pressed ? Kc.flameLight : Kc.muted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final radius = BorderRadius.circular(h / 2);
    final style = _textStyle;

    Widget label = Text(widget.label, style: style, maxLines: 1);
    if (widget.subLabel != null && widget.variant == PillVariant.primary) {
      label = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          Opacity(
            opacity: .8,
            child: Text(
              widget.subLabel!,
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
            ),
          ),
        ],
      );
    }
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        label,
        if (widget.icon != null) ...[
          SizedBox(width: widget.iconGap),
          widget.icon!,
        ],
      ],
    );

    BoxDecoration? deco;
    switch (widget.variant) {
      case PillVariant.primary:
        final dark = _pressed ? .12 : 0.0;
        Color d(Color c) => Color.lerp(c, const Color(0xFF000000), dark)!;
        final blur = widget.glowBlur ?? (h >= 60 ? 28 : 24);
        final alpha = (widget.glowAlpha ?? .35) * (_pressed ? .5 : 1);
        deco = BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [d(Kc.flame), d(Kc.flameDeep)],
          ),
          boxShadow: cssBoxShadows([
            CssShadow(0, 0, blur, 0, rgba(255, 140, 40, alpha)),
          ]),
        );
      case PillVariant.outline:
        final base = widget.fillColor;
        final fill = _pressed
            ? Color.alphaBlend(
                rgba(255, 210, 150, .06),
                base ?? const Color(0x00000000),
              )
            : base;
        deco = BoxDecoration(
          borderRadius: radius,
          color: fill,
          border: Border.all(color: widget.borderColor ?? Kc.outlineBorder),
        );
      case PillVariant.text:
        deco = null;
    }

    Widget body = Container(
      height: h,
      decoration: deco,
      padding: widget.expand
          ? null
          : EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      alignment: Alignment.center,
      child: content,
    );

    body = CustomPaint(
      foregroundPainter: _FocusRingPainter(_focused && _enabled, h / 2),
      child: AnimatedScale(
        scale: _pressed && widget.variant != PillVariant.text ? .97 : 1,
        duration: const Duration(milliseconds: 90),
        child: body,
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: Opacity(
        opacity: _enabled ? 1 : .4,
        child: FocusableActionDetector(
          enabled: _enabled,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => _setPressed(true) : null,
            onTapUp: _enabled ? (_) => _setPressed(false) : null,
            onTapCancel: _enabled ? () => _setPressed(false) : null,
            onTap: widget.onPressed,
            child: body,
          ),
        ),
      ),
    );
  }
}

/// The chevron from MComplete (`M9 2L4 7l5 5`, 14 viewBox, stroke 1.8) and
/// MLevels' back arrow (`M5 2l5 5-5 5`, stroke 1.6, 16 px). Points left by
/// default (the "forward" arrow in RTL); [pointsRight] mirrors it.
class ChevronIcon extends StatelessWidget {
  const ChevronIcon({
    super.key,
    this.size = 14,
    this.color = Kc.text,
    this.strokeWidth = 1.8,
    this.pointsRight = false,
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final bool pointsRight;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ChevronPainter(color, strokeWidth, pointsRight),
  );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color, this.stroke, this.right);
  final Color color;
  final double stroke;
  final bool right;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 14;
    // Left-pointing: 9,2 → 4,7 → 9,12 ; right-pointing: 5,2 → 10,7 → 5,12.
    final pts = right
        ? const [Offset(5, 2), Offset(10, 7), Offset(5, 12)]
        : const [Offset(9, 2), Offset(4, 7), Offset(9, 12)];
    final path = Path()
      ..moveTo(pts[0].dx * k, pts[0].dy * k)
      ..lineTo(pts[1].dx * k, pts[1].dy * k)
      ..lineTo(pts[2].dx * k, pts[2].dy * k);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * k
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter o) =>
      o.color != color || o.stroke != stroke || o.right != right;
}

/// `outline: 2px solid #ffd27a; outline-offset: 3px` on a pill.
class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter(this.show, this.radius);
  final bool show;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    // The outline's outer edge sits at offset + width = 5 px from the box;
    // stroke centre line is 4 px out.
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(4),
      Radius.circular(radius + 4),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Kc.flameLight,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter o) =>
      o.show != show || o.radius != radius;
}
