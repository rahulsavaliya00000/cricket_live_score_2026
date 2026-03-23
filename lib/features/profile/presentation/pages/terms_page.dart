import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricket_live_score/core/constants/app_colors.dart';

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
              'Last Updated: Feb 27, 2026',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('1. Acceptance of Terms', textColor),
            _paragraph(
              'By downloading, installing, or using Cricket Live Score ("the App"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App.',
              textColor,
            ),
            _sectionTitle('2. Nature of the App', textColor),
            _paragraph(
              'Cricket Live Score is a cricket scores, news, and entertainment application. The App provides:\n\n'
              '• Live and upcoming cricket match scores\n'
              '• Player and series statistics\n'
              '• Cricket news and updates\n'
              '• In-app entertainment features such as a virtual spin wheel\n\n'
              'The App does not offer gambling, betting, wagering, or any real-money gaming of any kind. All in-app features are purely for entertainment.',
              textColor,
            ),
            _sectionTitle('3. Virtual Rewards', textColor),
            _paragraph(
              'Cricket Live Score may award virtual items such as coins, balls, or collectibles as part of its entertainment features. These virtual items:\n\n'
              '• Have no monetary value\n'
              '• Cannot be exchanged for real money, goods, or services\n'
              '• Are not transferable outside the App\n'
              '• May be modified or removed at any time without notice\n\n'
              'Using entertainment features within the App does not constitute gambling under any applicable law.',
              textColor,
            ),
            _sectionTitle('4. User Accounts', textColor),
            _paragraph(
              'You may sign in using your Google account. You are responsible for maintaining the confidentiality of your account and for all activities that occur under it. You agree to notify us immediately of any unauthorised use.',
              textColor,
            ),
            _sectionTitle('5. Acceptable Use', textColor),
            _paragraph(
              'You agree to use the App only for lawful, personal, non-commercial purposes. You must not:\n\n'
              '• Attempt to reverse-engineer, decompile, or extract the source code of the App\n'
              '• Attempt to disrupt, overload, or compromise the App\'s servers\n'
              '• Impersonate any person or entity',
              textColor,
            ),
            _sectionTitle('6. Subscriptions & Payments', textColor),
            _paragraph(
              'Cricket Live Score offers an optional Premium subscription that removes advertisements and unlocks additional features. Subscriptions are managed through the Google Play Store and are subject to Google\'s billing terms. We do not process or store payment card information.',
              textColor,
            ),
            _sectionTitle('7. Content Ownership', textColor),
            _paragraph(
              'All content within the App, including text, graphics, logos, and software, is the property of Cricket Live Score or its licensors and is protected by applicable intellectual property laws. You may not reproduce or redistribute any content without written permission.',
              textColor,
            ),
            _sectionTitle('8. Disclaimers', textColor),
            _paragraph(
              'The App is provided "as is" without warranties of any kind. We do not guarantee that scores or data are error-free or uninterrupted. We are not responsible for any decisions made based on information provided by the App.',
              textColor,
            ),
            _sectionTitle('9. Changes to Terms', textColor),
            _paragraph(
              'We may update these Terms at any time. Continued use of the App after changes are posted constitutes your acceptance of the revised Terms. We will notify users of material changes via an in-app notice.',
              textColor,
            ),
            _sectionTitle('10. Contact Us', textColor),
            _paragraph(
              'If you have any questions about these Terms, please contact us at:\n\nqdevix@gmail.com',
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
