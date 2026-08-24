import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String successRedirectUrl;
  final String failureRedirectUrl;
  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.successRedirectUrl,
    required this.failureRedirectUrl,
  });
  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            final lowerUrl = url.toLowerCase();

            // ✅ Handle UPI
            if (url.startsWith("upi://pay")) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }

            // ✅ Success
            if (url.contains(widget.successRedirectUrl)) {
              Navigator.pop(context, 'PAYMENT_COMPLETE');
              return NavigationDecision.prevent;
            }

            // ✅ Failure
            if (url.contains(widget.failureRedirectUrl) ||
                lowerUrl.contains('cancel') ||
                lowerUrl.contains('fail')) {
              Navigator.pop(context, 'PAYMENT_FAILED');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
