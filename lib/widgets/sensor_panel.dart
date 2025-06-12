import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../utils/constants.dart';

class SensorPanel extends StatelessWidget {
  const SensorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarControlProvider>(
      builder: (context, provider, child) {
        final sensorData = provider.lastSensorData;
        
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
                  'Sensor Data',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.secondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (sensorData != null) ...[
                  // Distance from HC-SR04
                  _buildSensorTile(
                    context,
                    icon: Icons.straighten,
                    title: 'Distance',
                    value: '${sensorData.distance.toStringAsFixed(1)} cm',
                    subtitle: 'HC-SR04 Ultrasonic',
                    color: _getDistanceColor(sensorData.distance),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Temperature from BME280
                  _buildSensorTile(
                    context,
                    icon: Icons.thermostat,
                    title: 'Temperature',
                    value: '${sensorData.temperature.toStringAsFixed(1)}°C',
                    subtitle: 'BME280 Sensor',
                    color: _getTemperatureColor(sensorData.temperature),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Humidity from BME280
                  _buildSensorTile(
                    context,
                    icon: Icons.water_drop,
                    title: 'Humidity',
                    value: '${sensorData.humidity.toStringAsFixed(1)}%',
                    subtitle: 'BME280 Sensor',
                    color: _getHumidityColor(sensorData.humidity),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Last update time
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppColors.secondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last update: ${_formatTime(sensorData.timestamp)}',
                          style: const TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sensors_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sensor data available',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect to your GyroCar to see live sensor readings',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
  
  Widget _buildSensorTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.secondaryColor.withAlpha((0.7 * 255).round()),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    Color _getDistanceColor(double distance) {
    if (distance < SensorConstants.dangerDistance) return Colors.red;
    if (distance < SensorConstants.warningDistance) return Colors.orange;
    if (distance < SensorConstants.safeDistance) return Colors.yellow[700]!;
    return Colors.green;
  }
  
  Color _getTemperatureColor(double temperature) {
    if (temperature < SensorConstants.freezingTemp) return Colors.blue;
    if (temperature < SensorConstants.coldTemp) return Colors.lightBlue;
    if (temperature < SensorConstants.normalTemp) return Colors.green;
    if (temperature < SensorConstants.hotTemp) return Colors.orange;
    return Colors.red;
  }
  
  Color _getHumidityColor(double humidity) {
    if (humidity < SensorConstants.lowHumidity) return Colors.brown;
    if (humidity < SensorConstants.normalHumidity) return Colors.green;
    if (humidity < SensorConstants.highHumidity) return Colors.blue;
    return Colors.indigo;
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
