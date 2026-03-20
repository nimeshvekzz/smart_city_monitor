enum AlertType { fire, gas, water, light, distance, system }
enum AlertSeverity { high, medium, low, info }

class AlertModel {
  final String id;
  final AlertType type;
  final String nodeId;
  final String nodeLocation;
  final String message;
  final DateTime timestamp;
  bool isResolved;

  AlertModel({
    required this.id,
    required this.type,
    required this.nodeId,
    required this.nodeLocation,
    required this.message,
    required this.timestamp,
    this.isResolved = false,
  });

  String get typeLabel {
    switch (type) {
      case AlertType.fire:     return 'Fire';
      case AlertType.gas:      return 'Gas';
      case AlertType.water:    return 'Water';
      case AlertType.light:    return 'Light';
      case AlertType.distance: return 'Distance';
      case AlertType.system:   return 'System';
    }
  }

  AlertSeverity get severity {
    switch (type) {
      case AlertType.fire:     return AlertSeverity.high;
      case AlertType.gas:      return AlertSeverity.medium;
      case AlertType.water:    return AlertSeverity.medium;
      case AlertType.light:    return AlertSeverity.low;
      case AlertType.distance: return AlertSeverity.high;
      case AlertType.system:   return AlertSeverity.info;
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.high:   return 'HIGH';
      case AlertSeverity.medium: return 'MEDIUM';
      case AlertSeverity.low:    return 'LOW';
      case AlertSeverity.info:   return 'INFO';
    }
  }
}
