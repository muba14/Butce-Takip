import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'icons.dart';

enum EntryType { gelir, gider }

/// Tek sefer veya düzenli tekrar
enum Repeat { tek, haftalik, aylik, yillik }

const aylar = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];
const gunler = [
  'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
];
const gunlerKisa = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
int daysIn(int year, int month) => DateTime(year, month + 1, 0).day;
String shortDay(DateTime d) => '${d.day} ${aylar[d.month - 1].substring(0, 3)}';

class Category {
  String name;
  String icon;
  int color;

  Category(this.name, this.icon, this.color);

  Color get c => Color(color);

  Map<String, dynamic> toJson() => {'n': name, 'i': icon, 'c': color};

  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(j['n'] as String, j['i'] as String, j['c'] as int);
}

class Entry {
  final String id;
  final EntryType type;
  String category;
  final double amount;
  final DateTime date;
  final String note;
  final String? ruleId;

  Entry({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.ruleId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        't': type.name,
        'c': category,
        'a': amount,
        'd': date.toIso8601String(),
        'n': note,
        if (ruleId != null) 'r': ruleId,
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        type: EntryType.values.byName(j['t'] as String),
        category: j['c'] as String,
        amount: (j['a'] as num).toDouble(),
        date: DateTime.parse(j['d'] as String),
        note: (j['n'] ?? '') as String,
        ruleId: j['r'] as String?,
      );
}

/// Düzenli gelir/gider kuralı. Zamanı gelen kayıtlar otomatik eklenir.
class RecurringRule {
  final String id;
  final EntryType type;
  String category;
  final double amount;
  final String note;
  final Repeat freq; // haftalik, aylik veya yillik
  final int day; // aylık/yıllık: ayın günü (1-31)
  final int weekday; // haftalık: 1 = Pazartesi … 7 = Pazar
  final int month; // yıllık: 1-12
  DateTime last; // en son eklenen kaydın tarihi

  RecurringRule({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
    required this.freq,
    this.day = 1,
    this.weekday = 1,
    this.month = 1,
    required this.last,
  });

  /// [d] tarihinden sonraki ilk tekrar günü
  DateTime nextAfter(DateTime d) {
    d = dateOnly(d);
    if (freq == Repeat.haftalik) {
      var x = DateTime(d.year, d.month, d.day + 1);
      while (x.weekday != weekday) {
        x = DateTime(x.year, x.month, x.day + 1);
      }
      return x;
    }
    if (freq == Repeat.aylik) {
      for (var k = 0; k < 3; k++) {
        final first = DateTime(d.year, d.month + k, 1);
        final o = DateTime(first.year, first.month,
            math.min(day, daysIn(first.year, first.month)));
        if (o.isAfter(d)) return o;
      }
    }
    for (var k = 0; k < 3; k++) {
      final y = d.year + k;
      final o = DateTime(y, month, math.min(day, daysIn(y, month)));
      if (o.isAfter(d)) return o;
    }
    return DateTime(d.year + 1, d.month, d.day);
  }

  /// [t] gününe kadar (dahil) son tekrar günü
  DateTime? lastOnOrBefore(DateTime t) {
    t = dateOnly(t);
    var x = nextAfter(t.subtract(const Duration(days: 400)));
    DateTime? prev;
    while (!x.isAfter(t)) {
      prev = x;
      x = nextAfter(x);
    }
    return prev;
  }

  String get description => switch (freq) {
        Repeat.haftalik => 'Her ${gunler[weekday - 1]}',
        Repeat.aylik => 'Her ayın $day. günü',
        Repeat.yillik => 'Her yıl $day ${aylar[month - 1]}',
        Repeat.tek => 'Tek sefer',
      };

  double get perMonth => switch (freq) {
        Repeat.haftalik => amount * 52 / 12,
        Repeat.yillik => amount / 12,
        _ => amount,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        't': type.name,
        'c': category,
        'a': amount,
        'n': note,
        'f': freq.name,
        'day': day,
        'wd': weekday,
        'mon': month,
        'last': last.toIso8601String(),
      };

