import 'package:url_launcher/url_launcher.dart';
import 'package:another_telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:direct_caller_sim_choice/direct_caller_sim_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class SosService {
  final Telephony telephony = Telephony.instance;
  final DirectCaller directCaller = DirectCaller();
  
  List<Map<String, String>> trustedContacts = [];
  
  bool _isSosActive = false;
  
  // Load contacts from storage
  Future<void> loadContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contactsJson = prefs.getString('trusted_contacts');
    
    if (contactsJson != null) {
      List<dynamic> decoded = jsonDecode(contactsJson);
      trustedContacts = decoded.map((e) => Map<String, String>.from(e)).toList();
    }
    
    // If no contacts saved, add default ones
    if (trustedContacts.isEmpty) {
      trustedContacts = [
        {'name': 'Mother', 'phone': ''},
        {'name': 'Father', 'phone': ''},
        {'name': 'Brother', 'phone': ''},
      ];
      await saveContacts();
    }
  }
  
  // Save contacts to storage
  Future<void> saveContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String contactsJson = jsonEncode(trustedContacts);
    await prefs.setString('trusted_contacts', contactsJson);
  }
  
  // Add new contact
  Future<void> addContact(String name, String phone) async {
    trustedContacts.add({'name': name, 'phone': phone});
    await saveContacts();
  }
  
  // Remove contact
  Future<void> removeContact(int index) async {
    trustedContacts.removeAt(index);
    await saveContacts();
  }
  
  // Update contact
  Future<void> updateContact(int index, String name, String phone) async {
    trustedContacts[index] = {'name': name, 'phone': phone};
    await saveContacts();
  }
  
  // Reorder contacts (drag and drop)
  Future<void> reorderContacts(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = trustedContacts.removeAt(oldIndex);
    trustedContacts.insert(newIndex, item);
    await saveContacts();
  }
  
  Future<bool> requestPermissions() async {
    await Permission.phone.request();
    await Permission.sms.request();
    await Permission.location.request();
    
    return await Permission.phone.isGranted &&
           await Permission.sms.isGranted &&
           await Permission.location.isGranted;
  }
  
  Future<String> getCurrentLocationLink() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    } catch (e) {
      return 'Location unavailable';
    }
  }
  
  Future<void> makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      print('No phone number provided');
      return;
    }
    // Try a direct auto-dial first (works on most devices for normal numbers
    // and on some Samsung builds for emergency numbers like 15). If Android
    // blocks the direct call (typical for emergency numbers on stock builds),
    // fall back to opening the dialer with the number pre-filled.
    try {
      await directCaller.makePhoneCall(phoneNumber);
      print('📞 Auto-calling: $phoneNumber');
    } catch (e) {
      print('❌ Auto-call failed for $phoneNumber: $e — falling back to dialer');
      Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    }
  }
  
  Future<void> sendSms(String phoneNumber, String message) async {
    if (phoneNumber.isEmpty) return;
    
    try {
      await telephony.sendSms(
        to: phoneNumber,
        message: message,
      );
      print('✅ SMS sent to $phoneNumber');
    } catch (e) {
      print('❌ SMS failed to $phoneNumber: $e');
    }
  }
  
  /// Starts the SOS flow.
  ///
  /// [sequential]:
  /// - false (default, manual SOS button): pick ONE random trusted contact,
  ///   wait 30s, escalate to Police 15.
  /// - true (auto-triggered: distress detection / route deviation): walk
  ///   through ALL trusted contacts in saved order, 30s each, then escalate
  ///   to Police 15 if none responded.
  Future<void> startSos({bool sequential = false}) async {
    await loadContacts();

    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    _isSosActive = true;

    String locationLink = await getCurrentLocationLink();
    String sosMessage = '🚨 EMERGENCY! I need help. Location: $locationLink';

    final validContacts = trustedContacts
        .where((c) => c['phone'] != null && c['phone']!.isNotEmpty)
        .toList();

    if (validContacts.isEmpty) {
      print('No trusted contacts with phone numbers — escalating directly to 15');
      await _escalateToPolice(sosMessage);
      _isSosActive = false;
      return;
    }

    if (sequential) {
      await _runSequentialCascade(validContacts, sosMessage);
    } else {
      await _runRandomPick(validContacts, sosMessage);
    }
    _isSosActive = false;
  }

  Future<void> _runRandomPick(
    List<Map<String, String>> validContacts,
    String sosMessage,
  ) async {
    final picked = validContacts[Random().nextInt(validContacts.length)];
    print('Trying random trusted contact: ${picked['name']} - ${picked['phone']}');
    await sendSms(picked['phone']!, sosMessage);
    await makeCall(picked['phone']!);

    await Future.delayed(const Duration(seconds: 30));
    if (_isSosActive) {
      await _escalateToPolice(sosMessage);
    }
  }

  Future<void> _runSequentialCascade(
    List<Map<String, String>> validContacts,
    String sosMessage,
  ) async {
    for (final contact in validContacts) {
      if (!_isSosActive) return;
      print('Trying ${contact['name']} - ${contact['phone']}');
      await sendSms(contact['phone']!, sosMessage);
      await makeCall(contact['phone']!);
      await Future.delayed(const Duration(seconds: 30));
    }
    if (_isSosActive) {
      await _escalateToPolice(sosMessage);
    }
  }

  // Escalates to Pakistan Police emergency (15) when all trusted contacts
  // have been tried without response.
  Future<void> _escalateToPolice(String sosMessage) async {
    if (!_isSosActive) return;
    print('⚠️ No contacts responded — escalating to Police 15');
    await sendSms('15', sosMessage);
    await Future.delayed(const Duration(seconds: 2));
    await makeCall('15');
  }

  void stopSos() {
    _isSosActive = false;
  }
}