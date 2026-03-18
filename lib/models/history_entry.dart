class HistoryEntry {
  final String nodeId;
  final DateTime timestamp;
  final double fire;
  final double gas;
  final double water;
  final double light;

  const HistoryEntry({
    required this.nodeId,
    required this.timestamp,
    required this.fire,
    required this.gas,
    required this.water,
    required this.light,
  });
}
