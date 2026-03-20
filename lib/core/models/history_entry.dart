class HistoryEntry {
  final String nodeId;
  final String nodeLocation;
  final DateTime timestamp;
  final double fire;
  final double gas;
  final double water;
  final double light;
  final double hcSr04;

  const HistoryEntry({
    required this.nodeId,
    required this.nodeLocation,
    required this.timestamp,
    required this.fire,
    required this.gas,
    required this.water,
    required this.light,
    required this.hcSr04,
  });
}
