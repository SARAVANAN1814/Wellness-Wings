import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_wings/services/api_service.dart';
import 'dart:convert';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildQuoteCard(String quote, String author) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              quote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "- $author",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.teal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.healing, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Wellness Wings'),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Wellness Wings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 2,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bridging Hearts, Building Support',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Our Mission',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Connecting elderly and physically challenged individuals with compassionate volunteers to create a supportive community where dignity, independence, and well-being flourish.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuoteCard(
                                  "The greatest happiness of life is the conviction that we are loved.",
                                  "Victor Hugo"
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuoteCard(
                                  "The best way to find yourself is to lose yourself in the service of others.",
                                  "Mahatma Gandhi"
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.elderly, color: Colors.white, size: 28),
                                label: const Text(
                                  'Elderly User Portal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade800,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final elderlyDetails = prefs.getString('elderly_details');
                                  if (elderlyDetails != null) {
                                    final data = jsonDecode(elderlyDetails);
                                    
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (c) => const Center(child: CircularProgressIndicator()),
                                    );
                                    
                                    try {
                                      final api = ApiService();
                                      final result = await api.checkElderlyStatus(data['id']);
                                      
                                      if (!context.mounted) return;
                                      Navigator.pop(context); // dismiss loader
                                      
                                      if (result['success']) {
                                        ZegoUIKitPrebuiltCallInvitationService().init(
                                          appID: 494787214,
                                          appSign: 'feea80e8886ee2d1bd26d1ad0bb6c0b41152ec75b2b952d07261600211bf60cd',
                                          userID: 'elderly_${data['id']}',
                                          userName: data['full_name'] ?? 'Elderly User',
                                          plugins: [],
                                        );
                                        Navigator.pushNamed(context, '/elderly_purpose_selection');
                                      } else {
                                        await prefs.remove('elderly_details');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Account no longer exists. Please register again.'), backgroundColor: Colors.red)
                                        );
                                        Navigator.pushNamed(context, '/elderly_login');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // dismiss loader
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Server unreachable. Please try again later.'), backgroundColor: Colors.orange)
                                        );
                                      }
                                    }
                                  } else {
                                    Navigator.pushNamed(context, '/elderly_login');
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
                                label: const Text(
                                  'Volunteer Portal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade900,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final volunteerDetailsStr = prefs.getString('volunteer_details');
                                  if (volunteerDetailsStr != null) {
                                    final data = jsonDecode(volunteerDetailsStr);
                                    
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (c) => const Center(child: CircularProgressIndicator()),
                                    );
                                    
                                    try {
                                      final api = ApiService();
                                      final result = await api.checkVolunteerStatus(data['id'] ?? data['volunteer_id']);
                                      
                                      if (!context.mounted) return;
                                      Navigator.pop(context); // dismiss loader
                                      
                                      if (result['success']) {
                                        final userData = result['user'] ?? result['volunteer'] ?? data;
                                        ZegoUIKitPrebuiltCallInvitationService().init(
                                          appID: 494787214,
                                          appSign: 'feea80e8886ee2d1bd26d1ad0bb6c0b41152ec75b2b952d07261600211bf60cd',
                                          userID: 'volunteer_${userData['id'] ?? userData['volunteer_id']}',
                                          userName: userData['full_name'] ?? 'Volunteer',
                                          plugins: [],
                                        );
                                        Navigator.pushNamed(
                                          context, 
                                          '/volunteer_availability',
                                          arguments: userData,
                                        );
                                      } else {
                                        await prefs.remove('volunteer_details');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Profile no longer exists. Please register again.'), backgroundColor: Colors.red)
                                        );
                                        Navigator.pushNamed(context, '/volunteer_login');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // dismiss loader
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Connection failed. Please check server status.'), backgroundColor: Colors.orange)
                                        );
                                      }
                                    }
                                  } else {
                                    Navigator.pushNamed(context, '/volunteer_login');
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.security, color: Colors.white, size: 28),
                                label: const Text(
                                  'Guardian Portal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade800,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/guardian_login');
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lightbulb, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Select your role to continue',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (!kReleaseMode)
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/admin_login');
                                  },
                                  child: Text(
                                    'Admin Login',
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}