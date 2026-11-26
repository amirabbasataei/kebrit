/// Persian digit helpers (port of the design's `fa`).
const _digits = '۰۱۲۳۴۵۶۷۸۹';

String fa(int n) => n
    .toString()
    .split('')
    .map((c) {
      final i = c.codeUnitAt(0) - 0x30;
      return i >= 0 && i <= 9 ? _digits[i] : c;
    })
    .join();

/// `m:ss` in Persian digits, e.g. 102 s → «۱:۴۲». Negative durations clamp
/// to zero; minutes are not capped at 59.
String faTime(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final m = total ~/ 60, s = total % 60;
  return '${fa(m)}:${fa(s).padLeft(2, '۰')}';
}
