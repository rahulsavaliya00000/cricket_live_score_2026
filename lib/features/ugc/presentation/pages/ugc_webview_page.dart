import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UGCWebViewPage extends StatefulWidget {
  final String url;
  
  const UGCWebViewPage({super.key, required this.url});

  @override
  State<UGCWebViewPage> createState() => _UGCWebViewPageState();
}

class _UGCWebViewPageState extends State<UGCWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showWebview = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _showWebview = false;
            });
          },
          onPageFinished: (String url) {
            // Inject JavaScript to find the first iframe and scroll to it instantly
            _controller.runJavaScript('''
              setTimeout(function() {
                const iframes = document.getElementsByTagName('iframe');
                if (iframes.length > 0) {
                  const iframe = iframes[0];
                  // Scroll to the iframe instantly, offset slightly for the app bar
                  const y = iframe.getBoundingClientRect().top + window.scrollY - 50;
                  window.scrollTo({top: y, behavior: 'auto'});
                }
              }, 300); // Small delay to ensure dynamic content loads before measuring
            ''');

            // Wait for JS to execute and render before showing the webview
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _showWebview = true;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: \${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _showWebview = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121418) : Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Live Stream',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _showWebview ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
