import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/joystick_service.dart';
import '../services/connection_service.dart';
import '../models/control_data.dart';
import '../models/bluetooth_device.dart';
import '../models/wifi_network.dart';
import '../models/sensor_data.dart';

class CarControlProvider with ChangeNotifier {
  final JoystickService _joystickService = JoystickService();
  final ConnectionService _connectionService = ConnectionService();
  StreamSubscription<SensorData>? _sensorDataSubscription;
  bool get isControlActive => _joystickService.isActive;
  double get sensitivity => _joystickService.sensitivity;
  ConnectionType get connectionType => _connectionService.connectionType;
  ConnectionStatus get connectionStatus => _connectionService.connectionStatus;
  String get errorMessage => _connectionService.errorMessage;
  
  ControlData? _lastControlData;
  ControlData? get lastControlData => _lastControlData;
  
  SensorData? _lastSensorData;
  SensorData? get lastSensorData => _lastSensorData;

  CarControlProvider() {
    // Listen to sensor data stream
    _sensorDataSubscription = _connectionService.sensorDataStream.listen(
      (sensorData) {
        _lastSensorData = sensorData;
        notifyListeners();
      },
    );
  }

  void toggleControl() {
    if (isControlActive) {
      stopControl();
    } else {
      startControl();
    }
  }
  void startControl() {
    if (_connectionService.connectionStatus != ConnectionStatus.connected) {
      // Can't start if not connected
      return;
    }

    _joystickService.start(onDataReceived: _handleJoystickData);
    notifyListeners();
  }

  void stopControl() {
    _joystickService.stop();
    notifyListeners();
  }

  void setSensitivity(double value) {
    _joystickService.setSensitivity(value);
    notifyListeners();
  }

  void updateJoystickPosition(double x, double y) {
    _joystickService.updateJoystickPosition(x, y);
  }

  Future<bool> connectWifi(String ipAddress, int port) async {
    final result = await _connectionService.connectWifi(ipAddress, port);
    notifyListeners();
    return result;
  }

  Future<bool> connectBluetooth(String address) async {
    final result = await _connectionService.connectBluetooth(address);
    notifyListeners();
    return result;
  }

  Future<void> disconnect() async {
    await _connectionService.disconnect();
    notifyListeners();
  }

  Future<List<BluetoothDevice>> scanBluetoothDevices() {
    return _connectionService.scanBluetoothDevices();
  }

  Future<List<WiFiNetwork>> scanWifiNetworks() {
    return _connectionService.scanWifiNetworks();
  }
  void _handleJoystickData(ControlData data) {
    _lastControlData = data;
    _connectionService.sendControlData(data);
    notifyListeners();
  }  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _joystickService.dispose();
    _connectionService.disconnect();
    _connectionService.dispose();
    super.dispose();
  }
}
