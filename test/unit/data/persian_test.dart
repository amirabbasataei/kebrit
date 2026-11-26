import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/persian.dart';

void main() {
  test('fa converts digits', () {
    expect(fa(0), '۰');
    expect(fa(7), '۷');
    expect(fa(1234567890), '۱۲۳۴۵۶۷۸۹۰');
    expect(fa(-5), '-۵');
  });

  test('faTime formats m:ss', () {
    expect(faTime(const Duration(seconds: 102)), '۱:۴۲');
    expect(faTime(Duration.zero), '۰:۰۰');
    expect(faTime(const Duration(seconds: 9)), '۰:۰۹');
    expect(faTime(const Duration(minutes: 62, seconds: 5)), '۶۲:۰۵');
    expect(faTime(const Duration(seconds: -4)), '۰:۰۰');
  });
}
