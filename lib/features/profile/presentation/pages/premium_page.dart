import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Go Premium',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Image/Icon
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 80,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unlock Premium Features',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a plan that fits your cricket passion',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Tiers
            _TierCard(
              title: 'Monthly Pass',
              price: '\$2.99',
              period: '/ month',
              features: const [
                'Ad-free Experience',
                'Live Ball-by-Ball Alerts',
                'Advanced Player Stats',
                'Dark Mode Themes',
              ],
              isPopular: false,
            ),
            const SizedBox(height: 16),
            _TierCard(
              title: 'Yearly Pro',
              price: '\$19.99',
              period: '/ year',
              features: const [
                'Everything in Monthly Pass',
                'Priority Support',
                'Offline Match Viewing',
                'Exclusive Series Content',
              ],
              isPopular: true,
            ),
            const SizedBox(height: 16),
            _TierCard(
              title: 'Lifetime Legend',
              price: '\$49.99',
              period: ' (One-time)',
              features: const [
                'All Pro Features Forever',
                'Legendary Badge on Profile',
                'Future Premium Add-ons',
              ],
              isPopular: false,
            ),

            const SizedBox(height: 32),
            Text(
              'Subscriptions auto-renew and can be cancelled anytime.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;

  const _TierCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular
              ? AppColors.accentGold
              : (isDark ? Colors.white12 : Colors.black12),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: AppColors.accentGold.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isPopular ? AppColors.accentGold : null,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'POPULAR',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  period,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f, style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment gateway integration coming soon!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? AppColors.accentGold
                    : AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Subscribe Now',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
