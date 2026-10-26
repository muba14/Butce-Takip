import 'package:flutter/material.dart';

import '../models.dart';

class PillItem {
  final String label;
  final IconData icon;
  const PillItem(this.label, this.icon);
}

/// Altta ortada yüzen, hap şeklinde sekme çubuğu.
class PillNav extends StatelessWidget {
  final List<PillItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  const PillNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
              color: Color(0x660A1428), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (i) {
          final on = i == index;
          final c = on ? Colors.white : Colors.white.withAlpha(166);
          return GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: on ? AppColors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].icon, size: 20, color: c),
                  const SizedBox(height: 2),
                  Text(items[i].label,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: c)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
