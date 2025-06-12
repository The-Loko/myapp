import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum CameraStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class CameraService extends ChangeNotifier {
  static const String _streamPath = '/stream';
  static const String _capturePath = '/capture';
  static const String _statusPath = '/status';
  
  CameraStatus _status = CameraStatus.disconnected;
  String _errorMessage = '';
  String? _cameraIp;
  int _cameraPort = 80;
  
  StreamController<Uint8List>? _imageStreamController;
  StreamSubscription? _httpStreamSubscription;
  Timer? _reconnectTimer;
  
  // MJPEG parsing variables
  List<int> _buffer = [];
  bool _foundHeader = false;
  int _contentLength = 0;
  
  // Getters
  CameraStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? get cameraIp => _cameraIp;
  Stream<Uint8List>? get imageStream => _imageStreamController?.stream;
  bool get isConnected => _status == CameraStatus.connected;
  
  CameraService() {
    _imageStreamController = StreamController<Uint8List>.broadcast();
  }
  
  /// Connect to ESP32 CAM with given IP address
  Future<bool> connect(String ipAddress, {int port = 80}) async {
    if (_status == CameraStatus.connecting) {
      return false;
    }
    
    _status = CameraStatus.connecting;
    _errorMessage = '';
    _cameraIp = ipAddress;
    _cameraPort = port;
    notifyListeners();
    
    try {
      // Test connection by requesting status
      final statusUrl = 'http://$ipAddress:$port$_statusPath';
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        await _startImageStream();
        _status = CameraStatus.connected;
        _errorMessage = '';
        notifyListeners();
        return true;
      } else {
        throw Exception('Camera not responding (Status: ${response.statusCode})');
      }
    } catch (e) {
      _status = CameraStatus.error;
      _errorMessage = 'Failed to connect: ${e.toString()}';
      notifyListeners();
      
      // Schedule reconnection attempt
      _scheduleReconnect();
      return false;
    }
  }
  
  /// Start the image stream from ESP32 CAM
  Future<void> _startImageStream() async {
    if (_cameraIp == null) return;
    
    try {
      final streamUrl = 'http://$_cameraIp:$_cameraPort$_streamPath';
      final request = http.Request('GET', Uri.parse(streamUrl));
      request.headers['Connection'] = 'keep-alive';
      
      final client = http.Client();
      final response = await client.send(request);
      
      if (response.statusCode == 200) {
        _httpStreamSubscription = response.stream.listen(
          _processStreamData,
          onError: _handleStreamError,
          onDone: _handleStreamDone,
        );
      } else {
        throw Exception('Stream failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _handleStreamError(e);
    }
  }
    /// Process incoming stream data
  void _processStreamData(List<int> data) {
    try {
      _buffer.addAll(data);
      
      while (_buffer.isNotEmpty) {
        if (!_foundHeader) {
          // Look for JPEG header (FF D8) 
          int headerIndex = -1;
          for (int i = 0; i < _buffer.length - 1; i++) {
            if (_buffer[i] == 0xFF && _buffer[i + 1] == 0xD8) {
              headerIndex = i;
              break;
            }
          }
          
          if (headerIndex >= 0) {
            // Remove everything before the header
            _buffer = _buffer.sublist(headerIndex);
            _foundHeader = true;
          } else {
            // No header found, clear buffer and wait for more data
            _buffer.clear();
            break;
          }
        }
        
        if (_foundHeader) {
          // Look for JPEG footer (FF D9)
          int footerIndex = -1;
          for (int i = 1; i < _buffer.length - 1; i++) {
            if (_buffer[i] == 0xFF && _buffer[i + 1] == 0xD9) {
              footerIndex = i + 1;
              break;
            }
          }
          
          if (footerIndex >= 0) {
            // Extract complete JPEG image
            final imageData = Uint8List.fromList(_buffer.sublist(0, footerIndex + 1));
            
            // Send image to stream
            if (!_imageStreamController!.isClosed) {
              _imageStreamController!.add(imageData);
            }
            
            // Remove processed image from buffer
            _buffer = _buffer.sublist(footerIndex + 1);
            _foundHeader = false;
          } else {
            // Incomplete image, wait for more data
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing stream data: $e');
    }
  }
  
  /// Handle stream errors
  void _handleStreamError(dynamic error) {
    debugPrint('Camera stream error: $error');
    _status = CameraStatus.error;
    _errorMessage = 'Stream error: ${error.toString()}';
    notifyListeners();
    
    _scheduleReconnect();
  }
  
  /// Handle stream completion
  void _handleStreamDone() {
    debugPrint('Camera stream ended');
    if (_status == CameraStatus.connected) {
      _status = CameraStatus.disconnected;
      notifyListeners();
      _scheduleReconnect();
    }
  }
  
  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_cameraIp != null) {
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        if (_status != CameraStatus.connected && _cameraIp != null) {
          debugPrint('Attempting to reconnect to camera...');
          connect(_cameraIp!, port: _cameraPort);
        }
      });
    }
  }
    /// Capture a single image from ESP32 CAM
  Future<Uint8List?> captureImage() async {
    if (_cameraIp == null || _status != CameraStatus.connected) {
      return null;
    }
    
    try {
      final captureUrl = 'http://$_cameraIp:$_cameraPort$_capturePath';
      final response = await http.get(
        Uri.parse(captureUrl),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Capture failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }
    /// Disconnect from ESP32 CAM
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _httpStreamSubscription?.cancel();
    _httpStreamSubscription = null;
    
    // Clear MJPEG parsing state
    _buffer.clear();
    _foundHeader = false;
    _contentLength = 0;
    
    _status = CameraStatus.disconnected;
    _errorMessage = '';
    _cameraIp = null;
    notifyListeners();
  }
  
  /// Test if ESP32 CAM is reachable
  Future<bool> testConnection(String ipAddress, {int port = 80}) async {
    try {
      final statusUrl = 'http://$ipAddress:$port$_statusPath';
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _httpStreamSubscription?.cancel();
    _imageStreamController?.close();
    super.dispose();
  }
}
