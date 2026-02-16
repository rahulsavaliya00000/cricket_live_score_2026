import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = 'https://m.cricbuzz.com/live-cricket-scores';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh browser every 60 seconds (1 minute)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted && !_isLoading) {
        _controller.reload();
      }
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Block ad domains
            final blockedDomains = [
              'doubleclick.net',
              'googlesyndication.com',
              'adservice',
              'ads.',
              'advertising',
              'googleads',
              'ad-',
              'banner',
              'popup',
            ];

            final uri = Uri.parse(request.url);
            for (var domain in blockedDomains) {
              if (uri.host.contains(domain) || request.url.contains(domain)) {
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            // Inject CSS immediately when page starts loading
            _injectBlockingCSS();
          },
          onPageFinished: (String url) {
            // Inject comprehensive blocking after page loads
            _hidePromotionalElements();
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _injectBlockingCSS() {
    // Inject CSS immediately to prevent flashing
    const quickCSS = '''
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          nav, footer, [class*="nav"], [class*="footer"],
          [class*="banner"], [class*="ad-"], [class*="ads"],
          iframe, .cb-nav-main, .cb-nav-bottom {
            display: none !important;
            visibility: hidden !important;
            height: 0 !important;
            opacity: 0 !important;
          }
          
          /* Remove extra spacing */
          body, html {
            margin: 0 !important;
            padding: 0 !important;
          }
          
          body > div:first-child,
          body > header,
          .cb-hdr-main,
          [class*="header"] {
            margin-top: 0 !important;
            padding-top: 0 !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''';
    _controller.runJavaScript(quickCSS);
  }

  void _hidePromotionalElements() {
    // JavaScript to hide app install banners and promotional elements
    const script = '''
      (function() {
        // Inject comprehensive CSS to hide elements
        var style = document.createElement('style');
        style.innerHTML = `
          /* Hide ALL navigation bars */
          nav,
          .cb-nav-main,
          .cb-nav-bottom,
          [class*="bottom-nav"],
          [class*="nav-bar"],
          [class*="navigation"],
          .cb-footer-nav,
          footer nav,
          nav[class*="bottom"],
          div[class*="bottom-nav"],
          /* Hide headers */
          header,
          .cb-hdr-main,
          [class*="header"],
          /* Hide top header elements */
          .cb-app-banner,
          .cb-hm-rght,
          .cb-app-btn,
          [class*="get-app"],
          [class*="install-app"],
          /* Hide ALL footers */
          footer,
          .cb-footer,
          [class*="footer"],
          /* Hide popups and modals */
          .cb-ovr-flo,
          .cb-app-install-popup,
          [class*="app-install"],
          [class*="popup"],
          [class*="modal"],
          .overlay,
          .modal-backdrop,
          .cb-backdrop,
          [class*="overlay"],
          /* Hide sticky banners */
          [class*="sticky-banner"],
          [class*="app-banner"],
          [class*="sticky"],
          .cb-stickyad,
          /* Hide ALL ads and promotional content */
          [class*="ad-"],
          [class*="ads"],
          [class*="advertisement"],
          [id*="ad-"],
          [id*="ads"],
          .ad,
          .ads,
          ins.adsbygoogle,
          [class*="sponsor"],
          [class*="promo"],
          [data-ad],
          [data-advertisement],
          /* Hide ALL iframes (they're usually ads) */
          iframe {
            display: none !important;
            visibility: hidden !important;
            height: 0 !important;
            min-height: 0 !important;
            max-height: 0 !important;
            opacity: 0 !important;
            position: absolute !important;
            left: -9999px !important;
          }
          
          /* Remove all margins and padding */
          body, html {
            padding: 0 !important;
            margin: 0 !important;
            padding-bottom: 0 !important;
            margin-bottom: 0 !important;
            padding-top: 0 !important;
            margin-top: 0 !important;
            overflow: auto !important;
          }
          
          /* Remove spacing from main content containers */
          main,
          [role="main"],
          .cb-col-100,
          .cb-col,
          body > div:first-child {
            margin-top: 0 !important;
            padding-top: 0 !important;
          }
        `;
        
        // Remove any existing style tags and add ours
        var existingStyles = document.querySelectorAll('style[data-blocker]');
        existingStyles.forEach(function(s) { s.remove(); });
        style.setAttribute('data-blocker', 'true');
        document.head.appendChild(style);
        
        // Function to aggressively hide elements
        function hideElements() {
          // Remove header elements
          var headers = document.querySelectorAll('header, .cb-hdr-main, [class*="header"], [id*="header"]');
          headers.forEach(function(header) {
            header.remove();
          });
          
          // Hide all navigation elements
          var allNavs = document.querySelectorAll('nav, [role="navigation"], [class*="nav"], [id*="nav"]');
          allNavs.forEach(function(nav) {
            nav.remove(); // Remove instead of just hiding
          });
          
          // Hide all footer elements
          var footers = document.querySelectorAll('footer, [class*="footer"], [id*="footer"]');
          footers.forEach(function(footer) {
            footer.remove();
          });
          
          // Remove ALL iframes (ads, tracking, etc)
          var iframes = document.querySelectorAll('iframe');
          iframes.forEach(function(iframe) {
            iframe.remove();
          });
          
          // Remove ad-related divs
          var adElements = document.querySelectorAll('[class*="ad-"], [class*="ads"], [id*="ad-"], [id*="ads"], ins.adsbygoogle');
          adElements.forEach(function(ad) {
            ad.remove();
          });
          
          // Remove extra padding/margin from body and main content
          document.body.style.margin = '0';
          document.body.style.padding = '0';
          document.documentElement.style.margin = '0';
          document.documentElement.style.padding = '0';
          
          // Find main content area and remove top margin/padding
          var mainContent = document.querySelector('main, [role="main"], .cb-col-100, .cb-col');
          if (mainContent) {
            mainContent.style.marginTop = '0';
            mainContent.style.paddingTop = '0';
          }
          
          // Hide all fixed/sticky positioned elements at the bottom or top
          var allElements = document.querySelectorAll('*');
          allElements.forEach(function(el) {
            try {
              var styles = window.getComputedStyle(el);
              if (styles.position === 'fixed' || styles.position === 'sticky') {
                var rect = el.getBoundingClientRect();
                // If it's positioned at the bottom (within 150px of bottom) or top (within 150px of top)
                if (rect.bottom > window.innerHeight - 150 || rect.top > window.innerHeight - 150 || rect.top < 150) {
                  el.remove();
                }
              }
            } catch(e) {}
          });
          
          // Remove any elements with "banner" or "popup" in their classes
          var banners = document.querySelectorAll('[class*="banner"], [class*="popup"]');
          banners.forEach(function(banner) {
            banner.remove();
          });
        }
        
        // Run immediately and repeatedly
        hideElements();
        setTimeout(hideElements, 100);
        setTimeout(hideElements, 300);
        setTimeout(hideElements, 500);
        setTimeout(hideElements, 1000);
        setTimeout(hideElements, 2000);
        setTimeout(hideElements, 3000);
        
        // Watch for DOM changes and remove unwanted elements
        var observer = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
              if (node.nodeType === 1) { // Element node
                // Check if it's an ad or nav element
                var nodeName = node.nodeName.toLowerCase();
                var className = node.className || '';
                var id = node.id || '';
                
                if (nodeName === 'iframe' || 
                    nodeName === 'nav' || 
                    nodeName === 'header' ||
                    nodeName === 'footer' ||
                    className.toString().match(/ad|nav|header|footer|banner|popup/i) ||
                    id.toString().match(/ad|nav|header|footer|banner|popup/i)) {
                  node.remove();
                }
              }
            });
          });
          hideElements();
        });
        
        observer.observe(document.body, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ['style', 'class', 'id']
        });
        
        // Also check on scroll
        var scrollTimeout;
        window.addEventListener('scroll', function() {
          clearTimeout(scrollTimeout);
          scrollTimeout = setTimeout(hideElements, 100);
        });
      })();
    ''';

    _controller.runJavaScript(script);
  }

  void _goBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    }
  }

  void _goForward() async {
    if (await _controller.canGoForward()) {
      _controller.goForward();
    }
  }

  void _refresh() {
    _controller.reload();
    // Add a slight delay before hiding elements to ensure page is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _hidePromotionalElements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Matches',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goBack,
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: _goForward,
            tooltip: 'Forward',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    const SizedBox(height: 16),
                    Text(
                      'Loading live matches...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
