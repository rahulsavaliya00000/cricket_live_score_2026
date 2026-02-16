import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TeamFlag extends StatelessWidget {
  final String flagUrl;
  final double size;

  const TeamFlag({super.key, required this.flagUrl, this.size = 24.0});

  bool get _isUrl => flagUrl.startsWith('http');
  bool get _isEmoji =>
      flagUrl.isNotEmpty &&
      (flagUrl.codeUnits.any((unit) => unit >= 0x1F1E6 && unit <= 0x1F1FF));

  @override
  Widget build(BuildContext context) {
    // Handle empty flag
    if (flagUrl.isEmpty) {
      return _buildFallbackIcon();
    }

    // Handle emoji flags (like 🇮🇳)
    if (_isEmoji) {
      return Text(flagUrl, style: TextStyle(fontSize: size * 0.8));
    }

    // Handle URL flags
    if (_isUrl) {
      return SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: flagUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: size * 0.5,
              height: size * 0.5,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackIcon(),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
        ),
      );
    }

    // Fallback for any other case
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.sports_cricket, size: size * 0.6, color: Colors.grey),
    );
  }
}
