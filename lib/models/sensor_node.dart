enum SensorStatus { safe, warning, alert }

class SensorData {
  final double value;
  final SensorStatus status;
  final String unit;

  const SensorData({
    required this.value,
    required this.status,
    required this.unit,
  });
}

class SensorNode {
  final String id;
  final String location;
  final SensorData fire;   // temperature °C
  final SensorData gas;    // ppm
  final SensorData water;  // cm
  final SensorData light;  // lux
  final SensorData hcSr04; // distance cm

  const SensorNode({
    required this.id,
    required this.location,
    required this.fire,
    required this.gas,
    required this.water,
    required this.light,
    required this.hcSr04,
  });

  SensorStatus get overallStatus {
    final statuses = [fire.status, gas.status, water.status, light.status, hcSr04.status];
    if (statuses.contains(SensorStatus.alert)) return SensorStatus.alert;
    if (statuses.contains(SensorStatus.warning)) return SensorStatus.warning;
    return SensorStatus.safe;
  }
}
