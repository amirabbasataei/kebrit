/// Persian-digit text. Wraps `fa()` / `faDigits()` from `data/persian.dart` so
/// screens never show ASCII digits (PLAN §0.1).
library;

import 'package:flutter/widgets.dart';

import '../../data/persian.dart';

class FaText extends StatelessWidget {
  /// Shows [data] with every ASCII digit replaced by its Persian form.
  const FaText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
  })  : number = null;

  /// Shows the integer [n] in Persian digits.
  const FaText.number(
    int n, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
  })  : number = n,
        data = '';

  final String data;
  final int? number;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Text(
        number != null ? fa(number!) : faDigits(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: semanticsLabel,
      );
}
