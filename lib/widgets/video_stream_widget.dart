import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class VideoStreamWidget extends StatefulWidget {
  final String? streamUrl;
  final bool isStreaming;
  final VoidCallback? onToggleStream;
  final Function(String)? onIpAddressChanged;

  const VideoStreamWidget({
    super.key,
    this.streamUrl,
    required this.isStreaming,
    this.onToggleStream,
    this.onIpAddressChanged,
  });

  @override
  State<VideoStreamWidget> createState() => _VideoStreamWidgetState();
}

class _VideoStreamWidgetState extends State<VideoStreamWidget> {
  late WebViewController _webViewController;
  final TextEditingController _ipController = TextEditingController();
  bool _webViewInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    // Set default IP from ESP32 code (you might want to make this configurable)
    _ipController.text = '192.168.1.100'; // Default IP, user can change
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            Logger.log('Video stream page started loading: $url');
            setState(() {
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            Logger.log('Video stream page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            Logger.log('Video stream error: ${error.description}');
            setState(() {
              _hasError = true;
            });
          },
        ),
      );
    _webViewInitialized = true;
  }

  void _loadStream() {
    if (widget.streamUrl != null && _webViewInitialized) {
      _webViewController.loadRequest(Uri.parse(widget.streamUrl!));
      setState(() {
        _hasError = false;
      });
    }
  }

  @override
  void didUpdateWidget(VideoStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streamUrl != oldWidget.streamUrl && widget.streamUrl != null) {
      _loadStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: AppColors.secondaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'ESP32-CAM Video Stream',
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isStreaming ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.isStreaming ? 'LIVE' : 'OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // IP Address Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'ESP32-CAM IP Address',
                      hintText: '192.168.1.100',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wifi),
                    ),
                    onChanged: (value) {
                      widget.onIpAddressChanged?.call(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_ipController.text.isNotEmpty) {
                      widget.onIpAddressChanged?.call(_ipController.text);
                      widget.onToggleStream?.call();
                    }
                  },
                  icon: Icon(widget.isStreaming ? Icons.stop : Icons.play_arrow),
                  label: Text(widget.isStreaming ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isStreaming ? Colors.red : AppColors.accentColor,
                  ),
                ),
              ],
            ),
          ),

          // Video Stream Display
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildStreamContent(),
            ),
          ),

          // Stream Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStreamInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamContent() {
    if (!widget.isStreaming) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Video Stream Stopped',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter ESP32-CAM IP and press Start',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Connection Error',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check ESP32-CAM IP and WiFi connection',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.streamUrl == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WebViewWidget(controller: _webViewController);
  }

  Widget _buildStreamInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Stream Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.streamUrl != null)
          Text(
            'URL: ${widget.streamUrl}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Status: ${widget.isStreaming ? "Connected" : "Disconnected"}',
          style: TextStyle(
            fontSize: 12,
            color: widget.isStreaming ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Format: MJPEG Stream over HTTP',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
