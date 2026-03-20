import 'dart:math';
import 'package:smart_city_monitor/core/models/sensor_node.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';
import 'package:smart_city_monitor/core/models/history_entry.dart';

class MockDataGenerator {
  static final _rng = Random();

  static List<SensorNode> buildInitialNodes() => [
    _makeNode('NODE-01', 'City Hall Area', 32.0, 40.0, 75.0, 320.0, 150.0),
    _makeNode('NODE-02', 'Central Market', 68.0, 280.0, 45.0, 210.0, 35.0),
    _makeNode('NODE-03', 'Harbor District', 28.0, 60.0, 92.0, 480.0, 250.0),
    _makeNode('NODE-04', 'Industrial Zone', 45.0, 450.0, 30.0, 150.0, 15.0),
  ];

  static SensorNode _makeNode(String id, String loc, double f, double g, double w, double l, double d) =>
      SensorNode(
        id: id, location: loc,
        fire:    SensorData(value: f, status: fireStatus(f),  unit: '°C'),
        gas:     SensorData(value: g, status: gasStatus(g),   unit: 'ppm'),
        water:   SensorData(value: w, status: waterStatus(w), unit: 'cm'),
        light:   SensorData(value: l, status: lightStatus(l), unit: 'lux'),
        hcSr04:  SensorData(value: d, status: hcSr04Status(d), unit: 'cm'),
      );

  static SensorStatus fireStatus(double v)  => v >= 60 ? SensorStatus.alert  : v >= 45 ? SensorStatus.warning : SensorStatus.safe;
  static SensorStatus gasStatus(double v)   => v >= 400 ? SensorStatus.alert : v >= 200 ? SensorStatus.warning : SensorStatus.safe;
  static SensorStatus waterStatus(double v) => v >= 90 ? SensorStatus.alert  : v >= 70 ? SensorStatus.warning : SensorStatus.safe;
  static SensorStatus lightStatus(double v) => v < 100 ? SensorStatus.alert  : v < 200 ? SensorStatus.warning : SensorStatus.safe;
  static SensorStatus hcSr04Status(double v) => v < 20 ? SensorStatus.alert  : v < 50 ? SensorStatus.warning : SensorStatus.safe;

  static List<AlertModel> buildInitialAlerts() => [
    AlertModel(id: 'A001', type: AlertType.fire,   nodeId: 'NODE-02', nodeLocation: 'Central Market',  message: 'Temperature exceeded 65°C — fire risk detected.',   timestamp: DateTime.now().subtract(const Duration(minutes: 3)),  isResolved: false, hasBeenDispatched: false),
    AlertModel(id: 'A002', type: AlertType.gas,    nodeId: 'NODE-04', nodeLocation: 'Industrial Zone', message: 'Gas level at 450 ppm — hazardous concentration.',    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),  isResolved: false, hasBeenDispatched: false),
    AlertModel(id: 'A003', type: AlertType.water,  nodeId: 'NODE-03', nodeLocation: 'Harbor District', message: 'Water level at 92 cm — potential overflow.',          timestamp: DateTime.now().subtract(const Duration(minutes: 15)), isResolved: false, hasBeenDispatched: false),
    AlertModel(id: 'A004', type: AlertType.gas,    nodeId: 'NODE-02', nodeLocation: 'Central Market',  message: 'Gas spike detected — 320 ppm.',                      timestamp: DateTime.now().subtract(const Duration(hours: 1)),    isResolved: true, hasBeenDispatched: false),
    AlertModel(id: 'A005', type: AlertType.light,  nodeId: 'NODE-04', nodeLocation: 'Industrial Zone', message: 'Street lights below threshold — 90 lux.',            timestamp: DateTime.now().subtract(const Duration(hours: 2)),    isResolved: true, hasBeenDispatched: false),
    AlertModel(id: 'A006', type: AlertType.fire,   nodeId: 'NODE-01', nodeLocation: 'City Hall Area',  message: 'Brief temperature spike to 48°C — resolved.',        timestamp: DateTime.now().subtract(const Duration(hours: 3)),    isResolved: true, hasBeenDispatched: false),
  ];

  static List<HistoryEntry> buildInitialHistory(List<SensorNode> nodes) {
    final now = DateTime.now();
    final List<HistoryEntry> h = [];
    for (var node in nodes) {
      for (int i = 0; i < 20; i++) {
        final t = now.subtract(Duration(minutes: (19 - i) * 5));
        h.add(HistoryEntry(
          nodeId: node.id,
          nodeLocation: node.location,
          timestamp: t,
          fire:  28 + _rng.nextDouble() * 10,
          gas:   30 + _rng.nextDouble() * 20,
          water: 60 + _rng.nextDouble() * 20,
          light: 280 + _rng.nextDouble() * 80,
          hcSr04: 100 + _rng.nextDouble() * 100,
        ));
      }
    }
    h.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return h;
  }

  static double jitter(double base, double range) {
    final v = base + (_rng.nextDouble() - 0.5) * range;
    return double.parse(v.toStringAsFixed(1));
  }
}
