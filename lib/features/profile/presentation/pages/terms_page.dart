import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
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
              'Terms of Service',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: October 26, 2023',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('1. Acceptance of Terms', textColor),
            _paragraph(
              'By accessing and using CricketBuzz, you accept and agree to be bound by the terms and provision of this agreement.',
              textColor,
            ),
            _sectionTitle('2. User Conduct', textColor),
            _paragraph(
              'You agree to use the app only for lawful purposes. You are prohibited from posting or transmitting any unlawful, threatening, libelous, defamatory, obscene, or profane material.',
              textColor,
            ),
            _sectionTitle('3. Content Ownership', textColor),
            _paragraph(
              'All content found on or through this app is the property of CricketBuzz or used with permission. You may not distribute, modify, transmit, reuse, download, repost, copy, or use said Content, whether in whole or in part, for commercial purposes.',
              textColor,
            ),
            _sectionTitle('4. Termination', textColor),
            _paragraph(
              'We may terminate your access to the app, without cause or notice, which may result in the forfeiture and destruction of all information associated with you.',
              textColor,
            ),
            _sectionTitle('5. Changes to Terms', textColor),
            _paragraph(
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. What constitutes a material change will be determined at our sole discretion.',
              textColor,
            ),
            _sectionTitle('6. Contact Us', textColor),
            _paragraph(
              'If you have any questions about these Terms, please contact us at legal@cricketbuzz.com.',
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
