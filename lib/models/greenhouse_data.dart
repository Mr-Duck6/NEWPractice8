enum SensorType { temperature, humidity, light }

class SensorData {
  final String id;
  final String name;
  double value;
  final String unit;
  bool isError;
  String? errorMessage;
  DateTime? lastAlertTime;

  SensorData({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    this.isError = false,
    this.errorMessage,
    this.lastAlertTime,
  });

  SensorData copyWith({
    double? value,
    bool? isError,
    String? errorMessage,
    DateTime? lastAlertTime,
  }) {
    return SensorData(
      id: id,
      name: name,
      value: value ?? this.value,
      unit: unit,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAlertTime: lastAlertTime ?? this.lastAlertTime,
    );
  }
}

class Thresholds {
  final double maxTemperature;
  final double minHumidity;
  final double minLight;

  Thresholds({
    required this.maxTemperature,
    required this.minHumidity,
    required this.minLight,
  });
}

class DailySummary {
  final String reportDate;
  final double avgTemperature;
  final String status;

  DailySummary({
    required this.reportDate,
    required this.avgTemperature,
    required this.status,
  });
}

class GreenhouseInitData {
  final List<SensorData> sensors;
  final Thresholds thresholds;
  final DailySummary summary;

  GreenhouseInitData({
    required this.sensors,
    required this.thresholds,
    required this.summary,
  });
}
