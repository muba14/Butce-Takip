import 'package:flutter/material.dart';

import '../icons.dart';
import '../models.dart';
import 'common.dart';

/// Başlık ekleme / düzenleme alt sayfası: isim, simge ve renk seçimi.
/// Yeni başlık eklenirse adını döner.
Future<String?> showCategorySheet(
  BuildContext context, {
  required BudgetStore store,
  required EntryType type,
  Category? existing,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _CategorySheet(store: store, type: type, existing: existing),
  );
}

class _CategorySheet extends StatefulWidget {
  final BudgetStore store;
  final EntryType type;
  final Category? existing;

  const _CategorySheet(
      {required this.store, required this.type, this.existing});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final TextEditingController _name;
  late String _icon;
  late int _color;
  bool _armed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _icon = e?.icon ?? 'category';
    _color = e?.color ??
        kPalette[widget.store.categories[widget.type]!.length %
            kPalette.length];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Başlığa bir isim ver');
      return;
    }
    final ex = widget.existing;
    final ok = ex == null
        ? widget.store.addCategory(widget.type, n, _icon, _color)
        : widget.store.updateCategory(widget.type, ex, n, _icon, _color);
    if (!ok) {
      setState(() => _error = 'Bu isimde bir başlık zaten var');
      return;
    }
    showToast(context, ex == null ? 'Başlık eklendi' : 'Başlık güncellendi');
    Navigator.pop(context, n);
  }

  void _delete() {
    if (!_armed) {
      setState(() => _armed = true);
      return;
    }
    widget.store.removeCategory(widget.type, widget.existing!);
    showToast(context, 'Başlık silindi');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_color);
    final isEdit = widget.existing != null;
    final surface2 = Theme.of(context).inputDecorationTheme.fillColor;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit
                    ? 'Başlığı düzenle'
                    : 'Yeni ${widget.type == EntryType.gelir ? 'gelir' : 'gider'} başlığı',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CatIcon(iconFor(_icon), color, size: 52, solid: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      autofocus: !isEdit,
                      maxLength: 18,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.type == EntryType.gider
                            ? 'Örn. Bakım'
                            : 'Örn. Kira geliri',
                        counterText: '',
                        errorText: _error,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _Label('SİMGE'),
              GridView.count(
                crossAxisCount: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final e in kIcons.entries)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _icon = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: e.key == _icon ? color : surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(e.value,
                            size: 20,
                            color: e.key == _icon ? Colors.white : null),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _Label('RENK'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in kPalette)
                    GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c == _color
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: c == _color
                            ? const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: Text(isEdit ? 'Kaydet' : 'Başlığı ekle'),
              ),
              if (isEdit) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: BorderSide(color: AppColors.expense.withAlpha(100)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_armed
                      ? Icons.warning_amber_rounded
                      : Icons.delete_outline_rounded),
                  label: Text(_armed
                      ? 'Emin misin? Kayıtları da silinir'
                      : 'Başlığı sil'),
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: .5,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}
