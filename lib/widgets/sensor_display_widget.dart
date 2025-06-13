import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../services/connection_service.dart';
import '../utils/constants.dart';

class SensorDisplayWidget extends StatelessWidget {
  const SensorDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarControlProvider>(
      builder: (context, provider, child) {
        final sensorData = provider.lastSensorData;
        final isConnected = provider.connectionStatus == ConnectionStatus.connected;

        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isConnected ? AppColors.accentColor : Colors.grey,
              width: 2.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sensors,
                    color: isConnected ? AppColors.accentColor : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sensor Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? AppColors.textColor : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (sensorData != null && isConnected) ...[
                _buildSensorRow(
                  'Distance',
                  '${sensorData.distance.toStringAsFixed(1)} cm',
                  Icons.straighten,
                  _getDistanceColor(sensorData.distance),
                ),
                const SizedBox(height: 12),
                _buildSensorRow(
                  'Temperature',
                  '${sensorData.temperature.toStringAsFixed(1)} °C',
                  Icons.thermostat,
                  _getTemperatureColor(sensorData.temperature),
                ),
                const SizedBox(height: 12),
                _buildSensorRow(
                  'Pressure',
                  '${sensorData.pressure.toStringAsFixed(1)} hPa',
                  Icons.speed,
                  AppColors.accentColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${_formatTime(sensorData.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        isConnected ? Icons.hourglass_empty : Icons.bluetooth_disabled,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isConnected ? 'Waiting for sensor data...' : 'Not connected',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getDistanceColor(double distance) {
    if (distance < 10) {
      return Colors.red; // Danger - very close
    } else if (distance < 20) {
      return Colors.orange; // Warning - close
    } else {
      return Colors.green; // Safe distance
    }
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 10) {
      return Colors.blue; // Cold
    } else if (temperature > 35) {
      return Colors.red; // Hot
    } else {
      return Colors.green; // Normal
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}
