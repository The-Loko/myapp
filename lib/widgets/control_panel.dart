import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../utils/constants.dart';
import '../services/connection_service.dart';
import '../widgets/joystick_widget.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

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
          children: [            Text(
              'Car Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Start/Stop Button
            Center(
              child: GestureDetector(
                onTap: isConnected ? provider.toggleControl : null,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected 
                        ? provider.isControlActive 
                            ? Colors.red 
                            : AppColors.accentColor
                        : Colors.grey,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      provider.isControlActive ? Icons.stop : Icons.play_arrow,
                      size: 48,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Joystick Controls (only show when active)
            if (provider.isControlActive) ...[
              Text(
                'Joystick Control',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Center(
                child: JoystickWidget(
                  onChanged: (x, y) {
                    provider.updateJoystickPosition(x, y);
                  },
                  size: 200.0,
                  enabled: isConnected && provider.isControlActive,
                ),
              ),
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.secondaryColor, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Joystick Controls:',
                          style: TextStyle(
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Up/Down: Forward/Backward\n• Left/Right: Turning\n• Center: Stop',
                      style: TextStyle(
                        color: AppColors.secondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Sensitivity Slider
            Text(
              'Control Sensitivity',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.speed_outlined, color: AppColors.secondaryColor),
                Expanded(
                  child: Slider(
                    value: provider.sensitivity,
                    min: 0.1,
                    max: 3.0,
                    divisions: 29,
                    label: provider.sensitivity.toStringAsFixed(1),
                    onChanged: isConnected ? (value) => provider.setSensitivity(value) : null,
                  ),
                ),
                const Icon(Icons.speed, color: AppColors.secondaryColor),
              ],
            ),
            const SizedBox(height: 16),
              // Current values display
            if (provider.lastControlData != null && provider.isControlActive) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Control Values:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'X: ${(provider.lastControlData!.x * provider.sensitivity).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.secondaryColor),
                    ),                    Text(
                      'Y: ${(provider.lastControlData!.y * provider.sensitivity).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.secondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
