import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class PortalViewerPage extends StatefulWidget {
  final Uri feewPath;

  const PortalViewerPage({super.key, required this.feewPath});

  @override
  State<PortalViewerPage> createState() => _PortalViewerPageState();
}

class _PortalViewerPageState extends State<PortalViewerPage> {
  late final WebViewController _controller;
  bool _canNavigateBack = false;
  int? _activeEdgePointerId;
  Offset? _edgeDragOrigin;
  static const String _iosSafariUserAgent =
      'Version/17.2 Mobile/15E148 Safari/604.1';

  @override
  void initState() {
    super.initState();
    _controller = _initController();
    _refreshNavigationState();
  }

  WebViewController _initController() {
    final PlatformWebViewControllerCreationParams params =
        switch (WebViewPlatform.instance) {
          WebKitWebViewPlatform _ => WebKitWebViewControllerCreationParams(),
          AndroidWebViewPlatform _ => AndroidWebViewControllerCreationParams(),
          _ => const PlatformWebViewControllerCreationParams(),
        };

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) => _refreshNavigationState(),
              onPageFinished: (_) => _refreshNavigationState(),
              onNavigationRequest: _handleNavigationOverride,
            ),
          )
          ..setOnJavaScriptAlertDialog(
            (JavaScriptAlertDialogRequest request) async =>
                _presentJsAlert(request.message),
          )
          ..setOnJavaScriptConfirmDialog(
            (JavaScriptConfirmDialogRequest request) async =>
                _presentJsConfirm(request.message),
          )
          ..setOnJavaScriptTextInputDialog(
            (JavaScriptTextInputDialogRequest request) async =>
                _presentJsPrompt(
                  message: request.message,
                  defaultText: request.defaultText ?? '',
                ),
          );

    if (controller.platform is WebKitWebViewController) {
      (controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
      controller.setUserAgent(_iosSafariUserAgent);
    } else if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(widget.feewPath);

    return controller;
  }

  Future<void> _refreshNavigationState() async {
    final bool canGoBack = await _controller.canGoBack();
    if (!mounted) {
      return;
    }
    setState(() {
      _canNavigateBack = canGoBack;
    });
  }

  Future<void> _navigateBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      await _refreshNavigationState();
    }
  }

  Future<void> _presentJsAlert(String message) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _presentJsConfirm(String message) async {
    if (!mounted) {
      return false;
    }
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm action'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<String> _presentJsPrompt({
    required String message,
    required String defaultText,
  }) async {
    if (!mounted) {
      return defaultText;
    }
    final TextEditingController textController = TextEditingController(
      text: defaultText,
    );
    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter value'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              const SizedBox(height: 12),
              TextField(controller: textController, autofocus: true),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(defaultText),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(textController.text),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return result ?? defaultText;
  }

  Future<NavigationDecision> _handleNavigationOverride(
    NavigationRequest request,
  ) async {
    final Uri? destination = Uri.tryParse(request.url);
    if (destination == null) {
      return NavigationDecision.prevent;
    }

    if (_isInternalScheme(destination.scheme)) {
      return NavigationDecision.navigate;
    }

    await launchUrl(destination, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  bool _isInternalScheme(String? scheme) {
    if (scheme == null) {
      return false;
    }
    return switch (scheme.toLowerCase()) {
      "http" ||
      "https" ||
      "about" ||
      "srcdoc" ||
      "blob" ||
      "data" ||
      "javascript" ||
      "file" => true,
      _ => false,
    };
  }

  void _handleEdgePointerDown(PointerDownEvent event) {
    if (event.localPosition.dx <= 32) {
      _activeEdgePointerId = event.pointer;
      _edgeDragOrigin = event.localPosition;
    }
  }

  void _handleEdgePointerMove(PointerMoveEvent event) {
    if (_activeEdgePointerId != event.pointer || _edgeDragOrigin == null) {
      return;
    }
    final double delta = event.localPosition.dx - _edgeDragOrigin!.dx;
    if (delta > 24) {
      _activeEdgePointerId = null;
      _edgeDragOrigin = null;
      _navigateBack();
    }
  }

  void _handleEdgePointerUp(PointerUpEvent event) {
    if (_activeEdgePointerId == event.pointer) {
      _activeEdgePointerId = null;
      _edgeDragOrigin = null;
    }
  }

  void _handleEdgePointerCancel(PointerCancelEvent event) {
    if (_activeEdgePointerId == event.pointer) {
      _activeEdgePointerId = null;
      _edgeDragOrigin = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canNavigateBack,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          await _refreshNavigationState();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: ColoredBox(
            color: Colors.black,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handleEdgePointerDown,
              onPointerMove: _handleEdgePointerMove,
              onPointerUp: _handleEdgePointerUp,
              onPointerCancel: _handleEdgePointerCancel,
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ),
      ),
    );
  }
}
