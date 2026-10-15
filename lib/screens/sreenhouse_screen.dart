import 'dart:async';

import 'package:flutter/material.dart';

import '../models/greenhouse_data.dart';
import '../services/greenhouse_api.dart';

class GreenhouseScreen extends StatefulWidget {
  const GreenhouseScreen({super.key});

  @override
  State<GreenhouseScreen> createState() => _GreenhouseScreenState();
}

class _GreenhouseScreenState extends State<GreenhouseScreen> {
  final GreenhouseApi _api = GreenhouseApi(failureRate: 0.15);
  late Future<GreenhouseInitData> _initDataFuture;

  List<SensorData> _sensors = [];
  Thresholds? _thresholds;
  DailySummary? _summary;

  bool _isPaused = false;

  final Map<String, StreamSubscription<double>> _subscriptions = {};
  final Map<String, StreamController<double>> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _initDataFuture = _api.fetchInitialData().timeout(
      const Duration(seconds: 3),
      onTimeout: () =>
          throw TimeoutException('Перевищено час очікування сервера'),
    );
  }

  void _initStreamsAndSubscriptions() {
    for (var sensor in _sensors) {
      if (_controllers.containsKey(sensor.id)) continue;

      final controller = StreamController<double>.broadcast();
      _controllers[sensor.id] = controller;

      final stream = _api.sensorStream(sensor.id, controller: controller);

      _subscriptions[sensor.id] = stream.listen(
        (newValue) {
          if (!mounted || _isPaused) return;
          _updateSensorValue(sensor.id, newValue, false, null);
        },
        onError: (error) {
          if (!mounted || _isPaused) return;
          _updateSensorValue(sensor.id, 0.0, true, error.toString());
        },
      );
    }
  }

  void _updateSensorValue(
    String id,
    double value,
    bool isError,
    String? errorMsg,
  ) {
    setState(() {
      final index = _sensors.indexWhere((s) => s.id == id);
      if (index != -1) {
        final oldSensor = _sensors[index];
        _sensors[index] = oldSensor.copyWith(
          value: isError ? oldSensor.value : value,
          isError: isError,
          errorMessage: errorMsg,
        );

        if (!isError && _thresholds != null) {
          bool exceeded = false;
          if (id == 'temp' && value > _thresholds!.maxTemperature)
            exceeded = true;
          if (id == 'hum' && value < _thresholds!.minHumidity) exceeded = true;
          if (id == 'light' && value < _thresholds!.minLight) exceeded = true;

          if (exceeded) {
            final now = DateTime.now();
            if (oldSensor.lastAlertTime == null ||
                now.difference(oldSensor.lastAlertTime!).inSeconds >= 10) {
              _sensors[index] = _sensors[index].copyWith(lastAlertTime: now);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Увага! Поріг перевищено для датчика: ${oldSensor.name} (${value.toStringAsFixed(1)})',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }
          }
        }
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      // Зупиняємо підписки / закриваємо контролери
      for (var sub in _subscriptions.values) {
        sub.pause();
      }
    } else {
      for (var sub in _subscriptions.values) {
        sub.resume();
      }
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    for (var controller in _controllers.values) {
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моніторинг розумної теплиці'),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Продовжити' : 'Пауза',
          ),
        ],
      ),
      body: FutureBuilder<GreenhouseInitData>(
        future: _initDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Помилка: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadData();
                      });
                    },
                    child: const Text('Повторити'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData && _sensors.isEmpty) {
            _sensors = snapshot.data!.sensors;
            _thresholds = snapshot.data!.thresholds;
            _summary = snapshot.data!.summary;
            // Ініціалізуємо стріми після отримання даних
            _initStreamsAndSubscriptions();
          }

          if (_sensors.isEmpty) {
            return const Center(child: Text('Немає даних датчиків'));
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Підсумок за добу
                if (_summary != null)
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Добовий звіт: ${_summary!.reportDate}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Сер. температура: ${_summary!.avgTemperature}°C',
                          ),
                          Text(
                            'Статус: ${_summary!.status}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Показники датчиків у реальному часі:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sensors.length,
                    itemBuilder: (context, index) {
                      final sensor = _sensors[index];

                      bool isThresholdExceeded = false;
                      if (_thresholds != null) {
                        if (sensor.id == 'temp' &&
                            sensor.value > _thresholds!.maxTemperature)
                          isThresholdExceeded = true;
                        if (sensor.id == 'hum' &&
                            sensor.value < _thresholds!.minHumidity)
                          isThresholdExceeded = true;
                        if (sensor.id == 'light' &&
                            sensor.value < _thresholds!.minLight)
                          isThresholdExceeded = true;
                      }

                      Color cardColor = Colors.white;
                      if (sensor.isError) {
                        cardColor = Colors.red.shade100;
                      } else if (isThresholdExceeded) {
                        cardColor = Colors.orange.shade100;
                      }

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sensor.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (sensor.isError)
                                    Text(
                                      'Помилка: ${sensor.errorMessage}',
                                      style: const TextStyle(color: Colors.red),
                                    )
                                  else
                                    Text(
                                      'Значення: ${sensor.value.toStringAsFixed(1)} ${sensor.unit}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                ],
                              ),
                              Icon(
                                sensor.isError
                                    ? Icons.error_outline
                                    : (isThresholdExceeded
                                          ? Icons.warning_amber
                                          : Icons.check_circle_outline),
                                color: sensor.isError
                                    ? Colors.red
                                    : (isThresholdExceeded
                                          ? Colors.orange
                                          : Colors.green),
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
