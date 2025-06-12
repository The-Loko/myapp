class SensorData {
  final double distance; // in cm from HC-SR04
  final double temperature; // in °C from BME280
  final double humidity; // in % from BME280
  final DateTime timestamp;

  SensorData({
    required this.distance,
    required this.temperature,
    required this.humidity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      distance: (json['distance'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SensorData(distance: ${distance}cm, temp: ${temperature}°C, humidity: ${humidity}%)';
  }
}
