import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Default URL — change if you need another page.
const String kDefaultWebGameUrl =
    'https://happyacres.centurygames.com/play/index';

class WebGameScreen extends StatefulWidget {
  const WebGameScreen({super.key, this.initialUrl = kDefaultWebGameUrl});

  final String initialUrl;

  @override
  State<WebGameScreen> createState() => _WebGameScreenState();
}

class _WebGameScreenState extends State<WebGameScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _loading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom:
            _loading
                ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
                : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
