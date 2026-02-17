import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/theme/theme_bloc.dart';

import 'package:cricketbuzz/core/services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _dailyEnabled = true;
  bool _matchStart = true;
  bool _wicket = true;
  bool _result = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final service = NotificationService();
    final enabled = await service.isEnabled();
    final prefs = await service.getPreferences();
    if (mounted) {
      setState(() {
        _dailyEnabled = enabled;
        _matchStart = prefs['matchStart'] ?? true;
        _wicket = prefs['wicket'] ?? true;
        _result = prefs['result'] ?? true;
      });
    }
  }

  Future<void> _toggleDaily(bool value) async {
    setState(() => _dailyEnabled = value);
    await NotificationService().setEnabled(value);
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() {
      if (key == 'matchStart') _matchStart = value;
      if (key == 'wicket') _wicket = value;
      if (key == 'result') _result = value;
    });
    await NotificationService().setPreference(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Theme Section ──────────────────
          Text(
            'Appearance',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _ThemeTile(
                        icon: Icons.brightness_auto_rounded,
                        title: 'System Default',
                        isSelected: state.themeMode == ThemeMode.system,
                        onTap: () => context.read<ThemeBloc>().add(
                          SetThemeMode(ThemeMode.system),
                        ),
                      ),
                      _ThemeTile(
                        icon: Icons.light_mode_rounded,
                        title: 'Light Mode',
                        isSelected: state.themeMode == ThemeMode.light,
                        onTap: () => context.read<ThemeBloc>().add(
                          SetThemeMode(ThemeMode.light),
                        ),
                      ),
                      _ThemeTile(
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark Mode',
                        isSelected: state.themeMode == ThemeMode.dark,
                        onTap: () => context.read<ThemeBloc>().add(
                          SetThemeMode(ThemeMode.dark),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          // ─── Notifications ──────────────────
          Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Daily Match Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Get a daily summary of matches',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    value: _dailyEnabled,
                    onChanged: (v) => _toggleDaily(v),
                    activeThumbColor: AppColors.primaryGreen,
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Match Start Alerts',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    value: _matchStart,
                    onChanged: (v) => _updatePreference('matchStart', v),
                    activeThumbColor: AppColors.primaryGreen,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Wicket Alerts',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    value: _wicket,
                    onChanged: (v) => _updatePreference('wicket', v),
                    activeThumbColor: AppColors.primaryGreen,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Result Alerts',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    value: _result,
                    onChanged: (v) => _updatePreference('result', v),
                    activeThumbColor: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // ─── About ──────────────────────────
          Text(
            'About',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sports_cricket_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CricketBuzz',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Version 1.0.0',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your one-stop cricket companion. Follow live scores, detailed scorecards, player stats, and more — all in your preferred language.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryGreen : null),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryGreen,
              size: 22,
            )
          : const Icon(Icons.circle_outlined, size: 22),
      onTap: onTap,
    );
  }
}
