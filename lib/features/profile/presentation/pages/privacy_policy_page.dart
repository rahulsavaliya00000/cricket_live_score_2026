import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';

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
              'Effective Date: October 26, 2023',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('1. Information We Collect', textColor),
            _paragraph(
              'We collect minimal information to provide you with the best cricket experience. This includes:\n\n• Device Information: To optimize app performance.\n• Usage Data: To understand how you interact with our features.\n• Location (Optional): To provide localized match timings.',
              textColor,
            ),
            _sectionTitle('2. How We Use Your Data', textColor),
            _paragraph(
              'Your data is used solely to:\n\n• Deliver real-time scores and updates.\n• Personalize your feed based on favorite teams.\n• Improve app stability and performance.',
              textColor,
            ),
            _sectionTitle('3. Data Security', textColor),
            _paragraph(
              'We implement industry-standard security measures to protect your personal information. Your data is encrypted in transit and at rest.',
              textColor,
            ),
            _sectionTitle('4. Third-Party Services', textColor),
            _paragraph(
              'We may use trusted third-party services (like Google Firebase) for authentication and analytics. These services adhere to strict privacy standards.',
              textColor,
            ),
            _sectionTitle('5. Contact Us', textColor),
            _paragraph(
              'If you have any questions about this Privacy Policy, please contact us at support@cricketbuzz.com.',
              textColor,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2024 CricketBuzz. All rights reserved.',
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
