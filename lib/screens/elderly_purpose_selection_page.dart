import 'dart:convert';
import '../widgets/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'available_volunteers_page.dart';
import 'elderly_edit_profile_page.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class ElderlyPurposeSelectionPage extends StatefulWidget {
  final Map<String, dynamic>? elderlyData;
  const ElderlyPurposeSelectionPage({super.key, this.elderlyData});

  @override
  State<ElderlyPurposeSelectionPage> createState() => _ElderlyPurposeSelectionPageState();
}

class _ElderlyPurposeSelectionPageState extends State<ElderlyPurposeSelectionPage> {
  final _descriptionController = TextEditingController();
  Map<String, dynamic>? _elderlyDetails;
  
  Map<String, dynamic>? _activeBooking;
  bool _isLoadingActiveBooking = true;
  Timer? _pollingTimer;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.elderlyData != null) {
      _elderlyDetails = widget.elderlyData;
      _startPollingActiveBooking();
    } else {
      _loadElderlyDetails().then((_) {
        _startPollingActiveBooking();
      });
    }
  }

  void _startPollingActiveBooking() {
    _pollActiveBooking();
    _pushLiveLocation(); // Push GPS immediately on start
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pollActiveBooking();
      _pushLiveLocation(); // Push GPS every 10 seconds
    });
  }

  /// Continuously push the elderly user's current GPS to the backend
  /// so the volunteer gets truly live coordinates, not stale login-time ones.
  Future<void> _pushLiveLocation() async {
    if (_elderlyDetails == null || !mounted) return;
    final elderlyId = _elderlyDetails!['id'];
    if (elderlyId == null) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _apiService.updateElderlyLocation(
          id: int.parse(elderlyId.toString()),
          latitude: position.latitude,
          longitude: position.longitude,
        );
        debugPrint('📍 Elderly live location pushed: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('Error pushing elderly live location: $e');
    }
  }

  Future<void> _pollActiveBooking() async {
    if (_elderlyDetails == null || !mounted) return;
    
    final elderlyId = _elderlyDetails!['id']?.toString();
    if (elderlyId == null) return;

    final response = await _apiService.getElderlyActiveBooking(elderlyId);
    if (mounted) {
      if (response['success'] == true && response['hasActiveBooking'] == true) {
        setState(() {
          _activeBooking = response['booking'];
          _isLoadingActiveBooking = false;
        });
      } else {
        setState(() {
          _activeBooking = null;
          _isLoadingActiveBooking = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
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
          ),
        ),
        child: _isLoadingActiveBooking 
          ? const Center(child: CircularProgressIndicator())
          : _activeBooking != null 
              ? _buildActiveBookingDashboard()
              : Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ResponsiveContainer(
              maxWidth: 800,
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
          description: description ?? '',
          elderlyData: _elderlyDetails,
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


  Widget _buildActiveBookingDashboard() {
    final status = _activeBooking!['status'];
    final otp = _activeBooking!['otp'] ?? '0000';
    final volunteerName = _activeBooking!['volunteer_name'] ?? 'Volunteer';
    final volunteerPhone = _activeBooking!['volunteer_phone'] ?? 'N/A';
    
    final volLat = _activeBooking!['volunteer_lat'];
    final volLng = _activeBooking!['volunteer_lng'];

    final eLat = _elderlyDetails!['latitude'];
    final eLng = _elderlyDetails!['longitude'];

    final hasVolLocation = volLat != null && volLng != null;
    final hasELocation = eLat != null && eLng != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ResponsiveContainer(
        maxWidth: 800,
        child: Column(
          children: [
            const Text(
              'Current Active Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            
            // Volunteer Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage: _activeBooking!['volunteer_photo'] != null
                          ? MemoryImage(base64Decode(_activeBooking!['volunteer_photo']))
                          : null,
                      child: _activeBooking!['volunteer_photo'] == null
                          ? Icon(Icons.person, size: 40, color: Colors.teal.shade700)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      volunteerName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Service: ${_activeBooking!['service_type']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // OTP Code Section
            if (status == 'accepted') 
              Card(
                elevation: 4,
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_person_rounded, size: 48, color: Colors.teal),
                      const SizedBox(height: 16),
                      const Text(
                        'Share this OTP with your volunteer upon arrival to start the service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          otp,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
            if (status == 'in_progress')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Text(
                      'Service is currently in progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            
            // Map Tracking Section
            if (hasVolLocation)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        double.parse(volLat.toString()), 
                        double.parse(volLng.toString())
                      ),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wellness_wings',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(double.parse(volLat.toString()), double.parse(volLng.toString())),
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.location_on, size: 50, color: Colors.red),
                          ),
                          if (hasELocation)
                            Marker(
                              point: LatLng(double.parse(eLat.toString()), double.parse(eLng.toString())),
                              width: 60,
                              height: 60,
                              child: const Icon(Icons.home, size: 50, color: Colors.blue),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

