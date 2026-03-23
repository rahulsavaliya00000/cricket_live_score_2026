import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricketbuzz/features/profile/presentation/bloc/premium_bloc.dart';
import 'package:go_router/go_router.dart';

enum NativeAdStyle {
  small, // 100px height — used at odd positions in lists (1st, 3rd, 5th…)
  medium, // 300px height — used at even positions in lists (2nd, 4th, 6th…)
  carousel, // Medium Rectangle (250px, scaled/clipped for horizontal carousels)
}

class NativeAdWidget extends StatefulWidget {
  final NativeAdStyle style;

  /// Pass the list index when inserting ads inside a ListView so that odd
  /// positions get [NativeAdStyle.small] and even get [NativeAdStyle.medium].
  /// Pass null (or use the named constructors) to hard-code the style.
  final int? listIndex;

  /// Optional callback fired once when the banner ad successfully loads.
  final VoidCallback? onAdLoaded;

  const NativeAdWidget({
    super.key,
    this.style = NativeAdStyle.small,
    this.listIndex,
    this.onAdLoaded,
  });

  /// Auto-alternating factory: pass the ad's position in the list.
  /// Index 0, 2, 4… → small; 1, 3, 5… → medium.
  factory NativeAdWidget.forIndex(int index, {Key? key}) {
    return NativeAdWidget(
      key: key,
      listIndex: index,
      style: index.isEven ? NativeAdStyle.small : NativeAdStyle.medium,
    );
  }

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _impressionFired = false;
  // True while a load is already in-flight — prevents double loads
  bool _isLoading = false;

  NativeAdStyle get _effectiveStyle => widget.style;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  void _loadAd() {
    if (!mounted || AdHelper.isPremium || _isLoading || _isAdLoaded) return;
    debugPrint('🎯 [NATIVE_AD_WIDGET] _loadAd() starting. mounted: $mounted | style: $_effectiveStyle');
    _isLoading = true;

    // Always load via the async queue — never pull synchronously from the pool.
    // Synchronous pool hand-off caused AdWidget-not-loaded crashes because the
    // new ad object arrived inside the same call stack as the previous setState,
    // before Flutter had a chance to unmount the old AdWidget.
    final size = _effectiveStyle == NativeAdStyle.small
        ? const AdSize(width: 320, height: 100)
        : AdSize.mediumRectangle;

    // 1. Try to get an instant ad from the pre-loaded pool
    final cachedAd = AdHelper.getBannerAd(size);
    if (cachedAd != null) {
      debugPrint('⚡🚀 [NATIVE_AD_WIDGET] INSTANT CACHE HIT! Using preloaded ad ($size)');
      _onAdLoaded(cachedAd);
      return;
    }

    // 2. Fallback to async load if pool is empty
    debugPrint('⏳📥 [NATIVE_AD_WIDGET] Cache is EMPTY for $size! Falling back to async queue load...');
    AdHelper.loadAdaptiveBanner(
      size: size,
      onLoaded: _onAdLoaded,
      onFailed: _onAdFailed,
      onImpression: _onImpression,
    );
  }

  void _onAdLoaded(BannerAd loadedAd) {
    debugPrint('✅🎉 [NATIVE_AD_WIDGET] Ad successfully LOADED callback received!');
    _isLoading = false;
    if (!mounted) {
      debugPrint('🗑️ [NATIVE_AD_WIDGET] Widget unmounted right after ad loaded. Disposing ad to prevent memory leak.');
      loadedAd.dispose();
      return;
    }
    // Dispose the previous ad only if it's a different object
    if (_bannerAd != null && _bannerAd != loadedAd) {
      debugPrint('♻️ [NATIVE_AD_WIDGET] Disposing old ad object because a new one arrived.');
      _bannerAd!.dispose();
    }
    setState(() {
      _bannerAd = loadedAd;
      _isAdLoaded = true;
      _impressionFired = false;
    });
    // Notify caller that the ad is ready
    widget.onAdLoaded?.call();
    // Schedule the impression fallback ONCE here — NOT inside build()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_impressionFired) _onImpression();
    });
  }

  void _onAdFailed() {
    debugPrint('❌💀 [NATIVE_AD_WIDGET] Ad FAILED to load callback received! Retrying in 10s...');
    _isLoading = false;
    if (!mounted) return;
    setState(() {
      _isAdLoaded = false;
      _bannerAd = null;
    });
    // Retry after 10s — by then the widget tree is definitely stable
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _loadAd();
    });
  }

  /// Called exactly once after the ad is first visibly rendered.
  /// Schedules a fresh creative after 60s (policy-safe minimum).
  void _onImpression() {
    if (_impressionFired) return;
    _impressionFired = true;
    Future.delayed(const Duration(seconds: 60), () {
      if (!mounted) return;
      final old = _bannerAd;
      setState(() {
        _bannerAd = null;
        _isAdLoaded = false;
        _impressionFired = false;
        _isLoading = false;
      });
      // Wait for the frame to complete (old AdWidget fully unmounted),
      // THEN dispose the old ad and start loading the new one.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AdHelper.releaseAd(old);
        if (mounted) _loadAd();
      });
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<PremiumBloc, PremiumState>(
      builder: (context, premiumState) {
        if (premiumState.isPremium) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final decoration = BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );

        // Defensive check: AdWidget crashes if ad.load() wasn't successful/finished.
        // Even if our flag says true, we double-check the ad object itself if possible.
        if (_isAdLoaded && _bannerAd != null) {
          if (_effectiveStyle == NativeAdStyle.carousel) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: double.infinity,
              decoration: decoration,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: _bannerAd!.size.height.toDouble(),
                          width: _bannerAd!.size.width.toDouble(),
                          child: AdWidget(
                            key: ValueKey('ad_${_bannerAd.hashCode}'),
                            ad: _bannerAd!,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ad',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Small or Medium — card with "Ad / Sponsored / Remove Ads" header
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            decoration: decoration,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ad',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sponsored',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          AdHelper.showInterstitialAd(
                            () => context.push('/premium'),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Remove Ads',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: _bannerAd!.size.height.toDouble(),
                    width: double.infinity,
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    child: Center(
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(
                          key: ValueKey('ad_${_bannerAd.hashCode}'),
                          ad: _bannerAd!,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        }

        // ── Shimmer placeholder ──────────────────────────────────────────
        final isCarousel = _effectiveStyle == NativeAdStyle.carousel;
        final isMedium = _effectiveStyle == NativeAdStyle.medium;
        final double shimmerHeight = isCarousel
            ? double.infinity
            : (isMedium ? 300 : 150);

        return Container(
          height: shimmerHeight,
          margin: isCarousel
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: decoration,
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.white10 : Colors.grey[300]!,
            highlightColor: isDark ? Colors.white24 : Colors.grey[100]!,
            child: isCarousel
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 60,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: isMedium ? 200 : 100,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
