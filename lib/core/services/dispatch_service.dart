import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';

class DispatchService {
  static final DispatchService _instance = DispatchService._internal();
  factory DispatchService() => _instance;
  DispatchService._internal() {
    _dispatchController = StreamController<DispatchLog>.broadcast();
  }

  late final StreamController<DispatchLog> _dispatchController;
  Stream<DispatchLog> get dispatchLogs => _dispatchController.stream;

  final List<DispatchLog> history = [];

  // Simulated Government Agent Contact
  static const String agentName = "Agent Sarah Chen";
  static const String agentPhone = "+1 (800) 999-0119";
  static const String agentEmail = "s.chen@city-emergency.gov";

  Future<void> dispatchEmergencyResources(AlertModel alert) async {
    final type = alert.type == AlertType.fire ? "FIRE" : "WATER LEAKAGE";
    final location = alert.nodeLocation;
    
    debugPrint('🚨 EMERGENCY DISPATCH INITIATED: $type at $location');

    // 1. Send SMS
    await _sendSms(
      to: agentPhone,
      message: 'EMERGENCY: $type detected at $location. Immediate response required. Terminal ID: ${alert.nodeId}',
    );

    // 2. Automated Voice Call
    await _makeVoiceCall(
      to: agentPhone,
      script: 'This is an automated emergency broadcast. A $type has been detected at $location. Please acknowledge.',
    );

    // 3. Official Email
    await _sendEmail(
      to: agentEmail,
      subject: 'CRITICAL ALERT: $type - $location',
      body: 'Officer,\n\nA critical $type event has been logged by the Smart City Monitor.\n'
            'Location: $location\n'
            'Node ID: ${alert.nodeId}\n'
            'Timestamp: ${alert.timestamp}\n\n'
            'Please deploy local units immediately.',
    );

    _logDispatch(alert, "COMPLETED");
  }

  Future<void> _sendSms({required String to, required String message}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    debugPrint('📱 SMS SENT to $to: $message');
  }

  Future<void> _makeVoiceCall({required String to, required String script}) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    debugPrint('📞 CALL PLACED to $to. Playing script: "$script"');
  }

  Future<void> _sendEmail({required String to, required String subject, required String body}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    debugPrint('📧 EMAIL SENT to $to: [$subject]');
  }

  void _logDispatch(AlertModel alert, String status) {
    final log = DispatchLog(
      alertId: alert.id,
      timestamp: DateTime.now(),
      channels: ['SMS', 'VOICE', 'EMAIL'],
      recipient: agentName,
      status: status,
    );
    history.insert(0, log);
    _dispatchController.add(log);
  }
}

class DispatchLog {
  final String alertId;
  final DateTime timestamp;
  final List<String> channels;
  final String recipient;
  final String status;

  DispatchLog({
    required this.alertId,
    required this.timestamp,
    required this.channels,
    required this.recipient,
    required this.status,
  });
}
