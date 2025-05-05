# myapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Connecting Android App to ESP32 via Bluetooth

1. Firmware
   - Ensure ESP32 runs the `gyrocar_esp32.ino` with `BluetoothSerial`.
   - ESP advertises under name `"GyroCar"`.

2. AndroidManifest
   - Grant `BLUETOOTH`, `BLUETOOTH_ADMIN`, and `ACCESS_FINE_LOCATION` permissions.

3. Runtime Permission
   - Request location permission in Flutter (e.g. via `permission_handler`).

4. Scanning & Connecting
   ```dart
   final devices = await provider.scanBluetoothDevices();
   await provider.connectBluetooth(devices.first.address);
   ```

5. Data Exchange
   - Send JSON‐formatted lines from Flutter:  
     `connectionService.sendData('{"x":1.0,"y":0.0,"z":0.0}\n');`  
   - On ESP32, read in `handleBluetoothData()` and parse.

6. Disconnect
   ```dart
   await provider.disconnect();
   ```
