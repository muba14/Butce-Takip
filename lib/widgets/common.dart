import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';

const tabular = [FontFeature.tabularFigures()];

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class Dot extends StatelessWidget {
  final Color color;
  final double size;
  const Dot(this.color, {super.key, this.size = 10});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Renkli, yumuşak arka planlı başlık simgesi.
class CatIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool solid;

  const CatIcon(this.icon, this.color,
      {super.key, this.size = 38, this.solid = false});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: solid ? color : color.withAlpha(38),
          borderRadius: BorderRadius.circular(size * .32),
        ),
        child: Icon(icon,
            size: size * .55, color: solid ? Colors.white : color),
      );
}

class EntryRow extends StatelessWidget {
  final Entry entry;
  final BudgetStore store;
  final bool withIcon;

  const EntryRow(
      {super.key,
      required this.entry,
      required this.store,
      this.withIcon = false});

  @override
  Widget build(BuildContext context) {
    final inc = entry.type == EntryType.gelir;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final sub = shortDate(entry.date) +
        (entry.note.isNotEmpty ? ' · ${entry.note}' : '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (withIcon) ...[
            CatIcon(store.iconOf(entry.type, entry.category),
                store.colorFor(entry.type, entry.category),
                size: 32),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(entry.category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  if (entry.ruleId != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.autorenew_rounded, size: 14, color: muted),
                  ],
                ]),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ),
          Text(
            '${inc ? '+' : '−'}${tl(entry.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: inc ? AppColors.income : AppColors.expense,
              fontFeatures: tabular,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Kaydı sil',
            icon: Icon(Icons.close_rounded, size: 18, color: muted),
            onPressed: () {
              store.removeEntry(entry.id);
              showToast(context, 'Kayıt silindi');
            },
          ),
        ],
      ),
    );
  }
}

void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 100),
      shape: const StadiumBorder(),
      duration: const Duration(milliseconds: 1800),
    ));
}

/// Tek alanlı alt sayfa (hesap tutarı girmek için).
Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  bool number = false,
  required String action,
}) {
  final ctrl = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(action),
          ),
        ],
      ),
    ),
  );
}
