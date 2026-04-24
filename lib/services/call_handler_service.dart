import 'dart:async';
import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

class CallHandlerService {
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  final Telephony _telephony = Telephony.instance;

  bool _isEmergencyActive = false;

  void startListening(bool isEmergencyActive) {
    _isEmergencyActive = isEmergencyActive;

    _phoneStateSubscription = PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING) {
        String? number = event.number;
        if (number != null && number.isNotEmpty) {
          print("Incoming call from: $number");
          if (_isEmergencyActive) {
            await _handleIncomingEmergencyCall(number);
          }
        }
      }
    });
  }

  void stopListening() {
    _phoneStateSubscription?.cancel();
  }

  Future<void> _handleIncomingEmergencyCall(String number) async {
    // 1. Auto-Reject logic
    // NOTE: Android requires system-level CallScreeningService to cleanly reject calls.
    // In Flutter, without native TelecomManager integration, we can't reliably end a call.
    // But we CAN send an auto-reply SMS indicating we are safe or need help.

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String autoReplyStatus = prefs.getString('auto_reply_status') ?? 'Help Needed';
    
    String message = "Automated Message from Safety Guardian: I cannot take your call right now. Status: $autoReplyStatus.";

    try {
      await _telephony.sendSms(
        to: number,
        message: message,
      );
      print("Auto-reply SMS sent to $number");
    } catch (e) {
      print("Failed to send auto-reply to $number: $e");
    }
  }

  void setEmergencyMode(bool active) {
    _isEmergencyActive = active;
  }
}
