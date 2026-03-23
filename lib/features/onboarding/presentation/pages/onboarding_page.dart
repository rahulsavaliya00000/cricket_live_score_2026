import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricketbuzz/core/constants/app_constants.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';
import 'package:cricketbuzz/core/widgets/native_ad_widget.dart';
import 'package:cricketbuzz/core/services/analytics_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAdWaiting = false;
  int _adWaitSeconds = 0;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  // One stable NativeAdWidget per page — created once, never rebuilt.
  // GlobalKey keeps them alive even when the page is off-screen.
  late final List<Widget> _nativeAds;

  // Tracks which pages have their banner ad loaded.
  late final List<bool> _bannerAdLoaded;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      title: 'Welcome to CricketBuzz',
      description:
          'Your one-stop destination for live scores, ball-by-ball updates, and in-depth cricket coverage.',
      imagePath: 'assets/images/tour_welcome.png',
      icon: Icons.sports_cricket_rounded,
      accentColor: const Color(0xFF2E7D32),
      chipLabel: 'CRICKET',
    ),
    OnboardingItem(
      title: 'Live Matches & Stats',
      description:
          'Track every ball with real-time scorecards, detailed player statistics, and match insights.',
      imagePath: 'assets/images/tour_match.png',
      icon: Icons.leaderboard_rounded,
      accentColor: const Color(0xFF1565C0),
      chipLabel: 'LIVE',
    ),
    OnboardingItem(
      title: 'Spin, Play & Win',
      description:
          'Earn IR Coins by spinning the wheel, climb global leaderboards, and unlock exclusive cricket rewards!',
      imagePath: 'assets/images/tour_rewards.png',
      icon: Icons.emoji_events_rounded,
      accentColor: const Color(0xFFE65100),
      chipLabel: 'REWARDS',
    ),
  ];

  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();

    // Track banner load state per page (false = still loading)
    _bannerAdLoaded = List.filled(_pages.length, false);

    // Pre-build one ad widget per page with a stable key so they load
    // immediately and are never discarded when the user swipes pages.
    _nativeAds = List.generate(
      _pages.length,
      (i) => NativeAdWidget(
        key: GlobalKey(),
        style: NativeAdStyle.small,
        onAdLoaded: () {
          if (mounted) setState(() => _bannerAdLoaded[i] = true);
        },
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage == _pages.length - 1) {
      // Last page → wait for banner + interstitial, then finish
      _onFinishWithAdCheck();
    } else {
      // Pages 0 and 1 → wait for banner + interstitial before advancing
      _onNextWithAdCheck();
    }
  }

  /// Waits until both the current page's banner AND the interstitial are loaded
  /// (max 8 s each), then advances to the next page.
  Future<void> _onNextWithAdCheck() async {
    if (_isAdWaiting) return;

    if (_bannerAdLoaded[_currentPage] && AdHelper.isInterstitialAdReady) {
      _goToNextPage();
      return;
    }

    const maxWait = 8;
    setState(() {
      _isAdWaiting = true;
      _adWaitSeconds = maxWait;
    });

    for (int i = maxWait; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (_bannerAdLoaded[_currentPage] && AdHelper.isInterstitialAdReady) {
        break;
      }
      setState(() => _adWaitSeconds = i - 1);
    }

    if (!mounted) return;
    setState(() {
      _isAdWaiting = false;
      _adWaitSeconds = 0;
    });
    _goToNextPage();
  }

  /// On the last page: waits for the last page's banner ad to load (max 8 s),
  /// then shows the interstitial and navigates home.
  Future<void> _onFinishWithAdCheck() async {
    if (_isAdWaiting) return;

    if (_bannerAdLoaded[_currentPage]) {
      _finishOnboarding();
      return;
    }

    const maxWait = 8;
    setState(() {
      _isAdWaiting = true;
      _adWaitSeconds = maxWait;
    });

    for (int i = maxWait; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (_bannerAdLoaded[_currentPage]) break;
      setState(() => _adWaitSeconds = i - 1);
    }

    if (!mounted) return;
    setState(() {
      _isAdWaiting = false;
      _adWaitSeconds = 0;
    });
    _finishOnboarding();
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
    unawaited(AnalyticsService.instance.logOnboardingComplete());

    if (mounted) {
      AdHelper.showInterstitialAdImmediately(() {
        if (mounted) {
          context.go('/home');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A0E14), const Color(0xFF151C25)]
                : [const Color(0xFFF5F9F7), Colors.white],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // Top bar: Skip
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page counter
                      Text(
                        '${_currentPage + 1} / ${_pages.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingSlide(
                        item: _pages[index],
                        isDark: isDark,
                        screenSize: size,
                        nativeAd: _nativeAds[index],
                      );
                    },
                  ),
                ),

                // Bottom section: Indicators + Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                  child: Column(
                    children: [
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: 6,
                            width: _currentPage == index ? 28 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _pages[_currentPage].accentColor
                                  : (isDark
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton(
                            onPressed: _isAdWaiting ? null : _onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pages[_currentPage].accentColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: _pages[_currentPage].accentColor
                                  .withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isAdWaiting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                      if (_adWaitSeconds > 0) ...[
                                        const SizedBox(width: 10),
                                        Text(
                                          '$_adWaitSeconds s',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _currentPage == _pages.length - 1
                                            ? 'Get Started'
                                            : 'Continue',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _currentPage == _pages.length - 1
                                            ? Icons.check_rounded
                                            : Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Single Onboarding Slide ───
class _OnboardingSlide extends StatelessWidget {
  final OnboardingItem item;
  final bool isDark;
  final Size screenSize;
  final Widget nativeAd;

  const _OnboardingSlide({
    required this.item,
    required this.isDark,
    required this.screenSize,
    required this.nativeAd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image area with decorative backdrop
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background glow circle
                Container(
                  width: screenSize.width * 0.65,
                  height: screenSize.width * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        item.accentColor.withOpacity(isDark ? 0.12 : 0.08),
                        item.accentColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                // Secondary smaller ring
                Container(
                  width: screenSize.width * 0.52,
                  height: screenSize.width * 0.52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.accentColor.withOpacity(isDark ? 0.08 : 0.06),
                      width: 1.5,
                    ),
                  ),
                ),
                // The actual image
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(item.imagePath, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Text content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // Small icon chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.accentColor.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16, color: item.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      item.chipLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: item.accentColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: screenSize.width * 0.058,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                item.description,
                style: GoogleFonts.poppins(
                  fontSize: screenSize.width * 0.033,
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Native Ad — pre-loaded, stable instance (no shimmer flash on swipe)
        nativeAd,

        const SizedBox(height: 4),
      ],
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color accentColor;
  final String chipLabel;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.accentColor,
    required this.chipLabel,
  });
}
