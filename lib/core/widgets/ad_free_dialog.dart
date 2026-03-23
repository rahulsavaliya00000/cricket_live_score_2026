import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricket_live_score/core/constants/app_colors.dart';
import 'package:cricket_live_score/core/di/injection_container.dart';
import 'package:cricket_live_score/core/services/revenue_cat_service.dart';
import 'package:cricket_live_score/core/utils/ad_helper.dart';
import 'package:cricket_live_score/features/profile/presentation/bloc/premium_bloc.dart';

/// Shows the "Go Ad-Free" upsell dialog.
/// Call [AdFreeDialog.show] from anywhere you have a [BuildContext].
class AdFreeDialog {
  static Future<void> show(BuildContext context) {
    // Never show to premium users
    if (AdHelper.isPremium) return Future.value();

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Ad Free Dialog',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => const _AdFreeDialogContent(),
    );
  }
}

class _AdFreeDialogContent extends StatefulWidget {
  const _AdFreeDialogContent();

  @override
  State<_AdFreeDialogContent> createState() => _AdFreeDialogContentState();
}

class _AdFreeDialogContentState extends State<_AdFreeDialogContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  final _rcService = sl<RevenueCatService>();
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;

    return BlocListener<PremiumBloc, PremiumState>(
      listenWhen: (previous, current) =>
          !previous.isPremium && current.isPremium,
      listener: (context, state) {
        // User just purchased — close the dialog automatically
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: math.min(screenW - 48, 360),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1F35), const Color(0xFF0D1117)]
                    : [Colors.white, const Color(0xFFF0F9F5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(isDark ? 0.3 : 0.15),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header gradient band ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(27),
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A86B), Color(0xFF00C853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Animated crown icon
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (_, __) {
                          final glow =
                              (math.sin(
                                    _shimmerController.value * 2 * math.pi,
                                  ) +
                                  1) /
                              2;
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(
                                    0.1 + 0.25 * glow,
                                  ),
                                  blurRadius: 20 + 10 * glow,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enjoying the App?',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Go completely Ad-Free forever',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                  child: Column(
                    children: [
                      // Feature rows
                      _FeatureRow(
                        icon: Icons.block_rounded,
                        iconColor: AppColors.liveRed,
                        text: 'Zero ads - forever',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _FeatureRow(
                        icon: Icons.picture_in_picture_alt_rounded,
                        iconColor: const Color(0xFF42A5F5),
                        text: 'PIP floating score view',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _FeatureRow(
                        icon: Icons.bolt_rounded,
                        iconColor: AppColors.accentOrange,
                        text: '2-ball live prediction',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _FeatureRow(
                        icon: Icons.update_rounded,
                        iconColor: AppColors.primaryGreen,
                        text: 'All future updates free',
                        isDark: isDark,
                      ),

                      const SizedBox(height: 22),

                      // Price tag
                      Builder(
                        builder: (context) {
                          // Read the lifetime price dynamically from RevenueCat
                          final premiumState = context
                              .read<PremiumBloc>()
                              .state;
                          final lifetimePkg = premiumState.findPackage(
                            '\$rc_lifetime',
                          );
                          final lifetimePrice =
                              lifetimePkg?.storeProduct.priceString ?? '₹49';

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(
                                isDark ? 0.12 : 0.07,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.25),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    lifetimePrice,
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryGreen,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'one-time',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isPurchasing
                              ? null
                              : () async {
                                  // Locate the lifetime package from our state fallback
                                  final premiumState = context.read<PremiumBloc>().state;
                                  final lifetimePkg = premiumState.findPackage('\$rc_lifetime');
                                  
                                  if (lifetimePkg == null) return;
                                  
                                  setState(() => _isPurchasing = true);
                                  
                                  final result = await _rcService.purchasePackage(lifetimePkg);
                                  
                                  if (!mounted) return;
                                  
                                  setState(() => _isPurchasing = false);
                                  
                                  if (result.success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Welcome to Premium! You are now ad-free.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.of(context).pop(); // Close dialog
                                  } else if (result.errorMessage != 'cancelled') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result.errorMessage ?? 'Purchase failed.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.5),
                            elevation: 8,
                            shadowColor: AppColors.primaryGreen.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isPurchasing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Get Lifetime Access',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Dismiss link
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.grey[500]
                              : Colors.grey[500],
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Maybe later',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // end Center
    ); // end BlocListener
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
