import 'dart:async';
import '../models/control_data.dart';

class JoystickService {
  Function(ControlData)? _onDataReceived;
  bool _isActive = false;
  double _sensitivity = 1.0;
  
  // Current joystick position (-1.0 to 1.0 for both x and y)
  double _currentX = 0.0;
  double _currentY = 0.0;
  
  // Timer for continuous data sending
  Timer? _dataTimer;
  static const Duration _sendInterval = Duration(milliseconds: 100); // Send data every 100ms

  bool get isActive => _isActive;
  double get sensitivity => _sensitivity;
  double get currentX => _currentX;
  double get currentY => _currentY;

  void setSensitivity(double value) {
    _sensitivity = value;
  }

  void start({required Function(ControlData) onDataReceived}) {
    if (_isActive) return;

    _onDataReceived = onDataReceived;
    _isActive = true;
    
    // Start continuous data sending
    _dataTimer = Timer.periodic(_sendInterval, (timer) {
      _sendCurrentData();
    });
  }

  void stop() {
    _dataTimer?.cancel();
    _dataTimer = null;
    _onDataReceived = null;
    _isActive = false;
    
    // Reset joystick position
    _currentX = 0.0;
    _currentY = 0.0;
  }

  void updateJoystickPosition(double x, double y) {
    // Clamp values to -1.0 to 1.0 range
    _currentX = x.clamp(-1.0, 1.0);
    _currentY = y.clamp(-1.0, 1.0);
    
    // Send data immediately when joystick moves
    if (_isActive) {
      _sendCurrentData();
    }
  }

  void _sendCurrentData() {
    if (_onDataReceived != null) {
      final controlData = ControlData(
        x: _currentX,
        y: _currentY,
        z: 0.0, // Not used for joystick
        sensitivity: _sensitivity,
      );
      _onDataReceived!.call(controlData);
    }
  }

  void dispose() {
    stop();
  }
}
