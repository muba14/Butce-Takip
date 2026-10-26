import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';

/// Siyah cüzdan görünümlü hesap kartı; içinde hesap tutarı yazar.
class WalletCard extends StatelessWidget {
  final double amount;
  final VoidCallback onEdit;

  const WalletCard({super.key, required this.amount, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Üst kapak
            Positioned(
              left: w * .08,
              right: w * .10,
              top: 0,
              height: 40,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.wallet,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(
                    top: 14, left: w * .14, right: w * .10),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            // Gövde (üstte beyaz şerit)
            Positioned.fill(
              top: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 30,
                        offset: Offset(0, 14),
                        spreadRadius: -12),
                  ],
                ),
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 80, 18),
                  decoration: BoxDecoration(
                    color: AppColors.wallet,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HESAP TUTARI',
                          style: TextStyle(
                              color: Colors.white.withAlpha(153),
                              fontSize: 11,
                              letterSpacing: 1.3)),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tl(amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(30),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Tutarı düzenle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Kilit (sağdaki toka): beyaz çerçeve, sağ kenar açık
            Positioned(
              right: -6,
              top: 30 + 90 - 18,
              child: Container(
                width: 62,
                height: 46,
                padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(14)),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.wallet,
                    borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(10)),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
