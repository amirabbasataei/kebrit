import 'package:flutter/widgets.dart';

/// Design tokens extracted from the Claude Design mobile boards (PLAN §0.1).
abstract final class Kc {
  // Backgrounds
  static const page = Color(0xFF0A0706);
  static const deep = Color(0xFF070504);
  static const caught = Color(0xFF070404);
  static const radialInner = Color(0xFF1E1611);
  static const gameBgInner = Color(0xFF1C140F);

  // Stone
  static const floor = Color(0xFF2A211B);
  static const wallFront = Color(0xFF2E231B);
  static const wallTileA = Color(0xFF3A2D24);
  static const wallTileB = Color(0xFF1E1712);
  static const wallTops = <List<Color>>[
    [Color(0xFF6E5A48), Color(0xFF55453A)],
    [Color(0xFF655243), Color(0xFF4D3F35)],
    [Color(0xFF74604D), Color(0xFF5A493C)],
  ];

  // Text
  static const text = Color(0xFFEFE3D0);
  static const heading = Color(0xFFF3E6D2);
  static const headingBright = Color(0xFFFBF0DE);
  static const muted = Color(0xFFBFA688);
  static const dim = Color(0xFFA48D72);
  static const dimmer = Color(0xFF8F7A64);
  static const body = Color(0xFFCDB89C);
  static const serifSub = Color(0xFFD8C4A6);

  // Flame / accent
  static const flame = Color(0xFFFFB45A);
  static const flameDeep = Color(0xFFFF8A2B);
  static const flameLight = Color(0xFFFFD27A);
  static const flameHot = Color(0xFFFF6A12);
  static const ember = Color(0xFFC8402E);
  static const onFlame = Color(0xFF1C0E05);

  // Danger
  static const danger = Color(0xFFFF5A2E);
  static const dangerSoft = Color(0xFFFF7A5A);
  static const eyesLit = Color(0xFFFF4A2A);
  static const eyesDormant = Color(0xFF5A2A1E);

  // Match
  static const matchStick = Color(0xFFE0C393);
  static const matchHead = Color(0xFFC8402E);

  // Gradients
  static const primaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [flame, flameDeep],
  );

  /// CSS `linear-gradient(165deg, a, b)` for wall tops.
  static LinearGradient wallTop(int shade) => LinearGradient(
        begin: const Alignment(-0.26, -0.97),
        end: const Alignment(0.26, 0.97),
        colors: wallTops[shade % 3],
      );

  static const sheetGradient = LinearGradient(
    begin: Alignment(-0.17, -0.98),
    end: Alignment(0.17, 0.98),
    colors: [Color(0xFF241B15), Color(0xFF120D0A)],
  );

  static const sheetBorder = Color(0x1FEFE3D0); // rgba(239,227,208,.12)
  static const outlineBorder = Color(0x42EFE3D0); // rgba(239,227,208,.26)

  // Radii / sizes
  static const designWidth = 390.0;
  static const designHeight = 844.0;
  static const gutter = 24.0;
  static const gutterHud = 16.0;
  static const sheetRadius = 24.0;
  static const minTouch = 44.0;
  static const buttonHeights = <double>[60, 58, 56, 52, 50, 48, 44];
}
