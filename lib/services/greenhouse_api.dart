import 'dart:async';
import 'dart:math';

import '../models/greenhouse_data.dart';

class GreenhouseApi {
  GreenhouseApi({this.failureRate = 0.1, Random? random})
    : _random = random ?? Random();

  final double failureRate;
  final Random _random;

  Future<GreenhouseInitData> fetchInitialData() async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final sensors = [
      SensorData(id: 'temp', name: 'Температура', value: 24.5, unit: '°C'),
      SensorData(id: 'hum', name: 'Вологість', value: 65.0, unit: '%'),
      SensorData(id: 'light', name: 'Освітленість', value: 450.0, unit: 'лк'),
    ];

    final thresholds = Thresholds(
      maxTemperature: 30.0,
      minHumidity: 40.0,
      minLight: 200.0,
    );

    final summary = DailySummary(
      reportDate: 'Сьогодні',
      avgTemperature: 23.8,
      status: 'Стабільний режим',
    );

    return GreenhouseInitData(
      sensors: sensors,
      thresholds: thresholds,
      summary: summary,
    );
  }

  Stream<double> sensorStream(
    String sensorId, {
    required StreamController<double> controller,
  }) {
    Timer? timer;
    double currentValue = sensorId == 'temp'
        ? 24.5
        : (sensorId == 'hum' ? 65.0 : 450.0);

    void startTimer() {
      timer = Timer.periodic(const Duration(seconds: 2), (t) {
        if (controller.isClosed) {
          t.cancel();
          return;
        }

        if (_random.nextDouble() < failureRate) {
          controller.addError('Збій датчика $sensorId');
          return;
        }

        if (sensorId == 'temp') {
          currentValue += (_random.nextDouble() * 2 - 0.9); // коливання
        } else if (sensorId == 'hum') {
          currentValue += (_random.nextDouble() * 6 - 3);
        } else {
          currentValue += (_random.nextDouble() * 40 - 20);
        }

        controller.add(currentValue);
      });
    }

    startTimer();

    return controller.stream;
  }
}
