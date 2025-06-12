import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../services/camera_service.dart';
import '../utils/constants.dart';

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '80');
  bool _showSettings = false;
  Uint8List? _currentFrame;

  @override
  void initState() {
    super.initState();
    // Set default IP (you can change this or load from shared preferences)
    _ipController.text = '192.168.1.100'; // Default ESP32 CAM IP
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarControlProvider>(
      builder: (context, provider, child) {
        final cameraService = provider.cameraService;
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with title and settings button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Camera Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Status indicator
                        _buildStatusIndicator(cameraService.status),
                        const SizedBox(width: 8),
                        // Settings button
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showSettings = !_showSettings;
                            });
                          },
                          icon: Icon(_showSettings ? Icons.expand_less : Icons.settings),
                          tooltip: 'Camera Settings',
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Settings panel (collapsible)
                if (_showSettings) ...[
                  _buildSettingsPanel(cameraService),
                  const SizedBox(height: 16),
                ],
                
                // Camera preview area
                _buildCameraPreview(cameraService),
                
                const SizedBox(height: 16),
                
                // Control buttons
                _buildControlButtons(cameraService),
                
                // Error message
                if (cameraService.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withAlpha((0.1 * 255).round()),
                      border: Border.all(color: AppColors.errorColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cameraService.errorMessage,
                      style: const TextStyle(
                        color: AppColors.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(CameraStatus status) {
    Color color;
    String tooltip;
    
    switch (status) {
      case CameraStatus.connected:
        color = AppColors.successColor;
        tooltip = 'Connected';
        break;
      case CameraStatus.connecting:
        color = AppColors.warningColor;
        tooltip = 'Connecting...';
        break;
      case CameraStatus.error:
        color = AppColors.errorColor;
        tooltip = 'Error';
        break;
      case CameraStatus.disconnected:
      default:
        color = Colors.grey;
        tooltip = 'Disconnected';
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(CameraService cameraService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ESP32 CAM Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    hintText: '192.168.1.100',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '80',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: cameraService.status == CameraStatus.connecting
                ? null
                : () async {
                    final ip = _ipController.text.trim();
                    final port = int.tryParse(_portController.text) ?? 80;
                    
                    if (ip.isNotEmpty) {
                      if (cameraService.isConnected) {
                        await cameraService.disconnect();
                      }
                      await cameraService.connect(ip, port: port);
                    }
                  },
            icon: Icon(cameraService.isConnected ? Icons.refresh : Icons.connect_without_contact),
            label: Text(cameraService.isConnected ? 'Reconnect' : 'Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(CameraService cameraService) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: StreamBuilder<Uint8List>(
          stream: cameraService.imageStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _currentFrame = snapshot.data;
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder('Invalid image data');
                },
              );
            } else if (cameraService.status == CameraStatus.connecting) {
              return _buildPlaceholder('Connecting to camera...');
            } else if (cameraService.status == CameraStatus.connected) {
              return _buildPlaceholder('Waiting for video stream...');
            } else {
              return _buildPlaceholder('Camera not connected');
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(CameraService cameraService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: cameraService.isConnected
                ? () async {
                    await cameraService.disconnect();
                  }
                : null,
            icon: const Icon(Icons.stop),
            label: const Text('Disconnect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: cameraService.isConnected
                ? () async {
                    final imageData = await cameraService.captureImage();
                    if (imageData != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image captured successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.camera),
            label: const Text('Capture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
