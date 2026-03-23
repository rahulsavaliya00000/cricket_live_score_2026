import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:cricketbuzz/features/wallet/data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  void initState() {
    super.initState();
  }

  void _showRewardedAd() {
    bool userEarnedReward = false;
    AdHelper.showRewardedAd(
      onEarnedReward: (rewardItem) {
        userEarnedReward = true;
      },
      onAdDismissed: () async {
        if (userEarnedReward) {
          final success = await context.read<WalletCubit>().watchAdReward();
          if (success) {
            final newState = context.read<WalletCubit>().state;
            if (newState.transactions.isNotEmpty && context.mounted) {
              final lastTx = newState.transactions.first;
              _showRewardDialog(lastTx.amount);
            }
          }
        }
      },
    );
  }

  void _showRewardDialog(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reward Earned! 🎉'),
        content: Text(
          'You earned 💰 ${amount.toStringAsFixed(2)} IR Coins for watching the ad!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Wallet',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 3-Currency Balance Cards ─────────────────────────
                _buildBalanceCards(state, isDark),

                const SizedBox(height: 20),

                // ── Spin & Win Entry ─────────────────────────────────
                _buildSpinWinCard(state, isDark),

                const SizedBox(height: 20),

                // ── Claim Reward Button ──────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _showClaimRewardSheet(context, state),
                  icon: const Icon(Icons.redeem_rounded),
                  label: Text(
                    'Claim Reward',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Watch & Earn ─────────────────────────────────────
                _buildWatchEarn(state, isDark),

                const SizedBox(height: 24),

                // ── Transaction History ──────────────────────────────
                _buildHistory(state, isDark),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 3-cards row ──────────────────────────────────────────────────
  Widget _buildBalanceCards(WalletState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2980).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MY CURRENCIES',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _currencyCard(
                Image.asset(
                  'assets/images/coin_sticker.png',
                  width: 32,
                  height: 32,
                ),
                'IR Coins',
                state.irCoins.toStringAsFixed(2),
              ),
              _vDivider(),
              _currencyCard(
                Image.asset(
                  'assets/images/red_cricket_ball_sticker.png',
                  width: 32,
                  height: 32,
                ),
                'Balls',
                '${state.balls}',
              ),
              _vDivider(),
              _currencyCard(
                Image.asset(
                  'assets/images/cricket_bat_sticker.png',
                  width: 32,
                  height: 32,
                ),
                'Bats',
                '${state.bats}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              AdHelper.showInterstitialAd(() {
                context.push('/leaderboard');
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'See where you stand globally',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyCard(Widget icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(height: 32, child: icon),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 70,
    color: Colors.white24,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _buildSpinWinCard(WalletState state, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AdHelper.showInterstitialAd(() {
            context.push('/spin-wheel');
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE53935).withOpacity(0.15),
                const Color(0xFFB71C1C).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.gesture_rounded,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spin & Win 🎰',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      state.canSpinFree
                          ? 'Your daily FREE spin is ready!'
                          : 'Watch an ad for extra spins!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Watch & Earn ────────────────────────────────────────────────
  Widget _buildWatchEarn(WalletState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch & Earn',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Get 💰 Bonus IR Coins per ad',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.adsWatchedToday}/5 Done',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.adsWatchedToday / 5,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.adsWatchedToday >= 5 ? null : _showRewardedAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                state.adsWatchedToday >= 5
                    ? 'Mission Complete ✅'
                    : 'Watch Video (Earn Coins)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction History ─────────────────────────────────────────
  Widget _buildHistory(WalletState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Icon(Icons.history, size: 20, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        if (state.transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No transactions yet',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.transactions.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.grey.withOpacity(0.1)),
            itemBuilder: (context, index) {
              final tx = state.transactions[index];
              return _buildTxTile(tx, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildTxTile(WalletTransaction tx, bool isDark) {
    // Pick icon and color based on type
    final (icon, color) = switch (tx.type) {
      RewardType.coins => (
        Image.asset('assets/images/coin_sticker.png', width: 24, height: 24),
        const Color(0xFFFFB300),
      ),
      RewardType.balls => (
        Image.asset(
          'assets/images/red_cricket_ball_sticker.png',
          width: 24,
          height: 24,
        ),
        const Color(0xFF1565C0),
      ),
      RewardType.bats => (
        Image.asset(
          'assets/images/cricket_bat_sticker.png',
          width: 24,
          height: 24,
        ),
        const Color(0xFF6A1B9A),
      ),
    };

    final label = switch (tx.type) {
      RewardType.coins => 'IR Coins',
      RewardType.balls => 'Balls',
      RewardType.bats => 'Bats',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: icon),
      ),
      title: Text(
        tx.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        DateFormat('dd MMM, hh:mm a').format(tx.date),
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
      ),
      trailing: Text(
        '${tx.isCredit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} $label',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: tx.isCredit
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
        ),
      ),
    );
  }

  void _showClaimRewardSheet(BuildContext context, WalletState state) {
    final hasEnough = state.irCoins >= 300;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              hasEnough ? Icons.emoji_events_rounded : Icons.lock_rounded,
              color: hasEnough ? const Color(0xFFFFB300) : Colors.red,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              hasEnough ? 'Reward Coming Soon! 🎉' : 'Keep Earning! 💪',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: hasEnough ? const Color(0xFFFFB300) : Colors.red[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasEnough
                  ? 'You have ${state.irCoins.toStringAsFixed(0)} IR Coins! Exciting rewards are on the way — stay tuned for the next update.'
                  : 'You need at least 300 IR Coins to claim rewards. Spin the wheel and watch ads to earn more!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEnough
                      ? const Color(0xFFFFB300)
                      : const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  hasEnough ? 'Got It!' : 'Keep Earning',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
