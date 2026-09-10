import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_typography.dart';

const String _hideSiteChromeCss = 'header,footer{display:none!important;}';

/// Read-only in-app viewer for legal pages (Terms, Privacy, Refund Policy).
///
/// Unlike `launchUrl(mode: LaunchMode.inAppWebView)`, which hands the page to
/// the OS's own browser chrome (Custom Tabs / SFSafariViewController), this
/// hosts the page in our own [InAppWebView] so we keep the user inside the
/// page they were shown: [shouldOverrideUrlLoading] only ever allows
/// navigating within the same host + path we loaded — link taps, redirects,
/// and popups all get cancelled. The site's own header/footer chrome is
/// hidden via injected CSS rather than a pixel crop, so it stays correct
/// regardless of viewport size or how tall that chrome actually renders.
///
/// [topClipHeight] is a fallback for chrome the CSS rule doesn't catch (not
/// wrapped in a real `<header>` tag, or matched by no available selector). It
/// crops a fixed number of pixels off the top of the *visible* webview
/// regardless of DOM structure, at the cost of not adapting to viewport size.
class PolicyWebViewScreen extends StatefulWidget {
  const PolicyWebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.topClipHeight = 180,
  });

  final String title;
  final String url;
  final double topClipHeight;

  @override
  State<PolicyWebViewScreen> createState() => _PolicyWebViewScreenState();
}

class _PolicyWebViewScreenState extends State<PolicyWebViewScreen> {
  bool _isLoading = true;
  late final Uri _allowedUri = Uri.parse(widget.url);

  bool _isAllowed(Uri? uri) {
    if (uri == null) return false;
    return uri.host == _allowedUri.host &&
        _normalizePath(uri.path) == _normalizePath(_allowedUri.path);
  }

  String _normalizePath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.title,
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final webview = InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialUserScripts: UnmodifiableListView([
                  UserScript(
                    source:
                        "document.documentElement.insertAdjacentHTML('beforeend',"
                        "'<style>$_hideSiteChromeCss</style>');",
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  ),
                ]),
                initialSettings: InAppWebViewSettings(
                  useShouldOverrideUrlLoading: true,
                  javaScriptEnabled: true,
                  supportZoom: false,
                  disableLongPressContextMenuOnLinks: true,
                  allowsLinkPreview: false,
                  allowsBackForwardNavigationGestures: false,
                  supportMultipleWindows: false,
                  disableDefaultErrorPage: true,
                ),
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url?.uriValue;
                  if (_isAllowed(uri)) {
                    return NavigationActionPolicy.ALLOW;
                  }
                  return NavigationActionPolicy.CANCEL;
                },
                onCreateWindow: (controller, createWindowAction) async => false,
                onLoadStart: (_, _) {
                  if (mounted) setState(() => _isLoading = true);
                },
                onLoadStop: (controller, _) async {
                  await controller.injectCSSCode(source: _hideSiteChromeCss);
                  if (mounted) setState(() => _isLoading = false);
                },
                onReceivedError: (_, _, _) {
                  if (mounted) setState(() => _isLoading = false);
                },
              );

              if (widget.topClipHeight <= 0) return webview;

              // SizedBox + Transform would silently get clamped back to
              // `constraints.maxHeight` here since every ancestor up to the
              // Scaffold body is bounded. OverflowBox genuinely overrides the
              // child's constraints regardless of the parent's bound, so the
              // webview really does lay out taller before the top gets
              // clipped away, rather than opening a blank gap.
              return ClipRect(
                child: OverflowBox(
                  minHeight: constraints.maxHeight + widget.topClipHeight,
                  maxHeight: constraints.maxHeight + widget.topClipHeight,
                  alignment: Alignment.bottomCenter,
                  child: webview,
                ),
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
