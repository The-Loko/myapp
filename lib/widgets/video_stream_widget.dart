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
  final TextEditingController _ipController = TextEditingController();  late final WebViewController _controller;
  bool _isScreenOn = false;

  @override
  void initState() {
    super.initState();
      // Initialize with default ESP32-CAM IP from readme.md
    _ipController.text = '192.168.225.97';
    
    // Initialize WebView controller for ESP32-CAM video stream
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            Logger.log('ESP32-CAM video stream progress: $progress%');
          },
          onPageStarted: (String url) {
            Logger.log('ESP32-CAM stream started: $url');
          },
          onPageFinished: (String url) {
            Logger.log('ESP32-CAM stream loaded: $url');            // Inject CSS to properly scale video
            _controller.runJavaScript('''
              document.body.style.margin = '0';
              document.body.style.padding = '0';
              document.body.style.overflow = 'hidden';
              document.body.style.background = 'black';
              
              // Find and scale video/image elements
              var images = document.getElementsByTagName('img');
              for(var i = 0; i < images.length; i++) {
                images[i].style.width = '100%';
                images[i].style.height = '100%';
                images[i].style.objectFit = 'cover';
                images[i].style.display = 'block';
              }
              
              // Handle MJPEG stream containers
              var body = document.body;
              body.style.display = 'flex';
              body.style.justifyContent = 'center';
              body.style.alignItems = 'center';
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            Logger.log('ESP32-CAM stream error: ${error.description}');
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
        // Load the ESP32-CAM video stream
      _controller.loadRequest(Uri.parse(streamUrl));
      
      setState(() {
        _isScreenOn = true;
      });
      
      Logger.log('Starting ESP32-CAM video stream from: $streamUrl');
      Logger.log('Stream protocol: MJPEG over HTTP');
      Logger.log('Expected ESP32-CAM resolution: 640x480 or 800x600');
      
      widget.onIpAddressChanged?.call(ipAddress);
    }
  }

  void _stopVideoStream() {
    _controller.loadRequest(Uri.parse('about:blank'));
    setState(() {
      _isScreenOn = false;
    });
    Logger.log('Stopping video stream');
  }  /// Builds the video stream using WebView for MJPEG
  Widget _buildVideoStream() {
    return Stack(
      children: [
        // Primary video stream using WebView for MJPEG
        Positioned.fill(
          child: WebViewWidget(
            controller: _controller,
          ),
        ),
        
        // Overlay with stream info
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.aspect_ratio,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'ESP32-CAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Live indicator
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 8,
                ),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Protocol indicator
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'MJPEG',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                        ),                        onChanged: (value) {
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
                
                const SizedBox(height: 16),                // Video Display Area - ESP32-CAM Stream
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),                    child: _isScreenOn
                        ? _buildVideoStream()
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
                
                const SizedBox(height: 12),                  // Stream Info
                Column(
                  children: [
                    Text(
                      _isScreenOn 
                          ? 'Streaming from: http://${_ipController.text}'
                          : 'Stream URL: http://${_ipController.text}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),                    const SizedBox(height: 4),
                    Text(
                      'Protocol: MJPEG over WebView',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Connection Info and Troubleshooting
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stream Information:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'URL: ${_isScreenOn ? 'http://${_ipController.text}' : 'Not connected'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Text(
                  'Protocol: MJPEG over HTTP',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Text(
                  'Port: 80 (default)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                
                // Troubleshooting section
                const Text(
                  'Troubleshooting:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Ensure ESP32-CAM is connected to same WiFi network',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Text(
                  '• Check ESP32-CAM IP address (Serial Monitor)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Text(
                  '• Verify ESP32-CAM is running videostream.ino',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Text(
                  '• HTTP traffic is now allowed for local networks',
                  style: TextStyle(fontSize: 11, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
