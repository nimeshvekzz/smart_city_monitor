import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:smart_city_monitor/core/models/sensor_node.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';
import 'package:smart_city_monitor/core/models/history_entry.dart';
import 'package:smart_city_monitor/core/utils/mock_data_generator.dart';
import 'package:smart_city_monitor/core/services/dispatch_service.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal() {
    _notificationController = StreamController<String>.broadcast();
    _initData();
    _startAutoRefresh();
  }

  final _rng = Random();
  Timer? _timer;

  List<SensorNode> nodes = [];
  List<AlertModel> alerts = [];
  List<HistoryEntry> history = [];
  DateTime lastUpdated = DateTime.now();

  late final StreamController<String> _notificationController;
  Stream<String> get notifications => _notificationController.stream;

  void _initData() {
    nodes = MockDataGenerator.buildInitialNodes();
    alerts = MockDataGenerator.buildInitialAlerts();
    history = MockDataGenerator.buildInitialHistory(nodes);
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  void _refresh() {
    nodes = nodes.map((n) {
      final f = MockDataGenerator.jitter(n.fire.value,  4.0).clamp(20.0, 90.0);
      final g = MockDataGenerator.jitter(n.gas.value,  20.0).clamp(10.0, 600.0);
      final w = MockDataGenerator.jitter(n.water.value, 3.0).clamp(10.0, 100.0);
      final l = MockDataGenerator.jitter(n.light.value,30.0).clamp(50.0, 600.0);
      final d = MockDataGenerator.jitter(n.hcSr04.value,10.0).clamp(5.0, 400.0);

      _checkForNewAlerts(n.id, n.location, f, g, w, l, d);

      return SensorNode(
        id: n.id, location: n.location,
        fire:    SensorData(value: f, status: MockDataGenerator.fireStatus(f),  unit: '°C'),
        gas:     SensorData(value: g, status: MockDataGenerator.gasStatus(g),   unit: 'ppm'),
        water:   SensorData(value: w, status: MockDataGenerator.waterStatus(w), unit: 'cm'),
        light:   SensorData(value: l, status: MockDataGenerator.lightStatus(l), unit: 'lux'),
        hcSr04:  SensorData(value: d, status: MockDataGenerator.hcSr04Status(d), unit: 'cm'),
      );
    }).toList();

    final now = DateTime.now();
    for (var node in nodes) {
      final nodeHistory = history.where((h) => h.nodeId == node.id).toList();
      if (nodeHistory.length >= 40) {
        history.remove(nodeHistory.first);
      }
      
      history.insert(0, HistoryEntry(
        nodeId: node.id,
        nodeLocation: node.location,
        timestamp: now,
        fire: node.fire.value, gas: node.gas.value,
        water: node.water.value, light: node.light.value,
        hcSr04: node.hcSr04.value,
      ));
    }

    lastUpdated = now;
    notifyListeners();
  }

  void _checkForNewAlerts(String nodeId, String loc, double f, double g, double w, double l, double d) {
    String? message;
    AlertType? type;

    if (f >= 60) { type = AlertType.fire; message = 'CRITICAL: High temperature detected at $loc ($f°C)'; }
    else if (g >= 400) { type = AlertType.gas; message = 'CRITICAL: Hazardous gas level at $loc ($g ppm)'; }
    else if (w >= 90) { type = AlertType.water; message = 'CRITICAL: Water overflow risk at $loc ($w cm)'; }
    else if (l < 100) { type = AlertType.light; message = 'CRITICAL: Light failure at $loc ($l lux)'; }
    else if (d < 20) { type = AlertType.distance; message = 'CRITICAL: Obstacle/Proximity alert at $loc ($d cm)'; }

    if (message != null && type != null) {
      final exists = alerts.any((a) => !a.isResolved && a.nodeId == nodeId && a.type == type);
      if (!exists) {
        final newAlert = AlertModel(
          id: 'A-${_rng.nextInt(9999)}',
          type: type,
          nodeId: nodeId,
          nodeLocation: loc,
          message: message,
          timestamp: DateTime.now(),
          isResolved: false,
        );
        alerts.insert(0, newAlert);
        _notificationController.add(message);

        // Emergency Dispatch Integration
        if (type == AlertType.fire || type == AlertType.water) {
          newAlert.hasBeenDispatched = true;
          DispatchService().dispatchEmergencyResources(newAlert);
        }
      }
    }
  }

  void resolveAlert(String id) {
    final idx = alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      alerts[idx].isResolved = true;
      notifyListeners();
    }
  }

  List<SensorNode> getNodesForSensor(AlertType type) => nodes;

  int getActiveSensorsCount(AlertType type) => nodes.length;

  int getSensorAlertsCount(AlertType type, {bool criticalOnly = false}) {
    return alerts.where((a) => 
      !a.isResolved && 
      a.type == type && 
      (!criticalOnly || a.severity == AlertSeverity.high)
    ).length;
  }

  SensorData getSensorDataForNode(SensorNode node, AlertType type) {
    switch (type) {
      case AlertType.fire:     return node.fire;
      case AlertType.gas:      return node.gas;
      case AlertType.water:    return node.water;
      case AlertType.light:    return node.light;
      case AlertType.distance: return node.hcSr04;
      default: return node.fire;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notificationController.close();
    super.dispose();
  }
}
