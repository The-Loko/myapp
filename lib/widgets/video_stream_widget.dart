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
    this.isStreaming = false,
    this.onToggleStream,
    this.onIpAddressChanged,
  });

  @override
  State<VideoStreamWidget> createState() => _VideoStreamWidgetState();
}

class _VideoStreamWidgetState extends State<VideoStreamWidget> {
  final TextEditingController _ipController = TextEditingController();
  late final WebViewController _controller;
  bool _isScreenOn = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with default ESP32-CAM IP from readme.md
    _ipController.text = '192.168.225.97';
    
    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            Logger.log('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            Logger.log('Page started loading: $url');
          },
          onPageFinished: (String url) {
            Logger.log('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            Logger.log('Web resource error: ${error.description}');
          },
        ),
      );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _startVideoStream() {
    final ipAddress = _ipController.text.trim();
    if (ipAddress.isNotEmpty) {
      final streamUrl = 'http://$ipAddress';
      _controller.loadRequest(Uri.parse(streamUrl));
      setState(() {
        _isScreenOn = true;
      });
      Logger.log('Starting video stream from: $streamUrl');
      widget.onIpAddressChanged?.call(ipAddress);
    }
  }

  void _stopVideoStream() {
    _controller.loadRequest(Uri.parse('about:blank'));
    setState(() {
      _isScreenOn = false;
    });
    Logger.log('Stopping video stream');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'ESP32-CAM Video Stream',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // IP Address Input
                Row(
                  children: [
                    const Text(
                      'ESP32-CAM IP:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          hintText: '192.168.225.97',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          widget.onIpAddressChanged?.call(value);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Control Button (following readme.md pattern)
                ElevatedButton(
                  onPressed: () {
                    if (_isScreenOn == false) {
                      _startVideoStream();
                    } else {
                      _stopVideoStream();
                    }
                    widget.onToggleStream?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScreenOn ? Colors.red : AppColors.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _isScreenOn ? "Stop" : "Start",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Video Display Area
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isScreenOn
                        ? WebViewWidget(controller: _controller)
                        : const Center(
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
                                  'Video stream stopped',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Press Start to begin streaming',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Stream Info
                Text(
                  _isScreenOn 
                      ? 'Streaming from: http://${_ipController.text}'
                      : 'Stream URL: http://${_ipController.text}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
