import 'package:flutter/widgets.dart';

import 'text_styles.dart';
import 'tokens.dart';

/// Default text style for the whole app (Vazirmatn, primary text colour).
const kDefaultTextStyle = TextStyle(
  fontFamily: KFonts.ui,
  fontSize: 14,
  color: Kc.text,
  decoration: TextDecoration.none,
);

/// Wraps [child] with the app-wide default text style on a dark page.
class KebritTheme extends StatelessWidget {
  const KebritTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Kc.page,
      child: DefaultTextStyle(style: kDefaultTextStyle, child: child),
    );
  }
}
