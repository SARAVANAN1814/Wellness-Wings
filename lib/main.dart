import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/elderly_login_page.dart';
import 'screens/guardian_login_page.dart';
import 'screens/elderly_registration_page.dart';
import 'screens/volunteer_login_page.dart';
import 'screens/volunteer_registration_page.dart';
import 'screens/elderly_purpose_selection_page.dart';
import 'screens/volunteer_availability_page.dart';
import 'screens/booking_confirmation_page.dart';
import 'screens/volunteer_bookings_page.dart';
import 'screens/admin_login_page.dart';
import 'screens/admin_dashboard_page.dart';
import 'screens/admin_volunteer_details_page.dart';
import 'screens/guardian_dashboard_page.dart';
import 'screens/guardian_bookings_page.dart';
import 'screens/guardian_notifications_page.dart';
import 'screens/guardian_track_volunteer_page.dart';
import 'screens/guardian_emergency_page.dart';
import 'screens/guardian_profile_page.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  
  ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([ZegoUIKitSignalingPlugin()]);
  runApp(const WellnessWingsApp());
}

class WellnessWingsApp extends StatelessWidget {
  const WellnessWingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Wellness Wings',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/guardian_login': (context) => const GuardianLoginPage(),
        '/elderly_login': (context) => const ElderlyLoginPage(),
        '/elderly_register': (context) => const ElderlyRegistrationPage(),
        '/volunteer_login': (context) => const VolunteerLoginPage(),
        '/volunteer_register': (context) => const VolunteerRegistrationPage(),
        '/booking_confirmation': (context) => const BookingConfirmationPage(
              volunteerDetails: {},
              serviceType: '',
              isEmergency: false, bookingDetails: {},
            ),
        '/admin_login': (context) => const AdminLoginPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/volunteer_availability') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VolunteerAvailabilityPage(
              volunteerData: args,
            ),
          );
        } else if (settings.name == '/volunteer_bookings') {
          final args = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => VolunteerBookingsPage(
              volunteerId: args,
            ),
          );
        } else if (settings.name == '/admin_volunteer_details') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AdminVolunteerDetailsPage(
              volunteer: args,
            ),
          );
        } else if (settings.name == '/guardian_dashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => GuardianDashboardPage(
              guardianData: args,
            ),
          );
        } else if (settings.name == '/guardian_bookings') {
          final args = settings.arguments as Map<String, dynamic>;
          final elderlyData = args['elderlyData'] as Map<String, dynamic>;
          final guardianId = args['guardianId'] as int;
          return MaterialPageRoute(
            builder: (context) => GuardianBookingsPage(
              elderlyData: elderlyData,
              guardianId: guardianId,
            ),
          );
        } else if (settings.name == '/guardian_profile') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => GuardianProfilePage(
              guardianData: args,
            ),
          );
        } else if (settings.name == '/elderly_purpose_selection') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ElderlyPurposeSelectionPage(
              elderlyData: args,
            ),
          );
        }
        return null;
      },
    );
  }
}