  factory RecurringRule.fromJson(Map<String, dynamic> j) => RecurringRule(
        id: j['id'] as String,
        type: EntryType.values.byName(j['t'] as String),
        category: j['c'] as String,
        amount: (j['a'] as num).toDouble(),
        note: (j['n'] ?? '') as String,
        freq: Repeat.values.byName(j['f'] as String),
        day: j['day'] as int,
        weekday: j['wd'] as int,
        month: j['mon'] as int,
        last: DateTime.parse(j['last'] as String),
      );
}

Map<EntryType, List<Category>> defaultCategories() => {
      EntryType.gider: [
        Category('Barınma', 'home', 0xFFE0524A),
        Category('Market', 'shopping_cart', 0xFFF2A93B),
        Category('Fatura', 'receipt_long', 0xFF2A86EE),
        Category('Ulaşım', 'directions_bus', 0xFF14B8C4),
        Category('Eğlence', 'sports_esports', 0xFF8B5CF6),
        Category('Abonelik', 'subscriptions', 0xFFE5609B),
        Category('Sigorta', 'shield', 0xFF4F5BD5),
        Category('Sağlık', 'medical_services', 0xFF18A473),
        Category('Eğitim', 'school', 0xFFF07A2B),
        Category('Yemek', 'restaurant', 0xFFB45309),
        Category('Giyim', 'checkroom', 0xFFDB2777),
        Category('Kredi Kartı', 'credit_card', 0xFF475569),
        Category('Spor', 'fitness_center', 0xFF65A30D),
        Category('Evcil Hayvan', 'pets', 0xFF0D9488),
        Category('Hediye', 'card_giftcard', 0xFFC026D3),
      ],
      EntryType.gelir: [
        Category('Maaş', 'payments', 0xFF18A473),
        Category('Burs', 'school', 0xFF2A86EE),
        Category('Ek İş', 'work', 0xFFF2A93B),
        Category('Harçlık', 'savings', 0xFFE5609B),
        Category('Kira Geliri', 'apartment', 0xFF4F5BD5),
        Category('Yatırım', 'trending_up', 0xFF14B8C4),
        Category('Prim', 'emoji_events', 0xFFF07A2B),
        Category('Satış', 'sell', 0xFF8B5CF6),
        Category('Hediye', 'redeem', 0xFFC026D3),
        Category('İade', 'currency_exchange', 0xFF475569),
      ],
    };

class MonthSummary {
  final DateTime month;
  final double income;
  final double expense;
  MonthSummary(this.month, this.income, this.expense);
}

/// Uygulamanın tüm verisini tutar ve cihazda saklar.
class BudgetStore extends ChangeNotifier {
  static const _key = 'butce_takip_v1';

  double balance = 0;
  Map<EntryType, List<Category>> categories = defaultCategories();
  final List<Entry> entries = [];
  final List<RecurringRule> rules = [];

  SharedPreferences? _prefs;
  int _seq = 0;

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        balance = (j['balance'] as num).toDouble();
        final cats = j['cats'] as Map<String, dynamic>;
        final defs = defaultCategories();
        for (final t in EntryType.values) {
          final list = cats[t.name] as List;
          categories[t] = [
            for (var i = 0; i < list.length; i++)
              // 1.0 sürümünde başlıklar yalnızca isim olarak saklanıyordu
              if (list[i] is String)
                defs[t]!.firstWhere(
                  (c) => c.name == list[i],
                  orElse: () => Category(list[i] as String, 'category',
                      kPalette[i % kPalette.length]),
                )
              else
                Category.fromJson(list[i] as Map<String, dynamic>),
          ];
        }
        entries
          ..clear()
          ..addAll((j['entries'] as List)
              .map((e) => Entry.fromJson(e as Map<String, dynamic>)));
        rules
          ..clear()
          ..addAll(((j['rules'] ?? []) as List)
              .map((e) => RecurringRule.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // Bozuk kayıt varsa varsayılanlarla devam et.
      }
    }
    if (applyRules() > 0) _save();
  }

  /// Zamanı gelmiş düzenli kayıtları ekler; eklenen kayıt sayısını döner.
  int applyRules() {
    final today = dateOnly(DateTime.now());
    var added = 0;
    for (final r in rules) {
      var x = r.nextAfter(r.last);
      while (!x.isAfter(today)) {
        entries.add(Entry(
          id: _id(),
          type: r.type,
          category: r.category,
          amount: r.amount,
          date: x,
          note: r.note,
          ruleId: r.id,
        ));
        r.last = x;
        x = r.nextAfter(x);
        added++;
      }
    }
    return added;
  }

  /// Uygulama yeniden açıldığında gün değişmiş olabilir.
  void refresh() {
    if (applyRules() > 0) _save();
  }

  void _save() {
    _prefs?.setString(
      _key,
      jsonEncode({
        'balance': balance,
        'cats': {
          for (final t in EntryType.values)
            t.name: categories[t]!.map((c) => c.toJson()).toList()
        },
        'entries': entries.map((e) => e.toJson()).toList(),
        'rules': rules.map((r) => r.toJson()).toList(),
      }),
    );
    notifyListeners();
  }

  void setBalance(double v) {
    balance = v;
    _save();
  }

  Category? category(EntryType t, String name) {
    for (final c in categories[t]!) {
      if (c.name == name) return c;
    }
    return null;
  }

