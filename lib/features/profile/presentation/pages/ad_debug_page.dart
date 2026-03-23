import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cricket_live_score/core/utils/ad_helper.dart';

class AdDebugPage extends StatefulWidget {
  const AdDebugPage({super.key});

  @override
  State<AdDebugPage> createState() => _AdDebugPageState();
}

class _AdDebugPageState extends State<AdDebugPage> {
  bool _isLoadingInterstitial = false;

  void _loadInterstitial() {
    setState(() => _isLoadingInterstitial = true);
    AdHelper.loadInterstitialAd(
      onAdDismissed: () {
        if (mounted) {
          debugPrint('AdDebugPage: Interstitial Dismissed');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interstitial Dismissed')),
          );
        }
      },
    );
    // Simulate a delay or just wait a bit
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoadingInterstitial = false);
    });
  }

  void _showInterstitial() {
    AdHelper.showInterstitialAd(() {
      debugPrint('AdDebugPage: Interstitial Shown & Dismissed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interstitial Shown & Dismissed')),
      );
    });
  }

  Future<void> _openInspector() async {
    try {
      MobileAds.instance.openAdInspector((error) {
        if (error != null) {
          debugPrint('AdDebugPage Error: ${error.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ad Inspector Error: ${error.message}')),
          );
        }
      });
    } catch (e) {
      debugPrint('AdDebugPage Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad Inspector Exception: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Mediation Debug'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.bug_report, size: 48, color: Colors.blue),
                    SizedBox(height: 12),
                    Text(
                      'AdMob Mediation Tester',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use the buttons below to load an ad and inspect the mediation waterfall.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isLoadingInterstitial ? null : _loadInterstitial,
              icon: _isLoadingInterstitial
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Load Interstitial Ad'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showInterstitial,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Show Interstitial Ad'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openInspector,
              icon: const Icon(Icons.manage_search),
              label: const Text('Open Ad Inspector'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            const Text(
              'Supported Networks: Unity Ads, Meta Audience Network, IronSource',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
