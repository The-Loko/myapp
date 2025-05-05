import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../providers/car_control_provider.dart';
import '../services/connection_service.dart';
import '../widgets/connection_panel.dart';
import '../widgets/control_panel.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CarControlProvider>(context, listen: false);
    _subs.add(
      gyroscopeEventStream().listen((event) {
        if (provider.connectionStatus == ConnectionStatus.connected) {
          provider.sendGyroData(event.x, event.y, event.z);
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GyroCar'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Control panel for Start/Stop and sensitivity
            const ControlPanel(),
            
            const SizedBox(height: 16),
            
            // Connection panel for WiFi/Bluetooth
            const ConnectionPanel(),
            
            const SizedBox(height: 24),
            
            // Connection status panel
            Consumer<CarControlProvider>(
              builder: (context, provider, child) {
                if (provider.errorMessage.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withAlpha((0.1 * 255).round()), // Replace withOpacity
                      border: Border.all(color: AppColors.errorColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Error: ${provider.errorMessage}',
                      style: const TextStyle(color: AppColors.errorColor),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