  Color colorFor(EntryType t, String name) =>
      category(t, name)?.c ?? const Color(0xFF7A8599);

  IconData iconOf(EntryType t, String name) =>
      iconFor(category(t, name)?.icon ?? 'category');

  bool nameTaken(EntryType t, String name, {Category? except}) =>
      categories[t]!.any((c) => c.name == name && c != except);

  bool addCategory(EntryType t, String name, String icon, int color) {
    final n = name.trim();
    if (n.isEmpty || nameTaken(t, n)) return false;
    categories[t]!.add(Category(n, icon, color));
    _save();
    return true;
  }

  bool updateCategory(
      EntryType t, Category cat, String name, String icon, int color) {
    final n = name.trim();
    if (n.isEmpty || nameTaken(t, n, except: cat)) return false;
    final old = cat.name;
    cat
      ..name = n
      ..icon = icon
      ..color = color;
    if (old != n) {
      for (final e in entries) {
        if (e.type == t && e.category == old) e.category = n;
      }
      for (final r in rules) {
        if (r.type == t && r.category == old) r.category = n;
      }
    }
    _save();
    return true;
  }

  void removeCategory(EntryType t, Category cat) {
    categories[t]!.remove(cat);
    entries.removeWhere((e) => e.type == t && e.category == cat.name);
    rules.removeWhere((r) => r.type == t && r.category == cat.name);
    _save();
  }

  void addEntry(EntryType t, String category, double amount, String note,
      DateTime date) {
    entries.add(Entry(
      id: _id(),
      type: t,
      category: category,
      amount: amount,
      date: dateOnly(date),
      note: note.trim(),
    ));
    _save();
  }

  /// Düzenli kayıt ekler. [includeLast] açıksa bugüne kadarki son tekrar da eklenir.
  RecurringRule addRule({
    required EntryType type,
    required String category,
    required double amount,
    required String note,
    required Repeat freq,
    int day = 1,
    int weekday = 1,
    int month = 1,
    bool includeLast = true,
  }) {
    final today = dateOnly(DateTime.now());
    final r = RecurringRule(
      id: _id(),
      type: type,
      category: category,
      amount: amount,
      note: note.trim(),
      freq: freq,
      day: day,
      weekday: weekday,
      month: month,
      last: today,
    );
    final prev = r.lastOnOrBefore(today);
    if (includeLast && prev != null) {
      r.last = prev.subtract(const Duration(days: 1));
    }
    rules.add(r);
    applyRules();
    _save();
    return r;
  }

  void removeRule(String id) {
    rules.removeWhere((r) => r.id == id);
    _save();
  }

  void removeEntry(String id) {
    entries.removeWhere((e) => e.id == id);
    _save();
  }

  static bool isThisMonth(Entry e) {
    final n = DateTime.now();
    return e.date.year == n.year && e.date.month == n.month;
  }

  double total(EntryType t, {bool Function(Entry)? where}) => entries
      .where((e) => e.type == t && (where == null || where(e)))
      .fold(0.0, (s, e) => s + e.amount);

  double monthTotal(EntryType t) => total(t, where: isThisMonth);

  double lastMonthTotal(EntryType t) {
    final n = DateTime.now();
    final m = DateTime(n.year, n.month - 1);
    return total(t,
        where: (e) => e.date.year == m.year && e.date.month == m.month);
  }

  /// Hesap + bu ayın gelirleri − bu ayın giderleri
  double get projected =>
      balance + monthTotal(EntryType.gelir) - monthTotal(EntryType.gider);

  List<Entry> get recent {
    final today = dateOnly(DateTime.now());
    return (entries.where((e) => !e.date.isAfter(today)).toList()
          ..sort((a, b) => b.date.compareTo(a.date)))
        .take(5)
        .toList();
  }

  List<MonthSummary> lastMonths(int count) {
    final n = DateTime.now();
    return List.generate(count, (i) {
      final m = DateTime(n.year, n.month - (count - 1 - i));
      bool inMonth(Entry e) => e.date.year == m.year && e.date.month == m.month;
      return MonthSummary(
        m,
        total(EntryType.gelir, where: inMonth),
        total(EntryType.gider, where: inMonth),
      );
    });
  }
}

class AppColors {
  static const navy = Color(0xFF1F2E47);
  static const blue = Color(0xFF2A86EE);
  static const blueDark = Color(0xFF2E5FBE);
  static const wallet = Color(0xFF0B0D12);
  static const income = Color(0xFF18A473);
  static const expense = Color(0xFFE0524A);
  static const incomeGradient = [Color(0xFF1DB781), Color(0xFF0A7350)];
  static const expenseGradient = [Color(0xFFF0705F), Color(0xFFB3302B)];
}
