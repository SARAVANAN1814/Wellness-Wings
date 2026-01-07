import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/elderly_login_page.dart';
import 'screens/elderly_registration_page.dart';
import 'screens/volunteer_login_page.dart';
import 'screens/volunteer_registration_page.dart';
import 'screens/elderly_purpose_selection_page.dart';
import 'screens/volunteer_availability_page.dart';
import 'screens/booking_confirmation_page.dart';
import 'screens/volunteer_bookings_page.dart';

void main() {
  runApp(const WellnessWingsApp());
}

class WellnessWingsApp extends StatelessWidget {
  const WellnessWingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wellness Wings',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/elderly_login': (context) => const ElderlyLoginPage(),
        '/elderly_register': (context) => const ElderlyRegistrationPage(),
        '/elderly_purpose_selection': (context) => const ElderlyPurposeSelectionPage(),
        '/volunteer_login': (context) => const VolunteerLoginPage(),
        '/volunteer_register': (context) => const VolunteerRegistrationPage(),
        '/booking_confirmation': (context) => const BookingConfirmationPage(
              volunteerDetails: {},
              serviceType: '',
              isEmergency: false, bookingDetails: {},
            ),
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
        }
        return null;
      },
    );
  }
}
