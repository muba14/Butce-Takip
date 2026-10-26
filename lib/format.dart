import 'package:intl/intl.dart';

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

String tl(double v) => _tl.format(v);

String shortDate(DateTime d) => DateFormat('d MMM', 'tr_TR').format(d);

String longDate(DateTime d) => DateFormat('d MMMM y', 'tr_TR').format(d);

String monthShort(DateTime d) => DateFormat('MMM', 'tr_TR').format(d);

String monthYear(DateTime d) => DateFormat('MMMM y', 'tr_TR').format(d);

/// "1.250,50" veya "1250.5" gibi girişleri sayıya çevirir.
double? parseAmount(String s) {
  var t = s.trim().replaceAll(' ', '');
  if (t.contains(',')) t = t.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(t);
}
