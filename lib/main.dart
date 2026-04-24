import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/incident_report_screen.dart';
import 'screens/emergency_sos_screen.dart';
import 'screens/companion_mode_screen.dart';
import 'screens/distress_detection_screen.dart';
import 'screens/evidence_capture_screen.dart';
import 'screens/report_prioritization_screen.dart';
import 'screens/legal_resource_hub_screen.dart';
import 'screens/citizen_home_screen.dart';
import 'screens/police_dashboard_screen.dart';
import 'screens/verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.init();
  runApp(const SafetyGuardianApp());
}

class SafetyGuardianApp extends StatelessWidget {
  const SafetyGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafetyGuardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            elevation: 5,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                final user = snapshot.data!;
                final isPolice = user.email?.contains('@police.gov.pk') == true;

                // Citizens must verify their email; police are exempt (trusted domain).
                if (!isPolice && !user.emailVerified) {
                  return const VerifyEmailScreen();
                }

                // Fire-and-forget save of FCM token on each auth rebuild.
                NotificationService.saveToken();

                if (isPolice) {
                  return const PoliceDashboardScreen();
                } else {
                  return const CitizenHomeScreen();
                }
              }
              return const LoginScreen();
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
        '/signup': (context) => const SignUpScreen(),
        '/report': (context) => const IncidentReportScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/companion': (context) => const CompanionModeScreen(),
        '/distress': (context) => const DistressDetectionScreen(),
        '/sos': (context) => const EmergencySOSScreen(),
        '/evidence': (context) => const EvidenceCaptureScreen(),
        '/prioritization': (context) => const ReportPrioritizationScreen(),
        '/legal': (context) => const LegalResourceHubScreen(),
      },
    );
  }
}