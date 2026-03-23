import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/services/remote_config_service.dart';
import 'package:cricketbuzz/features/ugc/presentation/cubit/ugc_cubit.dart';
import 'package:cricketbuzz/features/ugc/domain/entities/ugc_post_entity.dart';
import '../../../../core/utils/ad_helper.dart';
import 'ugc_webview_page.dart';

class UGCFeedPage extends StatefulWidget {
  const UGCFeedPage({super.key});

  @override
  State<UGCFeedPage> createState() => _UGCFeedPageState();
}

class _UGCFeedPageState extends State<UGCFeedPage> {
  @override
  void initState() {
    super.initState();
    context.read<UGCCubit>().loadPosts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.feed_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              RemoteConfigService.instance.liveFeedTitle,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<UGCCubit>().refreshPosts(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/ugc-feed/create');
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      body: BlocBuilder<UGCCubit, UGCState>(
        builder: (context, state) {
          if (state is UGCLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state is UGCError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Failed to load posts',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<UGCCubit>().refreshPosts(),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        'Retry',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is UGCEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nothing here yet!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Be the first to create one.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is UGCLoaded || state is UGCLoadingMore) {
            final posts = (state is UGCLoaded) 
                ? state.posts 
                : (state as UGCLoadingMore).posts;
            
            final totalCount = (state is UGCLoaded) ? state.totalCount : 0;
            final currentPage = (state is UGCLoaded) ? state.currentPage : 1;

            if (posts.isEmpty) return const SizedBox.shrink();

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: state is UGCLoadingMore 
                      ? const SizedBox(
                          height: 400,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                        )
                      : _UGCPostCard(post: posts[0]),
                  ),
                ),
                
                // ─── Numbered Pagination Boxes ───
                if (totalCount > 1)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121418) : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 16),
                              ...List.generate(totalCount, (index) {
                                final pageNum = index + 1;
                                final isActive = pageNum == currentPage;

                                return GestureDetector(
                                  onTap: isActive ? null : () => context.read<UGCCubit>().goToPage(pageNum),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isActive 
                                          ? AppColors.primaryGreen 
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isActive 
                                            ? AppColors.primaryGreen 
                                            : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey[300]!),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$pageNum',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                          color: isActive 
                                              ? Colors.white 
                                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _UGCPostCard extends StatelessWidget {
  final UGCPost post;

  const _UGCPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: isDark 
            ? Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1)
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Essential: card wraps its content
          children: [
            // ─── Image Section ──────────────
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              GestureDetector(
                onTap: (post.externalUrl != null && post.externalUrl!.isNotEmpty)
                    ? () => AdHelper.showInterstitialAd(() {
                          _launchURL(context, post.externalUrl!);
                        })
                    : null,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 220,
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tap Hint for Links
                    if (post.externalUrl != null && post.externalUrl!.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    // Tag Overlay
                    if (post.customTag != null && post.customTag!.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            post.customTag!.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // ─── Content Section ────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[800],
                    ),
                  ),
                  
                  // ─── Link Button ───
                  if (post.externalUrl != null && post.externalUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _AnimatedLinkButton(
                        url: post.externalUrl!,
                        label: post.linkName?.isNotEmpty == true 
                            ? post.linkName! 
                            : 'TAP HERE LIVE',
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ─── Footer: User Info ──────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (post.userAvatar != null && post.userAvatar!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: post.userAvatar!,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 18,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) => const CircleAvatar(
                        radius: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                      child: const Icon(Icons.person_rounded, size: 18, color: AppColors.primaryGreen),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d • h:mm a').format(post.timestamp),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.show_chart_rounded, size: 12, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          '${post.views}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLinkButton extends StatefulWidget {
  final String url;
  final String label;

  const _AnimatedLinkButton({required this.url, required this.label});

  @override
  State<_AnimatedLinkButton> createState() => _AnimatedLinkButtonState();
}

class _AnimatedLinkButtonState extends State<_AnimatedLinkButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
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
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3 * (1 + (_pulseAnimation.value - 1) * 10)),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AdHelper.showRewardedAd(
                    onEarnedReward: (_) {},
                    onAdDismissed: () {
                      _launchURL(context, widget.url);
                    },
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF3B30),
                        const Color(0xFFFF2D55),
                        const Color(0xFFFF3B30).withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [
                        0.0,
                        (0.5 + _shimmerAnimation.value).clamp(0.0, 1.0),
                        1.0,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(
                          widget.label.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void _launchURL(BuildContext context, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => UGCWebViewPage(url: url),
    ),
  );
}
