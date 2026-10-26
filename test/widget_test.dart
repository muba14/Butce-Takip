import 'package:butce_takip/models.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringRule rule(Repeat f, {int day = 1, int weekday = 1, int month = 1}) =>
    RecurringRule(
      id: 't',
      type: EntryType.gider,
      category: 'Test',
      amount: 100,
      note: '',
      freq: f,
      day: day,
      weekday: weekday,
      month: month,
      last: DateTime(2026, 1, 1),
    );

void main() {
  test('Aylık: ayın 31i kısa aylarda son güne düşer', () {
    final r = rule(Repeat.aylik, day: 31);
    expect(r.nextAfter(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
    expect(r.nextAfter(DateTime(2026, 2, 28)), DateTime(2026, 3, 31));
  });

  test('Haftalık: bir sonraki cuma', () {
    final r = rule(Repeat.haftalik, weekday: DateTime.friday);
    // 26 Ekim 2026 pazartesi
    expect(r.nextAfter(DateTime(2026, 10, 26)), DateTime(2026, 10, 30));
  });

  test('Yıllık: tarih geçtiyse gelecek yıl', () {
    final r = rule(Repeat.yillik, day: 10, month: 8);
    expect(r.nextAfter(DateTime(2026, 10, 26)), DateTime(2027, 8, 10));
  });

  test('Son tekrar günü', () {
    final r = rule(Repeat.aylik, day: 1);
    expect(r.lastOnOrBefore(DateTime(2026, 10, 26)), DateTime(2026, 10, 1));
  });
}
