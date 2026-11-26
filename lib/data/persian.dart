/// Persian digit helpers (port of the design's `fa`).
const _digits = '۰۱۲۳۴۵۶۷۸۹';

/// Replaces every ASCII digit in [s] with its Persian form.
String faDigits(String s) => s.split('').map((c) {
  final i = c.codeUnitAt(0) - 0x30;
  return c.length == 1 && i >= 0 && i <= 9 ? _digits[i] : c;
}).join();

String fa(int n) => faDigits(n.toString());

/// `m:ss` in Persian digits, e.g. 102 s → «۱:۴۲». Negative durations clamp
/// to zero; minutes are not capped at 59.
String faTime(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final m = total ~/ 60, s = total % 60;
  return '${fa(m)}:${fa(s).padLeft(2, '۰')}';
}
