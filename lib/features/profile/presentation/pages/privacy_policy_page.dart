import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricket_live_score/core/constants/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Privacy Matters',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: Feb 27, 2026',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('1. Information We Collect', textColor),
            _paragraph(
              'Cricket Live Score collects only the minimum information needed to provide a great cricket experience:\n\n'
              '• Account Information: Name and email address when you sign in with Google.\n'
              '• Device Information: Device model and OS version to optimise app performance.\n'
              '• Usage Data: Pages visited and features used, collected anonymously to help us improve the app.\n'
              '• Notification Token: To deliver cricket score alerts you have opted into.',
              textColor,
            ),
            _sectionTitle('2. How We Use Your Data', textColor),
            _paragraph(
              'Your data is used only to:\n\n'
              '• Deliver live cricket scores, match updates, and breaking news.\n'
              '• Save your preferences such as favourite teams and display language.\n'
              '• Send optional push notifications for matches you follow.\n'
              '• Improve app stability, fix bugs, and develop new features.\n\n'
              'We do not sell, rent, or share your personal data with third parties for marketing purposes.',
              textColor,
            ),
            _sectionTitle('3. No Real-Money or Gambling Activities', textColor),
            _paragraph(
              'Cricket Live Score is a free cricket scores and news app. It does not involve any real-money transactions, betting, wagering, or gambling of any kind.\n\n'
              'Any in-app rewards (coins, collectibles) are purely virtual, have no monetary value, cannot be exchanged for real money or prizes, and are provided solely for entertainment within the app.',
              textColor,
            ),
            _sectionTitle('4. Advertising', textColor),
            _paragraph(
              'We display non-personalised advertisements through Google AdMob to keep the app free. These ads do not use sensitive personal data. You can remove all ads by upgrading to Cricket Live Score Premium.',
              textColor,
            ),
            _sectionTitle('5. Data Security', textColor),
            _paragraph(
              'We implement industry-standard security measures including HTTPS encryption in transit and secure cloud storage via Google Firebase. We regularly review our practices to protect your information.',
              textColor,
            ),
            _sectionTitle('6. Third-Party Services', textColor),
            _paragraph(
              'The app uses the following trusted third-party services, each governed by their own privacy policies:\n\n'
              '• Google Firebase — authentication & database\n'
              '• Google AdMob — advertising\n'
              '• RevenueCat — subscription management\n\n'
              'None of these services receive your data for advertising profiling.',
              textColor,
            ),
            _sectionTitle('7. Children\'s Privacy', textColor),
            _paragraph(
              'Cricket Live Score is not directed at children under 13. We do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us and we will delete it promptly.',
              textColor,
            ),
            _sectionTitle('8. Your Rights', textColor),
            _paragraph(
              'You may request access to, correction of, or deletion of your personal data at any time by contacting us. You can also delete your account directly from the Profile page.',
              textColor,
            ),
            _sectionTitle('9. Contact Us', textColor),
            _paragraph(
              'If you have questions about this Privacy Policy, please contact us at:\n\nqdevix@gmail.com',
              textColor,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 Cricket Live Score. All rights reserved.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _paragraph(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        height: 1.6,
        color: color.withValues(alpha: 0.8),
      ),
    );
  }
}
