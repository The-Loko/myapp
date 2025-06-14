import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../services/connection_service.dart';
import '../utils/constants.dart';
import '../models/bluetooth_device.dart';

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({super.key});

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  // no Wi-Fi controllers or selection needed

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CarControlProvider>(context);
    final isConnected = provider.connectionStatus == ConnectionStatus.connected;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: AppColors.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connection Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(height: 16),
              // Bluetooth device selection (simplified)
            if (!isConnected) ...[              ElevatedButton(
                onPressed: () async {
                  // Store context before async operation
                  final currentContext = context;
                  
                  // Show dialog with device list
                  final devices = await provider.scanBluetoothDevices();
                  
                  // Guard context use after async operation
                  if (!mounted) return; 
                  
                  // Call the dialog function
                  _showDeviceSelectionDialog(currentContext, devices);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                ),
                child: const Text('Scan for Bluetooth Devices'),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Connection status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.connectionStatus == ConnectionStatus.connected
                        ? Icons.check_circle
                        : provider.connectionStatus == ConnectionStatus.connecting
                            ? Icons.pending
                            : provider.connectionStatus == ConnectionStatus.error
                                ? Icons.error
                                : Icons.cancel,
                    color: provider.connectionStatus == ConnectionStatus.connected
                        ? Colors.green
                        : provider.connectionStatus == ConnectionStatus.connecting
                            ? Colors.orange
                            : provider.connectionStatus == ConnectionStatus.error
                                ? AppColors.errorColor
                                : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.connectionStatus == ConnectionStatus.connected
                          ? 'Connected'
                          : provider.connectionStatus == ConnectionStatus.connecting
                              ? 'Connecting...'
                              : provider.connectionStatus == ConnectionStatus.error
                                  ? 'Connection Error'
                                  : 'Disconnected',
                      style: const TextStyle(color: AppColors.secondaryColor),
                    ),
                  ),
                ],
              ),
            ),            
            const SizedBox(height: 16),
            
            // Scan & Connect / Disconnect Button
            ElevatedButton(
              onPressed: () async {
                if (provider.connectionStatus == ConnectionStatus.connected) {
                  provider.disconnect();
                } else {
                  // Store context before async operation
                  final currentContext = context;
                  
                  final devices = await provider.scanBluetoothDevices();
                  if (!mounted) return;
                  _showDeviceSelectionDialog(currentContext, devices);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.red : AppColors.accentColor,
              ),
              child: Text(isConnected ? 'Disconnect' : 'Scan & Connect'),
            ),
          ],
        ),
      ),
    );
  }
  // Helper method to show device selection dialog
  void _showDeviceSelectionDialog(BuildContext context, List<BluetoothDevice> devices) {
    // Store provider reference before async operation
    final provider = Provider.of<CarControlProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Bluetooth Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.name),
                subtitle: Text(device.address),
                onTap: () {
                  Navigator.of(context).pop(device);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),        ],
      ),    ).then((selectedDevice) {
      // Guard context use after async gap (dialog closing)
      if (!mounted) return; 
      if (selectedDevice != null) {
        // Use stored provider reference
        provider.connectBluetooth(selectedDevice.address);
      }
    });
  }
}
