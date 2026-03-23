import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cricket_live_score/core/utils/ad_helper.dart';
import 'package:cricket_live_score/features/wallet/presentation/bloc/wallet_cubit.dart';

class WalletChip extends StatelessWidget {
  const WalletChip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.06);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.12);

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            AdHelper.showInterstitialAd(() {
              context.push('/wallet');
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/coin_sticker.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  state.irCoins >= 1000
                      ? '${(state.irCoins / 1000).toStringAsFixed(1)}k'
                      : state.irCoins.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 6),
                Image.asset(
                  'assets/images/red_cricket_ball_sticker.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${state.balls}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
