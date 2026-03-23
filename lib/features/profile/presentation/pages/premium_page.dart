import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/features/profile/presentation/bloc/premium_bloc.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<PremiumBloc, PremiumState>(
      listenWhen: (previous, current) =>
          current.error != null && previous.error != current.error,
      listener: (context, state) {
        if (state.error != null && state.error != 'cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF323232),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!state.isPremium)
                TextButton(
                  onPressed: () =>
                      context.read<PremiumBloc>().add(RestoreLifetime()),
                  child: Text(
                    'Restore',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              // Background Gradient
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF030508),
                            const Color(0xFF0D1117),
                            const Color(0xFF030508),
                          ]
                        : [
                            const Color(0xFFF0F4F2),
                            Colors.white,
                            const Color(0xFFE8F1ED),
                          ],
                  ),
                ),
              ),
              // Background Decorative Circles
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen.withOpacity(
                      isDark ? 0.05 : 0.1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentOrange.withOpacity(
                      isDark ? 0.02 : 0.04,
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          // Header Area
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _PulsingPremiumIcon(),
                                const SizedBox(height: 16),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    state.isPremium
                                        ? 'Legendary Member'
                                        : 'Premium Experience',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey[800],
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  state.isPremium
                                      ? 'Welcome back! You have full access to all features.'
                                      : 'Choose the best plan for your match insights',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),

                          if (state.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(),
                            )
                          else ...[
                            const SizedBox(height: 10),

                            // Extract dynamic prices from RevenueCat packages
                            Builder(
                              builder: (context) {
                                final weeklyPkg = state.findPackage(
                                  '\$rc_weekly',
                                );
                                final monthlyPkg = state.findPackage(
                                  '\$rc_monthly',
                                );
                                final lifetimePkg = state.findPackage(
                                  '\$rc_lifetime',
                                );

                                final weeklyPrice =
                                    weeklyPkg?.storeProduct.priceString ?? '—';
                                final monthlyPrice =
                                    monthlyPkg?.storeProduct.priceString ?? '—';
                                final lifetimePrice =
                                    lifetimePkg?.storeProduct.priceString ??
                                    '—';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 14),

                                    // Tiers - Reordered to Descending (49, 29, 11)
                                    _TierCard(
                                      title: 'Lifetime Legend',
                                      price: lifetimePrice,
                                      period: ' One-time',
                                      description: 'Ultimate fan experience',
                                      gradient: const [
                                        Color(0xFF00C853),
                                        Color(0xFF00796B),
                                      ],
                                      isPopular: true,
                                      isPurchased: state.isPremium,
                                      staggerIndex: 0,
                                      features: const [
                                        'Lifetime Ad-free',
                                        'PIP (Picture in Picture) View',
                                        'Future Updates Free',
                                        '2 Ball Advanced (Live)',
                                      ],
                                      onPressed: () {
                                        if (lifetimePkg != null &&
                                            !state.isPremium) {
                                          context.read<PremiumBloc>().add(
                                            PurchasePackage('\$rc_lifetime'),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _TierCard(
                                      title: 'Monthly Pro',
                                      price: monthlyPrice,
                                      period: '/ month',
                                      description: 'Most versatile choice',
                                      gradient: const [
                                        Color(0xFF42A5F5),
                                        Color(0xFF1976D2),
                                      ],
                                      features: const [
                                        'Everything in Starter',
                                        'Advanced Player Stats',
                                        'Faster Notifications',
                                        '1 Ball Future (Live)',
                                      ],
                                      isPopular: false,
                                      isPurchased: false,
                                      staggerIndex: 1,
                                      onPressed: () {
                                        if (monthlyPkg != null &&
                                            !state.isPremium) {
                                          context.read<PremiumBloc>().add(
                                            PurchasePackage('\$rc_monthly'),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _TierCard(
                                      title: 'Weekly Starter',
                                      price: weeklyPrice,
                                      period: '/ week',
                                      description: 'Perfect for quick updates',
                                      gradient: const [
                                        Color(0xFF66BB6A),
                                        Color(0xFF43A047),
                                      ],
                                      features: const [
                                        'Ad-free Experience',
                                        'Live Score Tracking',
                                        'Basic Match Insights',
                                      ],
                                      isPopular: false,
                                      isPurchased: false,
                                      staggerIndex: 2,
                                      onPressed: () {
                                        if (weeklyPkg != null &&
                                            !state.isPremium) {
                                          context.read<PremiumBloc>().add(
                                            PurchasePackage('\$rc_weekly'),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: 40),

                          // Trust Badges or Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Secure Subscription via Google Play',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Subscriptions can be cancelled at any time.\nTerms and Conditions apply.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Pulsing Premium Icon ───
class _PulsingPremiumIcon extends StatefulWidget {
  @override
  State<_PulsingPremiumIcon> createState() => _PulsingPremiumIconState();
}

class _PulsingPremiumIconState extends State<_PulsingPremiumIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00796B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withOpacity(_glowAnim.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

// ─── Shimmer Overlay Painter (cascading shine) ───
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;

  _ShimmerPainter({
    required this.progress,
    required this.color,
    this.radius = 18,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerWidth = size.width * 0.5;
    final dx = -shimmerWidth + (size.width + shimmerWidth * 2) * progress;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.08),
          color.withOpacity(0.25),
          color.withOpacity(0.08),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(dx, 0, shimmerWidth, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Animated Gradient Border Painter ───
class _GlowBorderPainter extends CustomPainter {
  final double progress;
  final List<Color> gradient;
  final double radius;
  final double strokeWidth;

  _GlowBorderPainter({
    required this.progress,
    required this.gradient,
    this.radius = 18,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Rotating sweep gradient for the border
    final angle = progress * 2 * math.pi;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle,
        endAngle: angle + 2 * math.pi,
        colors: [
          gradient[0].withOpacity(0.0),
          gradient[0].withOpacity(0.6),
          gradient[1].withOpacity(0.9),
          gradient[0].withOpacity(0.6),
          gradient[0].withOpacity(0.0),
        ],
        stops: const [0.0, 0.15, 0.35, 0.55, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);

    // Add a subtle glow behind the bright part
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader = SweepGradient(
        colors: [
          gradient[0].withOpacity(0.0),
          gradient[0].withOpacity(0.2),
          gradient[1].withOpacity(0.35),
          gradient[0].withOpacity(0.2),
          gradient[0].withOpacity(0.0),
        ],
        stops: const [0.0, 0.15, 0.35, 0.55, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(_GlowBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Mini Plan Card with Staggered Shimmer + Animated Border + Scale ───
class _MiniPlanCard extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final List<Color> gradient;
  final IconData icon;
  final bool isPopular;
  final bool isPurchased;
  final int staggerIndex;
  final VoidCallback onTap;

  const _MiniPlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.gradient,
    required this.icon,
    required this.isPopular,
    required this.isPurchased,
    required this.staggerIndex,
    required this.onTap,
  });

  @override
  State<_MiniPlanCard> createState() => _MiniPlanCardState();
}

class _MiniPlanCardState extends State<_MiniPlanCard>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _borderController;
  double _scale = 1.0;

  // Total cycle = 3 cards × 1500ms each + gap = ~6000ms
  static const _totalCycleDuration = 6000;
  static const _cardShimmerDuration = 1500; // ms per card

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalCycleDuration),
    )..repeat();

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  /// Returns 0..1 shimmer progress for THIS card, or -1 if not active
  double _getCardShimmerProgress(double globalProgress) {
    final cardStartFraction =
        (widget.staggerIndex * _cardShimmerDuration) / _totalCycleDuration;
    final cardEndFraction =
        cardStartFraction + (_cardShimmerDuration / _totalCycleDuration);

    if (globalProgress < cardStartFraction ||
        globalProgress > cardEndFraction) {
      return -1; // not active
    }
    return (globalProgress - cardStartFraction) /
        (cardEndFraction - cardStartFraction);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            // Base card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.gradient[0].withOpacity(isDark ? 0.25 : 0.15),
                    widget.gradient[1].withOpacity(isDark ? 0.10 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.gradient[0].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: widget.gradient[0],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.price,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: widget.gradient[0],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.period,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  // Fixed-height slot — always reserves space so all 3 cards
                  // stay the same height regardless of badge visibility
                  SizedBox(
                    height: 20,
                    child: widget.isPurchased
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF00C853),
                            size: 16,
                          )
                        : widget.isPopular
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.gradient,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'BEST',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // Animated gradient border
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _borderController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _GlowBorderPainter(
                        progress: _borderController.value,
                        gradient: widget.gradient,
                        radius: 18,
                        strokeWidth: 1.5,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Staggered shimmer sweep
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) {
                      final progress = _getCardShimmerProgress(
                        _shimmerController.value,
                      );
                      if (progress < 0) return const SizedBox.shrink();
                      return CustomPaint(
                        painter: _ShimmerPainter(
                          progress: progress,
                          color: widget.gradient[0],
                          radius: 18,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final List<Color> gradient;
  final bool isPopular;
  final bool isPurchased;
  final int staggerIndex;
  final VoidCallback onPressed;

  const _TierCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.gradient,
    required this.isPopular,
    required this.isPurchased,
    required this.staggerIndex,
    required this.onPressed,
  });

  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _borderController;

  static const _totalCycleDuration = 7500;
  static const _cardShimmerDuration = 2000;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalCycleDuration),
    )..repeat();

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  double _getCardShimmerProgress(double globalProgress) {
    final cardStartFraction =
        (widget.staggerIndex * _cardShimmerDuration) / _totalCycleDuration;
    final cardEndFraction =
        cardStartFraction + (_cardShimmerDuration / _totalCycleDuration);

    if (globalProgress < cardStartFraction ||
        globalProgress > cardEndFraction) {
      return -1;
    }
    return (globalProgress - cardStartFraction) /
        (cardEndFraction - cardStartFraction);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isPurchased
                ? (isDark ? const Color(0xFF004D40) : const Color(0xFFE8F5E9))
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Card Header with Gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.gradient[0].withOpacity(0.15),
                      widget.gradient[1].withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.description,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.isPurchased)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00C853),
                        size: 28,
                      )
                    else if (widget.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE0E0E0), Color(0xFFB0B0B0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          'BEST VALUE',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.price,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 6),
                            child: Text(
                              widget.period,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFFA0AEC0)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...widget.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: widget.gradient[0].withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: widget.gradient[0],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.black87.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onPressed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isPurchased
                              ? Colors.grey[800]
                              : (widget.isPopular
                                    ? const Color(0xFF00A86B)
                                    : (isDark
                                          ? const Color(0xFF1E2636)
                                          : Colors.black87)),
                          foregroundColor: Colors.white,
                          elevation: widget.isPopular && !widget.isPurchased
                              ? 12
                              : 0,
                          shadowColor: widget.isPopular
                              ? const Color(0xFF00A86B).withOpacity(0.4)
                              : Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          widget.isPurchased ? 'Purchased' : 'Get Started',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
        // Animated gradient border
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _borderController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GlowBorderPainter(
                    progress: _borderController.value,
                    gradient: widget.gradient,
                    radius: 24,
                    strokeWidth: 2.0,
                  ),
                );
              },
            ),
          ),
        ),
        // Staggered shimmer sweep
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  final progress = _getCardShimmerProgress(
                    _shimmerController.value,
                  );
                  if (progress < 0) return const SizedBox.shrink();
                  return CustomPaint(
                    painter: _ShimmerPainter(
                      progress: progress,
                      color: widget.gradient[0],
                      radius: 24,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
