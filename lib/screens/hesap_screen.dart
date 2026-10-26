import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/wallet_card.dart';

class HesapScreen extends StatelessWidget {
  final BudgetStore store;
  const HesapScreen({super.key, required this.store});

  Future<void> _edit(BuildContext context) async {
    final v = await askText(
      context,
      title: 'Hesaptaki para',
      initial: store.balance == 0 ? '' : store.balance.toStringAsFixed(0),
      hint: 'Örn. 24500',
      number: true,
      action: 'Kaydet',
    );
    if (v == null) return;
    final n = parseAmount(v);
    if (n == null) return;
    store.setBalance(n);
    if (context.mounted) showToast(context, 'Hesap tutarı güncellendi');
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final gi = store.monthTotal(EntryType.gelir);
    final ge = store.monthTotal(EntryType.gider);
    final proj = store.projected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
      children: [
        const SizedBox(height: 8),
        WalletCard(amount: store.balance, onEdit: () => _edit(context)),
        const SizedBox(height: 14),
        SectionTitle('${monthYear(DateTime.now())} özeti'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Stat('Bu ay gelir', '+${tl(gi)}', AppColors.income)),
            const SizedBox(width: 10),
            Expanded(child: _Stat('Bu ay gider', '−${tl(ge)}', AppColors.expense)),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ay sonu tahmini bakiye',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('Hesap + gelir − gider',
                          style: TextStyle(fontSize: 12, color: muted)),
                    ],
                  ),
                ),
                Text(
                  tl(proj),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: proj >= 0 ? AppColors.income : AppColors.expense,
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionTitle('Son hareketler'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
            child: store.recent.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Henüz kayıt yok. Gelirler veya Giderler sekmesinden ilk kaydını ekle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  )
                : Column(
                    children: [
                      for (final e in store.recent)
                        EntryRow(entry: e, store: store, withIcon: true),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFeatures: tabular)),
              ),
            ],
          ),
        ),
      );
}
