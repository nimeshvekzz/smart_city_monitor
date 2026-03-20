import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_node.dart';
import '../models/alert_model.dart';
import '../models/history_entry.dart';

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

  // Stream for UI notifications (e.g. Snackbars)
  late final StreamController<String> _notificationController;
  Stream<String> get notifications => _notificationController.stream;

  // ---------- INIT ----------
  void _initData() {
    nodes = _buildInitialNodes();
    alerts = _buildInitialAlerts();
    // Correct history initialization with all 5 sensors
    history = _buildInitialHistory();
  }

  List<SensorNode> _buildInitialNodes() => [
    _makeNode('NODE-01', 'City Hall Area', 32.0, 40.0, 75.0, 320.0, 150.0),
    _makeNode('NODE-02', 'Central Market', 68.0, 280.0, 45.0, 210.0, 35.0),
    _makeNode('NODE-03', 'Harbor District', 28.0, 60.0, 92.0, 480.0, 250.0),
    _makeNode('NODE-04', 'Industrial Zone', 45.0, 450.0, 30.0, 150.0, 15.0),
  ];

  SensorNode _makeNode(String id, String loc, double f, double g, double w, double l, double d) =>
      SensorNode(
        id: id, location: loc,
        fire:    SensorData(value: f, status: _fireStatus(f),  unit: '°C'),
        gas:     SensorData(value: g, status: _gasStatus(g),   unit: 'ppm'),
        water:   SensorData(value: w, status: _waterStatus(w), unit: 'cm'),
        light:   SensorData(value: l, status: _lightStatus(l), unit: 'lux'),
        hcSr04:  SensorData(value: d, status: _hcSr04Status(d), unit: 'cm'),
      );

  // ---------- STATUS RULES ----------
  SensorStatus _fireStatus(double v)  => v >= 60 ? SensorStatus.alert  : v >= 45 ? SensorStatus.warning : SensorStatus.safe;
  SensorStatus _gasStatus(double v)   => v >= 400 ? SensorStatus.alert : v >= 200 ? SensorStatus.warning : SensorStatus.safe;
  SensorStatus _waterStatus(double v) => v >= 90 ? SensorStatus.alert  : v >= 70 ? SensorStatus.warning : SensorStatus.safe;
  SensorStatus _lightStatus(double v) => v < 100 ? SensorStatus.alert  : v < 200 ? SensorStatus.warning : SensorStatus.safe;
  SensorStatus _hcSr04Status(double v) => v < 20 ? SensorStatus.alert  : v < 50 ? SensorStatus.warning : SensorStatus.safe;

  // ---------- MOCK ALERTS ----------
  List<AlertModel> _buildInitialAlerts() => [
    AlertModel(id: 'A001', type: AlertType.fire,   nodeId: 'NODE-02', nodeLocation: 'Central Market',  message: 'Temperature exceeded 65°C — fire risk detected.',   timestamp: DateTime.now().subtract(const Duration(minutes: 3)),  isResolved: false),
    AlertModel(id: 'A002', type: AlertType.gas,    nodeId: 'NODE-04', nodeLocation: 'Industrial Zone', message: 'Gas level at 450 ppm — hazardous concentration.',    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),  isResolved: false),
    AlertModel(id: 'A003', type: AlertType.water,  nodeId: 'NODE-03', nodeLocation: 'Harbor District', message: 'Water level at 92 cm — potential overflow.',          timestamp: DateTime.now().subtract(const Duration(minutes: 15)), isResolved: false),
    AlertModel(id: 'A004', type: AlertType.gas,    nodeId: 'NODE-02', nodeLocation: 'Central Market',  message: 'Gas spike detected — 320 ppm.',                      timestamp: DateTime.now().subtract(const Duration(hours: 1)),    isResolved: true),
    AlertModel(id: 'A005', type: AlertType.light,  nodeId: 'NODE-04', nodeLocation: 'Industrial Zone', message: 'Street lights below threshold — 90 lux.',            timestamp: DateTime.now().subtract(const Duration(hours: 2)),    isResolved: true),
    AlertModel(id: 'A006', type: AlertType.fire,   nodeId: 'NODE-01', nodeLocation: 'City Hall Area',  message: 'Brief temperature spike to 48°C — resolved.',        timestamp: DateTime.now().subtract(const Duration(hours: 3)),    isResolved: true),
  ];

  // ---------- MOCK HISTORY (last 20 data points per 5 min for all nodes) ----------
  List<HistoryEntry> _buildInitialHistory() {
    final now = DateTime.now();
    final List<HistoryEntry> h = [];
    for (var node in nodes) {
      for (int i = 0; i < 20; i++) {
        final t = now.subtract(Duration(minutes: (19 - i) * 5));
        h.add(HistoryEntry(
          nodeId: node.id, timestamp: t,
          fire:  28 + _rng.nextDouble() * 10,
          gas:   30 + _rng.nextDouble() * 20,
          water: 60 + _rng.nextDouble() * 20,
          light: 280 + _rng.nextDouble() * 80,
          hcSr04: 100 + _rng.nextDouble() * 100,
        ));
      }
    }
    // Ensure history is sorted newest to oldest as requested
    h.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return h;
  }

  // ---------- AUTO REFRESH ----------
  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  double _jitter(double base, double range) {
    final v = base + (_rng.nextDouble() - 0.5) * range;
    return double.parse(v.toStringAsFixed(1));
  }

  void _refresh() {
    nodes = nodes.map((n) {
      final f = _jitter(n.fire.value,  4.0).clamp(20.0, 90.0);
      final g = _jitter(n.gas.value,  20.0).clamp(10.0, 600.0);
      final w = _jitter(n.water.value, 3.0).clamp(10.0, 100.0);
      final l = _jitter(n.light.value,30.0).clamp(50.0, 600.0);
      final d = _jitter(n.hcSr04.value,10.0).clamp(5.0, 400.0);

      // Check for new critical states and generate alerts
      _checkForNewAlerts(n.id, n.location, f, g, w, l, d);

      return _makeNode(n.id, n.location, f, g, w, l, d);
    }).toList();

    // Append new history for ALL nodes
    final now = DateTime.now();
    for (var node in nodes) {
      // Limit history size per node
      final nodeHistory = history.where((h) => h.nodeId == node.id).toList();
      if (nodeHistory.length >= 40) {
        history.remove(nodeHistory.first);
      }
      
      history.insert(0, HistoryEntry(
        nodeId: node.id, timestamp: now,
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
      // Avoid duplicate active alerts for same node and type within 1 minute
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

  // ---------- SENSOR HELPERS ----------
  
  List<SensorNode> getNodesForSensor(AlertType type) {
    return nodes; // Currently all nodes have all sensors
  }

  int getActiveSensorsCount(AlertType type) {
    // In this mock, all sensors are "active" if they exist
    return nodes.length;
  }

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
