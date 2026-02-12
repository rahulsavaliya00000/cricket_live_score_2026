import 'package:flutter/material.dart';

class TeamFlag extends StatelessWidget {
  final String flagUrl;
  final double size;

  const TeamFlag({super.key, required this.flagUrl, this.size = 24.0});

  bool get _isUrl => flagUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (flagUrl.isEmpty) {
      return Icon(Icons.flag_rounded, size: size, color: Colors.grey);
    }

    if (_isUrl) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.network(
          flagUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.flag_rounded, size: size, color: Colors.grey),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return Text(flagUrl, style: TextStyle(fontSize: size));
  }
}
