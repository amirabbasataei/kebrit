import 'package:flutter/widgets.dart';

import 'tokens.dart';

abstract final class KFonts {
  static const ui = 'Vazirmatn';
  static const serif = 'NotoNaskhArabic';
  static const logo = 'Lalezar';
}

/// Named text styles. Naskh uses line-height 1.5 as in the design.
abstract final class KText {
  static const logoSplash = TextStyle(
    fontFamily: KFonts.logo,
    fontSize: 112,
    height: 1.1,
    color: Color(0xFFF6EAD6),
    shadows: [Shadow(color: Color(0x59FF963C), blurRadius: 34)],
  );
  static const logoTitle = TextStyle(
    fontFamily: KFonts.logo,
    fontSize: 104,
    height: 1.1,
    color: Color(0xFFF6EAD6),
    shadows: [Shadow(color: Color(0x4DFF963C), blurRadius: 30)],
  );
  static const eyebrow = TextStyle(
    fontFamily: KFonts.logo,
    fontSize: 22,
    color: Kc.flame,
  );
  static const h1Serif = TextStyle(
    fontFamily: KFonts.serif,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: Kc.heading,
  );
  static const h2Serif = TextStyle(
    fontFamily: KFonts.serif,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.6,
    color: Kc.heading,
  );
  static const tagline = TextStyle(
    fontFamily: KFonts.serif,
    fontSize: 19,
    height: 1.6,
    color: Kc.serifSub,
  );
  static const body = TextStyle(
    fontFamily: KFonts.ui,
    fontSize: 15,
    height: 1.9,
    color: Kc.body,
  );
  static const caption = TextStyle(
    fontFamily: KFonts.ui,
    fontSize: 11,
    color: Kc.muted,
  );
  static const small = TextStyle(
    fontFamily: KFonts.ui,
    fontSize: 12,
    height: 1.6,
    color: Kc.muted,
  );
  static const button = TextStyle(
    fontFamily: KFonts.ui,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Kc.onFlame,
  );
  static const buttonOutline = TextStyle(
    fontFamily: KFonts.ui,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Kc.text,
  );
  static const link = TextStyle(
    fontFamily: KFonts.ui,
    fontSize: 14,
    color: Kc.muted,
  );
}
