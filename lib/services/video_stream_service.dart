import 'dart:async';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

class VideoStreamService {
  String? _streamUrl;
  bool _isStreaming = false;
  Timer? _connectionTestTimer;
  Function(bool)? _onStreamStatusChanged;

  bool get isStreaming => _isStreaming;
  String? get streamUrl => _streamUrl;

  // Set callback for stream status changes
  void setStreamStatusCallback(Function(bool) callback) {
    _onStreamStatusChanged = callback;
  }

  // Start video stream from ESP32-CAM
  Future<bool> startVideoStream(String ipAddress, {int port = 80}) async {
    if (_isStreaming) {
      Logger.log('Video stream already running');
      return true;
    }

    try {
      // Construct the stream URL (ESP32-CAM serves MJPEG stream on root path)
      _streamUrl = 'http://$ipAddress:$port/';
      
      // Test if the ESP32-CAM is reachable
      final isReachable = await _testConnection(ipAddress, port);
      
      if (!isReachable) {
        Logger.log('ESP32-CAM not reachable at $_streamUrl');
        _streamUrl = null;
        return false;
      }

      _isStreaming = true;
      Logger.log('Video stream started: $_streamUrl');
      
      // Start periodic connection test
      _startConnectionMonitoring(ipAddress, port);
      
      _onStreamStatusChanged?.call(true);
      return true;
      
    } catch (e) {
      Logger.log('Failed to start video stream: $e');
      _streamUrl = null;
      _isStreaming = false;
      _onStreamStatusChanged?.call(false);
      return false;
    }
  }

  // Stop video stream
  void stopVideoStream() {
    if (!_isStreaming) return;

    _connectionTestTimer?.cancel();
    _connectionTestTimer = null;
    _streamUrl = null;
    _isStreaming = false;
    
    Logger.log('Video stream stopped');
    _onStreamStatusChanged?.call(false);
  }

  // Test connection to ESP32-CAM
  Future<bool> _testConnection(String ipAddress, int port) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:$port/'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));
      
      // Check if response indicates a video stream (MJPEG content type)
      final contentType = response.headers['content-type'] ?? '';
      return response.statusCode == 200 && 
             (contentType.contains('multipart/x-mixed-replace') || 
              contentType.contains('image/jpeg'));
              
    } catch (e) {
      Logger.log('Connection test failed: $e');
      return false;
    }
  }

  // Monitor connection status periodically
  void _startConnectionMonitoring(String ipAddress, int port) {
    _connectionTestTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        final isConnected = await _testConnection(ipAddress, port);
        if (!isConnected && _isStreaming) {
          Logger.log('Lost connection to ESP32-CAM, stopping stream');
          stopVideoStream();
        }
      },
    );
  }

  // Get stream info for display
  Map<String, dynamic> getStreamInfo() {
    return {
      'isStreaming': _isStreaming,
      'streamUrl': _streamUrl,
      'status': _isStreaming ? 'Connected' : 'Disconnected',
    };
  }

  void dispose() {
    stopVideoStream();
  }
}
