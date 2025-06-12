import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../models/sensor_data.dart';
import '../utils/constants.dart';

class SensorHistoryWidget extends StatefulWidget {
  const SensorHistoryWidget({super.key});

  @override
  State<SensorHistoryWidget> createState() => _SensorHistoryWidgetState();
}

class _SensorHistoryWidgetState extends State<SensorHistoryWidget> {
  final List<SensorData> _sensorHistory = [];
  static const int maxHistorySize = 50; // Keep last 50 readings

  @override
  Widget build(BuildContext context) {
    return Consumer<CarControlProvider>(
      builder: (context, provider, child) {
        // Add new sensor data to history
        if (provider.lastSensorData != null) {
          _addToHistory(provider.lastSensorData!);
        }

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
                  'Sensor Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.secondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (_sensorHistory.isNotEmpty) ...[
                  // Distance trend
                  _buildTrendIndicator(
                    'Distance Trend',
                    _sensorHistory.map((d) => d.distance).toList(),
                    'cm',
                    Icons.straighten,
                    Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Temperature trend
                  _buildTrendIndicator(
                    'Temperature Trend',
                    _sensorHistory.map((d) => d.temperature).toList(),
                    '°C',
                    Icons.thermostat,
                    Colors.orange,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Humidity trend
                  _buildTrendIndicator(
                    'Humidity Trend',
                    _sensorHistory.map((d) => d.humidity).toList(),
                    '%',
                    Icons.water_drop,
                    Colors.teal,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Collecting sensor data...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildTrendIndicator(
    String title,
    List<double> values,
    String unit,
    IconData icon,
    Color color,
  ) {
    if (values.length < 2) {
      return _buildNoTrendWidget(title, icon, color);
    }

    final latest = values.last;
    final previous = values[values.length - 2];
    final trend = latest - previous;
    final isIncreasing = trend > 0;
    final isStable = trend.abs() < 0.1; // Consider stable if change is small

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                isStable
                    ? Icons.horizontal_rule
                    : isIncreasing
                        ? Icons.trending_up
                        : Icons.trending_down,
                color: isStable
                    ? Colors.grey
                    : isIncreasing
                        ? Colors.red
                        : Colors.green,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatText('Min', '$min$unit', Colors.blue),
              _buildStatText('Avg', '${avg.toStringAsFixed(1)}$unit', Colors.orange),
              _buildStatText('Max', '$max$unit', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoTrendWidget(String title, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            'Waiting for data...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatText(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryColor.withAlpha((0.7 * 255).round()),
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _addToHistory(SensorData newData) {
    // Only add if it's different from the last entry (avoid duplicates)
    if (_sensorHistory.isEmpty || 
        _sensorHistory.last.timestamp != newData.timestamp) {
      setState(() {
        _sensorHistory.add(newData);
        
        // Keep only the last maxHistorySize entries
        if (_sensorHistory.length > maxHistorySize) {
          _sensorHistory.removeAt(0);
        }
      });
    }
  }
}
