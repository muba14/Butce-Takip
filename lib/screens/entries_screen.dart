import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../widgets/category_sheet.dart';
import '../widgets/common.dart';

/// Gelirler ve Giderler sekmeleri aynı ekranı kullanır.
class EntriesScreen extends StatefulWidget {
  final BudgetStore store;
  final EntryType type;
  const EntriesScreen({super.key, required this.store, required this.type});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _Group {
  final Category cat;
  final List<Entry> list;
  final double sum;
  _Group(this.cat, this.list) : sum = list.fold(0.0, (s, e) => s + e.amount);
}

class _EntriesScreenState extends State<EntriesScreen> {
  final _note = TextEditingController();
  final _amount = TextEditingController();
  String? _selected;
  bool _editing = false;

  Repeat _repeat = Repeat.tek;
  DateTime _date = dateOnly(DateTime.now());
  int _day = DateTime.now().day;
  int _weekday = DateTime.now().weekday;
  bool _includeLast = true;

  BudgetStore get store => widget.store;
  EntryType get type => widget.type;
  bool get isIncome => type == EntryType.gelir;
  String get name => isIncome ? 'gelir' : 'gider';
  Color get color => isIncome ? AppColors.income : AppColors.expense;

  @override
  void dispose() {
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Formdaki seçimlere göre örnek kural (sonraki tarihi göstermek için).
  RecurringRule get _draftRule => RecurringRule(
        id: '',
        type: type,
        category: '',
        amount: 0,
        note: '',
        freq: _repeat,
        day: _repeat == Repeat.yillik ? _date.day : _day,
        weekday: _weekday,
        month: _date.month,
        last: dateOnly(DateTime.now()),
      );

  Future<void> _openSheet(Category? existing) async {
    final n = await showCategorySheet(context,
        store: store, type: type, existing: existing);
    if (!mounted) return;
    setState(() {
      if (existing == null && n != null) {
        _selected = n;
        _editing = false;
      } else if (existing != null && n != null && _selected == existing.name) {
        _selected = n;
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = dateOnly(d));
  }

  void _add(Category? cat) {
    final a = parseAmount(_amount.text);
    if (cat == null) {
      showToast(context, 'Önce bir başlık ekle');
      return;
    }
    if (a == null || a <= 0) {
      showToast(context, 'Geçerli bir tutar gir');
      return;
    }
    if (_repeat == Repeat.tek) {
      store.addEntry(type, cat.name, a, _note.text, _date);
      showToast(context, '${cat.name}: ${tl(a)} eklendi');
    } else {
      final r = store.addRule(
        type: type,
        category: cat.name,
        amount: a,
        note: _note.text,
        freq: _repeat,
        day: _repeat == Repeat.yillik ? _date.day : _day,
        weekday: _weekday,
        month: _date.month,
        includeLast: _includeLast,
      );
      showToast(context, 'Düzenli $name eklendi · ${r.description}');
    }
    _amount.clear();
    _note.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cats = store.categories[type]!;
    if (_selected != null && store.category(type, _selected!) == null) {
      _selected = null;
    }
    final current = _selected != null
        ? store.category(type, _selected!)
        : (cats.isNotEmpty ? cats.first : null);

    final month = store.entries
        .where((e) => e.type == type && BudgetStore.isThisMonth(e))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total = month.fold(0.0, (s, e) => s + e.amount);
    final groups = [
      for (final c in cats)
        if (month.any((e) => e.category == c.name))
          _Group(c, month.where((e) => e.category == c.name).toList()),
    ]..sort((a, b) => b.sum.compareTo(a.sum));
    final rules = store.rules.where((r) => r.type == type).toList();
    final perMonth = rules.fold(0.0, (s, r) => s + r.perMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
      children: [
        _hero(total, month.length, groups, rules.isNotEmpty, perMonth),
        const SizedBox(height: 14),
        SectionTitle('Yeni $name ekle'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _gridHeader(),
                const SizedBox(height: 10),
                _categoryGrid(cats, current),
                const SizedBox(height: 14),
                if (current == null)
                  _muted('Önce bir başlık ekle.')
                else
                  ..._form(current),
              ],
            ),
          ),
        ),
        if (rules.isNotEmpty) ...[
          const SizedBox(height: 14),
          SectionTitle(
            isIncome ? 'Düzenli gelirler' : 'Düzenli giderler',
            trailing: Text('Aylık ort. ${tl(perMonth)}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
              child: Column(children: [for (final r in rules) _ruleRow(r)]),
            ),
          ),
        ],
        const SizedBox(height: 14),
        const SectionTitle('Başlıklara göre · bu ay'),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _muted(
                  'Bu ay henüz $name yok. Yukarıdan bir başlık seçip tutar gir.'),
            ),
          ),
        for (final g in groups) ...[
          _groupCard(g, total),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ---------- Üst kart ----------

  Widget _hero(double total, int count, List<_Group> groups, bool hasRules,
      double perMonth) {
    final grad =
        isIncome ? AppColors.incomeGradient : AppColors.expenseGradient;
    final lm = store.lastMonthTotal(type);
    final pct = lm > 0 ? ((total - lm) / lm * 100).round() : null;
    final now = DateTime.now();

    Widget circle(double s) => Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
              color: Colors.white.withAlpha(20), shape: BoxShape.circle),
        );

    Widget pill(IconData i, String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(46),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(t,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ]),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: grad[1].withAlpha(80),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -8),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -50, top: -70, child: circle(180)),
          Positioned(right: 40, bottom: -60, child: circle(110)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${aylar[now.month - 1]} · toplam $name',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(tl(total),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: tabular)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(46),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                          isIncome
                              ? Icons.trending_up_rounded
                              : Icons.shopping_bag_rounded,
                          color: Colors.white,
                          size: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  pill(Icons.receipt_rounded, '$count kayıt'),
                  if (pct != null)
                    pill(
                        pct >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        'Geçen aya göre %${pct.abs()}'),
                  if (hasRules)
                    pill(Icons.autorenew_rounded, 'Düzenli ${tl(perMonth)}/ay'),
                ]),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 8,
                    color: Colors.white.withAlpha(50),
                    child: Row(children: [
                      for (final g in groups)
                        Expanded(
                          flex: math.max(1, (g.sum / total * 1000).round()),
                          child: Container(
                              margin: const EdgeInsets.only(right: 2),
                              color: g.cat.c),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Başlık ızgarası ----------

  Widget _gridHeader() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Expanded(
          child: Text(
              _editing ? 'Düzenlemek istediğin başlığa dokun' : 'Başlık seç',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: muted)),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
              foregroundColor: AppColors.blue,
              visualDensity: VisualDensity.compact),
          onPressed: () => setState(() => _editing = !_editing),
          icon: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded,
              size: 17),
          label: Text(_editing ? 'Bitti' : 'Düzenle'),
        ),
      ],
    );
  }

  Widget _categoryGrid(List<Category> cats, Category? current) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget tile(Category c) {
      final on = !_editing && c == current;
      return Material(
        color: on ? c.c : fill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editing
              ? _openSheet(c)
              : setState(() => _selected = c.name),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CatIcon(iconFor(c.icon), on ? Colors.white : c.c),
                      const SizedBox(height: 6),
                      Text(c.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.15,
                              fontWeight: FontWeight.w500,
                              color: on ? Colors.white : null)),
                    ],
                  ),
                ),
              ),
              if (_editing)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                        color: AppColors.navy, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final addTile = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openSheet(null),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CatIcon(Icons.add_rounded, muted),
            const SizedBox(height: 6),
            Text('Başlık ekle',
                style: TextStyle(fontSize: 11.5, color: muted)),
          ],
        ),
      ),
    );

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: .8,
      children: [for (final c in cats) tile(c), addTile],
    );
  }

  // ---------- Form ----------

  List<Widget> _form(Category cur) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final today = dateOnly(DateTime.now());
    final rule = _draftRule;
    final prev = _repeat == Repeat.tek ? null : rule.lastOnOrBefore(today);

    Widget box({required Widget child, VoidCallback? onTap}) => Material(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: child,
            ),
          ),
        );

    return [
      box(
        child: Row(children: [
          CatIcon(iconFor(cur.icon), cur.c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cur.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Seçili başlık',
                    style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: '0',
          prefixText: '₺ ',
          prefixStyle: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: muted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _note,
        decoration: const InputDecoration(hintText: 'Açıklama (isteğe bağlı)'),
      ),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text('TEKRAR',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: .5,
                color: muted)),
      ),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<Repeat>(
          segments: const [
            ButtonSegment(value: Repeat.tek, label: Text('Tek sefer')),
            ButtonSegment(value: Repeat.haftalik, label: Text('Haftalık')),
            ButtonSegment(value: Repeat.aylik, label: Text('Aylık')),
            ButtonSegment(value: Repeat.yillik, label: Text('Yıllık')),
          ],
          selected: {_repeat},
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.navy,
            selectedForegroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            textStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          onSelectionChanged: (s) => setState(() => _repeat = s.first),
        ),
      ),
      const SizedBox(height: 10),
      if (_repeat == Repeat.tek || _repeat == Repeat.yillik)
        box(
          onTap: _pickDate,
          child: Row(children: [
            Icon(Icons.calendar_month_rounded, size: 20, color: muted),
            const SizedBox(width: 10),
            Text(_repeat == Repeat.tek ? 'Tarih' : 'Her yıl'),
            const Spacer(),
            Text(
              _repeat == Repeat.tek
                  ? longDate(_date)
                  : '${_date.day} ${aylar[_date.month - 1]}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      if (_repeat == Repeat.haftalik)
        Row(children: [
          for (var i = 1; i <= 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: _weekday == i ? AppColors.navy : fill,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _weekday = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(gunlerKisa[i - 1],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _weekday == i ? Colors.white : null)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      if (_repeat == Repeat.aylik) ...[
        box(
          child: Row(children: [
            const Text('Her ayın'),
            const SizedBox(width: 10),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _day,
                isDense: true,
                borderRadius: BorderRadius.circular(14),
                menuMaxHeight: 320,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface),
                items: [
                  for (var d = 1; d <= 31; d++)
                    DropdownMenuItem(value: d, child: Text('$d')),
                ],
                onChanged: (v) => setState(() => _day = v ?? _day),
              ),
            ),
            const SizedBox(width: 6),
            const Text('günü'),
          ]),
        ),
        if (_day > 28)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text('Bu gün olmayan aylarda ayın son günü eklenir.',
                style: TextStyle(fontSize: 12, color: muted)),
          ),
      ],
      if (_repeat != Repeat.tek) ...[
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.event_repeat_rounded, size: 15, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${rule.description} otomatik eklenir · Sonraki: ${shortDay(rule.nextAfter(today))}',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
        ]),
        if (prev != null)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.navy,
            value: _includeLast,
            onChanged: (v) => setState(() => _includeLast = v ?? true),
            title: Text('${shortDay(prev)} tarihli kaydı da şimdi ekle'),
          ),
      ],
      const SizedBox(height: 10),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => _add(cur),
        icon: Icon(
            _repeat == Repeat.tek ? Icons.add_rounded : Icons.autorenew_rounded),
        label: Text(_repeat == Repeat.tek
            ? '${cur.name} olarak ekle'
            : 'Düzenli $name olarak ekle'),
      ),
    ];
  }

  // ---------- Listeler ----------

  Widget _ruleRow(RecurringRule r) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final today = dateOnly(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        CatIcon(store.iconOf(type, r.category), store.colorFor(type, r.category),
            size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: r.category,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (r.note.isNotEmpty)
                    TextSpan(
                        text: ' · ${r.note}', style: TextStyle(color: muted)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${r.description} · Sonraki ${shortDay(r.nextAfter(today))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted)),
            ],
          ),
        ),
        Text(tl(r.amount),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: tabular)),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Düzenli kaydı durdur',
          icon: Icon(Icons.close_rounded, size: 18, color: muted),
          onPressed: () {
            store.removeRule(r.id);
            showToast(
                context, 'Düzenli kayıt durduruldu, geçmiş kayıtlar duruyor');
          },
        ),
      ]),
    );
  }

  Widget _groupCard(_Group g, double total) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final share = total > 0 ? g.sum / total : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 4, 6),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(children: [
                CatIcon(iconFor(g.cat.icon), g.cat.c),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${g.list.length} kayıt · %${(share * 100).round()}',
                          style: TextStyle(fontSize: 12, color: muted)),
                    ],
                  ),
                ),
                Text(tl(g.sum),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFeatures: tabular)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 6,
                  color: g.cat.c,
                  backgroundColor:
                      Theme.of(context).inputDecorationTheme.fillColor,
                ),
              ),
            ),
            for (final e in g.list) EntryRow(entry: e, store: store),
          ],
        ),
      ),
    );
  }

  Widget _muted(String t) => Text(t,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant));
}
