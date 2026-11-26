/// Full-screen result overlays of MGame: "found the door" and "caught".
library;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/pill_button.dart';

enum ResultKind { escaped, caught }

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.kind,
    required this.levelId,
    this.onContinue,
  });

  final ResultKind kind;
  final int levelId;
  final VoidCallback? onContinue;

  bool get _escaped => kind == ResultKind.escaped;

  @override
  Widget build(BuildContext context) {
    final size = const Size(Kc.designWidth, Kc.designHeight);
    final gradient = _escaped
        ? cssRadialFarthestCorner(
            box: size,
            center: const Offset(195, 150),
            stops: [
              CssStop(rgba(255, 200, 130, .55), 0),
              CssStop(rgba(10, 7, 6, .92), .7),
            ],
          )
        : cssRadialFarthestCorner(
            box: size,
            center: Offset(size.width * .5, size.height * .45),
            stops: [
              CssStop(rgba(120, 20, 10, .6), 0),
              CssStop(rgba(7, 4, 4, .95), .7),
            ],
          );
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        // Swallows touches so the game below ignores them.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _escaped ? 'مرحله‌ی ${fa(levelId)}' : 'گیر افتادی',
                  style: TextStyle(
                    fontFamily: KFonts.ui,
                    fontSize: 12,
                    color: _escaped ? const Color(0xFFFFE2B0) : Kc.dangerSoft,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _escaped ? 'در را پیدا کردی.' : 'شکارچی به تو رسید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: KFonts.serif,
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: _escaped
                        ? Kc.headingBright
                        : const Color(0xFFF6E2D6),
                  ),
                ),
                const SizedBox(height: 18),
                PillButton(
                  label: 'ادامه',
                  height: 52,
                  fontSize: 15,
                  expand: false,
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
