import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'available_volunteers_page.dart';
import 'elderly_edit_profile_page.dart';

class ElderlyPurposeSelectionPage extends StatefulWidget {
  const ElderlyPurposeSelectionPage({super.key});

  @override
  State<ElderlyPurposeSelectionPage> createState() => _ElderlyPurposeSelectionPageState();
}

class _ElderlyPurposeSelectionPageState extends State<ElderlyPurposeSelectionPage> {
  final _descriptionController = TextEditingController();
  Map<String, dynamic>? _elderlyDetails;

  @override
  void initState() {
    super.initState();
    _loadElderlyDetails();
  }

  Future<void> _loadElderlyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final elderlyDetailsStr = prefs.getString('elderly_details');
    if (elderlyDetailsStr != null) {
      if (mounted) {
        setState(() {
          _elderlyDetails = jsonDecode(elderlyDetailsStr);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Purpose', 
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 2,
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal.shade50,
                  child: Icon(Icons.person, color: Colors.teal.shade700),
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: _elderlyDetails == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      _elderlyDetails!['full_name'] ?? 'Elderly User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    accountEmail: const Text('Elderly Account'),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.elderly, size: 40, color: Colors.teal.shade700),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone_rounded, color: Colors.teal),
                    title: const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_elderlyDetails!['phone_number']?.toString() ?? 'Not provided'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home_rounded, color: Colors.teal),
                    title: const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_elderlyDetails!['address'] ?? 'Unknown location'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit_rounded, color: Colors.teal),
                    title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context); // Close drawer
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ElderlyEditProfilePage(elderlyData: _elderlyDetails!),
                        ),
                      );
                      if (result == true) {
                        _loadElderlyDetails(); // refresh details from shared preferences
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.red),
                    title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('elderly_details');
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                  ),
                ],
              ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade100, Colors.white],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Common Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildHospitalCard(),
                  _buildPurposeCard('Bank Visit', Icons.account_balance_rounded),
                  _buildPurposeCard('Religious Visit', Icons.church_rounded),
                  _buildPurposeCard('Companion Visit', Icons.diversity_3_rounded),
                  _buildPurposeCard('Shopping Visit', Icons.shopping_bag_rounded),
                ],
              ),
              const SizedBox(height: 24),
              _buildOtherPurposeSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToVolunteers(String serviceType, {
    bool isEmergency = false,
    String? description,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailableVolunteersPage(
          serviceType: serviceType,
          isEmergency: isEmergency,
          description: description ?? '', // Provide empty string as default
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital, size: 36, color: Colors.teal),
            const SizedBox(height: 12),
            const Text(
              'Hospital Visit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToVolunteers('Hospital Visit', isEmergency: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Emergency'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToVolunteers('Hospital Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Regular'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeCard(String title, IconData icon) {
    return Card(
      elevation: 4,
      shadowColor: Colors.teal.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToVolunteers(title),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: Colors.teal.shade700),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to proceed',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherPurposeSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.teal.shade50],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: Colors.teal.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Other Purpose',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Please describe your requirement in detail',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Enter purpose details...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter purpose details'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  _navigateToVolunteers(
                    'Other Visit',
                    description: _descriptionController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Proceed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
} 

