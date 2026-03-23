import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:cricketbuzz/features/wallet/data/models/transaction_model.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';
import 'package:cricketbuzz/core/services/notification_service.dart';
import 'package:cricketbuzz/core/services/analytics_service.dart';

// ── Data ────────────────────────────────────────────────────────
class SpinItem {
  final String label; // legend chip text
  final String emoji; // sticker badge fallback
  final String imagePath; // asset PNG – overrides emoji when set
  final String seasonName; // shown in win dialog
  final int amount; // 0 = Try Again
  final RewardType type;
  final Color color;
  final double probability;
  final Color textColor;

  const SpinItem({
    required this.label,
    required this.emoji,
    this.imagePath = '',
    this.seasonName = '',
    required this.amount,
    required this.type,
    required this.color,
    required this.probability,
    required this.textColor,
  });
}

// ── Page ────────────────────────────────────────────────────────
class SpinWheelPage extends StatefulWidget {
  const SpinWheelPage({super.key});
  @override
  State<SpinWheelPage> createState() => _SpinWheelPageState();
}

class _SpinWheelPageState extends State<SpinWheelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  late AudioPlayer _audioPlayer;

  static const List<SpinItem> _standardItems = [
    SpinItem(
      label: '3 IR',
      emoji: '⭐',
      seasonName: 'IR Coins',
      amount: 3,
      type: RewardType.coins,
      color: Color(0xFFFFB300),
      probability: 0.05,
      textColor: Colors.black87,
    ),
    SpinItem(
      label: '1 IR',
      emoji: '💰',
      seasonName: 'IR Coins',
      amount: 1,
      type: RewardType.coins,
      color: Color(0xFF00ACC1),
      probability: 0.15,
      textColor: Colors.white,
    ),
    SpinItem(
      label: '2 Balls',
      emoji: '⚾',
      imagePath: 'assets/images/red_cricket_ball_sticker.png',
      seasonName: 'Season Ball',
      amount: 2,
      type: RewardType.balls,
      color: Color(0xFFFF6D00),
      probability: 0.20,
      textColor: Colors.white,
    ),
    SpinItem(
      label: '1 Bat',
      emoji: '�',
      imagePath: 'assets/images/cricket_bat_sticker.png',
      seasonName: 'Cricket Bat',
      amount: 1,
      type: RewardType.bats,
      color: Color(0xFF6A1B9A),
      probability: 0.15,
      textColor: Colors.white,
    ),
    SpinItem(
      label: '1 Ball',
      emoji: '⚾',
      imagePath: 'assets/images/red_cricket_ball_sticker.png',
      seasonName: 'Season Ball',
      amount: 1,
      type: RewardType.balls,
      color: Color(0xFFD81B60),
      probability: 0.25,
      textColor: Colors.white,
    ),
    SpinItem(
      label: 'Try Again',
      emoji: '😔',
      seasonName: '',
      amount: 0,
      type: RewardType.coins,
      color: Color(0xFFC62828),
      probability: 0.20,
      textColor: Colors.white,
    ),
  ];

  static const List<SpinItem> _ultraRareItems = [
    SpinItem(
      label: '3 IR',
      emoji: '⭐',
      seasonName: 'IR Coins',
      amount: 3,
      type: RewardType.coins,
      color: Color(0xFFFFB300),
      probability: 0.001,
      textColor: Colors.black87,
    ),
    SpinItem(
      label: '1 IR',
      emoji: '💰',
      seasonName: 'IR Coins',
      amount: 1,
      type: RewardType.coins,
      color: Color(0xFF00ACC1),
      probability: 0.002,
      textColor: Colors.white,
    ),
    SpinItem(
      label: '2 Balls',
      emoji: '⚾',
      imagePath: 'assets/images/red_cricket_ball_sticker.png',
      seasonName: 'Season Ball',
      amount: 2,
      type: RewardType.balls,
      color: Color(0xFFFF6D00),
      probability: 0.25,
      textColor: Colors.white,
    ),
    SpinItem(
      label: '1 Bat',
      emoji: '�',
      imagePath: 'assets/images/cricket_bat_sticker.png',
      seasonName: 'Cricket Bat',
      amount: 1,
      type: RewardType.bats,
      color: Color(0xFF6A1B9A),
      probability: 0.25,
      textColor: Colors.white,
    ),
    SpinItem(
      label: '1 Ball',
      emoji: '⚾',
      imagePath: 'assets/images/red_cricket_ball_sticker.png',
      seasonName: 'Season Ball',
      amount: 1,
      type: RewardType.balls,
      color: Color(0xFFD81B60),
      probability: 0.25,
      textColor: Colors.white,
    ),
    SpinItem(
      label: 'Try Again',
      emoji: '😔',
      seasonName: '',
      amount: 0,
      type: RewardType.coins,
      color: Color(0xFFC62828),
      probability: 0.247,
      textColor: Colors.white,
    ),
  ];

  List<SpinItem> _getCurrentItems() {
    final balance = context.read<WalletCubit>().state.irCoins;
    return balance > 230 ? _ultraRareItems : _standardItems;
  }

  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.decelerate);
    _audioPlayer = AudioPlayer();

    // Check if coming from tour for celebratory message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GoRouterState.of(context);
      if (state.uri.queryParameters['fromTour'] == 'true') {
        _showTourCelebration();
      }
    });
  }

  void _showTourCelebration() {
    _confettiController.play();
    _playResultSound(true);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.primaryGreen, size: 48),
            const SizedBox(height: 12),
            Text(
              'Welcome, Lucky Player! 🎲',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'You\'ve arrived just in time! Every day you get one FREE lucky spin. Spin the wheel now to start your journey with a win!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Let\'s Spin! 🎯',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardedAdAndSpin() {
    bool userEarnedReward = false;
    AdHelper.showRewardedAd(
      onEarnedReward: (rewardItem) {
        userEarnedReward = true;
      },
      onAdDismissed: () {
        if (userEarnedReward) {
          _spin(isFree: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSpinSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/spin.wav'));
    } catch (_) {}
  }

  Future<void> _playResultSound(bool win) async {
    try {
      await _audioPlayer.play(
        AssetSource(win ? 'audio/cheer.wav' : 'audio/wicket.wav'),
      );
    } catch (_) {}
  }

  void _attemptSpin() {
    if (_controller.isAnimating) return;
    final walletState = context.read<WalletCubit>().state;

    if (walletState.canSpinFree) {
      _spin(isFree: true);
    } else {
      _showAdPrompt();
    }
  }

  void _showAdPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Extra Spin? 🎰'),
        content: const Text(
          'You have already used your free spin for today. Watch a quick video to spin again!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showRewardedAdAndSpin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Watch Ad & Spin',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _spin({required bool isFree}) {
    if (_controller.isAnimating) return;
    context.read<WalletCubit>().setSpinning(true);
    _playSpinSound();

    // Pick result based on probability
    final items = _getCurrentItems();
    double rand = math.Random().nextDouble();
    double cumulative = 0.0;
    SpinItem selected = items.last;
    for (var item in items) {
      cumulative += item.probability;
      if (rand <= cumulative) {
        selected = item;
        break;
      }
    }

    // Calculate target angle based on current position to ensure perfect alignment
    final index = items.indexOf(selected);
    const degreesPerSegment = 360.0 / 6;

    // We want the specific segment to land at top (0/360 degrees)
    // The target relative offset from 0 is (360 - index * degreesPerSegment)
    final targetOffsetRadians =
        (360 - (index * degreesPerSegment)) * (math.pi / 180);

    // Current wheel position normalized to 0-2pi
    final currentNormalized = _currentAngle % (2 * math.pi);

    // Calculate how much to rotate to reach target 0, then add the specific segment offset
    // Plus 5 full spins (10*pi) for visual effect
    final rotationDelta =
        (2 * math.pi - currentNormalized) +
        targetOffsetRadians +
        (10 * math.pi);

    _animation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + rotationDelta,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));

    _controller.reset();
    _controller.forward().then((_) {
      _currentAngle = _animation.value;
      context.read<WalletCubit>().setSpinning(false);
      _showResult(selected, isFree);
    });
  }

  void _showResult(SpinItem item, bool isFree) {
    // Immediately dismiss the sticky spin notification once a free spin is used
    if (isFree) {
      NotificationService().cancelSpinNotification();
    }

    final isWin = item.amount > 0;
    if (isWin) {
      _confettiController.play();
      context.read<WalletCubit>().creditSpinReward(
        amount: item.amount.toDouble(),
        type: item.type,
        isFree: isFree,
      );
      // Log reward earned to Analytics
      unawaited(
        AnalyticsService.instance.logSpinWheelResult(
          rewardType: item.type.name, // 'coins', 'balls', 'bats'
          amount: item.amount,
        ),
      );
      _playResultSound(true);
    } else {
      // Still need to mark free spin as used even if lost
      if (isFree) {
        context.read<WalletCubit>().claimFreeSpin();
      }
      _playResultSound(false);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWin ? '🎉 You Won!' : 'Better Luck Next Time!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isWin ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              // Reward badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withOpacity(0.15),
                  border: Border.all(color: item.color, width: 3),
                ),
                child: ClipOval(
                  child: item.imagePath.isNotEmpty
                      ? Image.asset(
                          item.imagePath,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (isWin) ...[
                Text(
                  'You won ${item.amount} ${item.seasonName.isNotEmpty ? item.seasonName : item.label}${item.amount > 1 && !item.seasonName.contains('Bat') && !item.seasonName.contains('IR') ? 's' : ''}!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: item.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isWin ? 'Collect Reward' : 'Try Again',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        title: Text(
          'Spin & Win',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Grass gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
                radius: 1.2,
              ),
            ),
          ),

          Positioned.fill(child: CustomPaint(painter: FieldLinesPainter())),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.white,
              Colors.yellow,
              Colors.orange,
              Colors.blue,
            ],
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Spin to Win!',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Your luck could change today 🏆',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 32),

                BlocBuilder<WalletCubit, WalletState>(
                  builder: (context, state) {
                    final items = state.irCoins > 230
                        ? _ultraRareItems
                        : _standardItems;
                    final isFree = state.canSpinFree;

                    return Column(
                      children: [
                        // ── Spin Wheel ──────────────────────────────────
                        _buildWheel(items),
                        const SizedBox(height: 28),
                        // Rewards legend
                        _buildLegend(items),
                        const SizedBox(height: 28),
                        // SPIN button
                        GestureDetector(
                          onTap: state.isSpinning ? null : _attemptSpin,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: state.isSpinning
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF757575),
                                        Color(0xFF616161),
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFE53935),
                                        Color(0xFFB71C1C),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: state.isSpinning
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE53935,
                                        ).withOpacity(0.5),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Text(
                              state.isSpinning
                                  ? '🌀  SPINNING...'
                                  : (isFree ? '🎯  FREE SPIN' : '🎬  SPIN'),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Wheel Widget ──────────────────────────────────────────────
  Widget _buildWheel(List<SpinItem> items) {
    const wheelSize = 300.0;
    const double radius = wheelSize / 2;
    final int n = items.length;
    final double anglePerSegment = 2 * math.pi / n;

    return SizedBox(
      width: wheelSize + 20,
      height: wheelSize + 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: wheelSize + 16,
            height: wheelSize + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Colored segments + segment icon labels (rotate together)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Transform.rotate(
                angle: _animation.value,
                child: SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Segments
                      CustomPaint(
                        size: const Size(wheelSize, wheelSize),
                        painter: WheelPainter(items: items),
                      ),

                      // Sticker badges — positioned at 60% radius via trig
                      for (int i = 0; i < n; i++)
                        Builder(
                          builder: (_) {
                            final item = items[i];
                            // mid-angle of this segment (pointing UP = -π/2 at index 0)
                            final angle = i * anglePerSegment - math.pi / 2;
                            const dist = radius * 0.60; // 60% from center
                            final dx = radius + dist * math.cos(angle);
                            final dy = radius + dist * math.sin(angle);
                            return Positioned(
                              left: dx - 28,
                              top: dy - 28,
                              // Counter-rotate the badge so it remains upright
                              child: Transform.rotate(
                                angle: -_animation.value,
                                child: _StickerBadge(item: item),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Top pointer
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(36, 44),
              painter: PointerPainter(),
            ),
          ),

          // Center SPIN hub (tappable)
          GestureDetector(
            onTap: _attemptSpin,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10),
                ],
              ),
              child: Center(
                child: Text(
                  'SPIN',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rewards Legend ────────────────────────────────────────────
  Widget _buildLegend(List<SpinItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: items.where((i) => i.amount > 0).map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.color.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.imagePath.isNotEmpty)
                  ClipOval(
                    child: Image.asset(
                      item.imagePath,
                      width: 14,
                      height: 14,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Text(item.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Sticker Badge Widget ─────────────────────────────────────────
class _StickerBadge extends StatelessWidget {
  final SpinItem item;
  const _StickerBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: item.imagePath.isNotEmpty
                ? Image.asset(
                    item.imagePath,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
          ),
        ),
        if (item.label.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Wheel Segment Painter (colors + borders only) ────────────────
class WheelPainter extends CustomPainter {
  final List<SpinItem> items;
  const WheelPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final anglePerItem = 2 * math.pi / items.length;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // Offset by half a segment so that the center of item 0 is exactly at top
      final startAngle = i * anglePerItem - math.pi / 2 - anglePerItem / 2;

      // Fill
      canvas.drawArc(
        rect,
        startAngle,
        anglePerItem,
        true,
        Paint()..color = item.color,
      );

      // Divider line
      canvas.drawArc(
        rect,
        startAngle,
        anglePerItem,
        true,
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Inner ring
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant WheelPainter old) => false;
}

// ── Pointer ──────────────────────────────────────────────────────
class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black, 4, false);

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Field Lines ──────────────────────────────────────────────────
class FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(Offset(cx, cy), size.width * 0.8, paint);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.45, paint);

    // Pitch rectangle
    final pitchPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 120),
        const Radius.circular(4),
      ),
      pitchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
