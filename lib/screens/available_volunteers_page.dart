import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:wellness_wings/screens/booking_confirmation_page.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AvailableVolunteersPage extends StatefulWidget {
  final String serviceType;
  final bool isEmergency;
  final String description;

  const AvailableVolunteersPage({
    super.key,
    required this.serviceType,
    required this.isEmergency,
    required this.description,
  });

  @override
  State<AvailableVolunteersPage> createState() => _AvailableVolunteersPageState();
}

class _AvailableVolunteersPageState extends State<AvailableVolunteersPage> {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _volunteers = [];
  String? _error;
  Map<String, dynamic>? _elderlyDetails;

  @override
  void initState() {
    super.initState();
    _loadElderlyDetails();
    _loadVolunteers();
  }

  Future<void> _loadElderlyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final elderlyDetailsStr = prefs.getString('elderly_details');
    if (elderlyDetailsStr != null) {
      setState(() {
        _elderlyDetails = jsonDecode(elderlyDetailsStr);
      });
    }
  }

  Future<void> _loadVolunteers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        if (!mounted) return;
        
        bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange),
                SizedBox(width: 10),
                Text('Location Disabled'),
              ],
            ),
            content: const Text('Your location services (GPS) are turned off. Please enable them to find volunteers nearby.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
        
        setState(() {
          _isLoading = false;
          _error = 'Please enable location services and try again.';
        });
        return;
      }
      
      // Get current location
      print('Fetching current location for matching...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('Initial matching permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('Requesting matching permission...');
        permission = await Geolocator.requestPermission();
        print('Matching permission after request: $permission');
      }

      double? lat;
      double? lng;

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        lat = position.latitude;
        lng = position.longitude;
        print('Matching coordinates: $lat, $lng');
      } else {
        print('Matching location permission not granted: $permission');
      }

      final result = await _apiService.getAvailableVolunteers(
        serviceType: widget.serviceType,
        emergency: widget.isEmergency,
        latitude: lat,
        longitude: lng,
      );
      print('Get available volunteers result: ${result['success']}');

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _volunteers = List<Map<String, dynamic>>.from(result['volunteers']);
        } else {
          _error = result['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load volunteers: ${e.toString()}';
      });
    }
  }

  String _generateWhatsAppMessage(String serviceType, String description, bool isEmergency) {
    if (_elderlyDetails == null) return '';
    
    return '''Greetings,

I am ${_elderlyDetails!['full_name']}, an elderly individual seeking assistance.

My Details:
Name: ${_elderlyDetails!['full_name']}
Contact: ${_elderlyDetails!['phone_number']}
Address: ${_elderlyDetails!['address']}

Service Required: $serviceType
${description.isNotEmpty ? 'Purpose: $description\n' : ''}
${isEmergency ? 'This is an EMERGENCY request.\n' : ''}

I would like to book your services for the above-mentioned purpose. Contact me as soon as possible and Please confirm your availability.

Thank you.''';
  }

  Future<void> _sendWhatsAppMessage(Map<String, dynamic> volunteer) async {
    try {
      if (_elderlyDetails == null) {
        throw Exception('Elderly details not found');
      }

      setState(() {
        _isLoading = true;
      });

      // Create booking record first
      final bookingResult = await _apiService.createBooking(
        volunteerId: volunteer['id'].toString(),
        elderlyDetails: _elderlyDetails!,
        serviceType: widget.serviceType,
        description: widget.description,
        isEmergency: widget.isEmergency,
      );

      if (!bookingResult['success']) {
        throw Exception(bookingResult['message']);
      }

      // Generate and send WhatsApp message
      final message = _generateWhatsAppMessage(
        widget.serviceType,
        widget.description,
        widget.isEmergency,
      );

      final phoneNumber = volunteer['phone_number'].toString().replaceAll(RegExp(r'[^\d+]'), '');
      final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to booking confirmation page instead of popping
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationPage(
              volunteerDetails: volunteer,
              serviceType: widget.serviceType,
              isEmergency: widget.isEmergency,
              bookingDetails: bookingResult['booking'],
            ),
          ),
        );
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Available ${widget.serviceType} Volunteers',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.white],
            stops: const [0.0, 0.2],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.teal.shade700.withOpacity(0.5),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          color: Colors.teal.shade700,
                          size: 40,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Hang tight, we are fetching volunteers in nearby locations for you...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadVolunteers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _volunteers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sorry no volunteers found in the nearby',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try checking again later or adjusting your search.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Text(
                              'Here are the list of volunteers, nearby',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.60,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _volunteers.length,
                              itemBuilder: (context, index) {
                                final volunteer = _volunteers[index];
                                return Card(
                                  elevation: 8,
                                  shadowColor: Colors.black26,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.teal.shade100,
                                      width: 1,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.white, Colors.teal.shade50],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.teal.shade100,
                                                  width: 2,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 35,
                                                backgroundColor: Colors.teal.shade50,
                                                child: volunteer['profile_picture'] != null
                                                    ? ClipOval(
                                                        child: Image.memory(
                                                          base64Decode(volunteer['profile_picture']),
                                                          width: 70,
                                                          height: 70,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.person_rounded,
                                                        size: 35,
                                                        color: Colors.teal.shade700,
                                                      ),
                                              ),
                                            ),
                                            if (volunteer['has_experience'] == true)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.shade50,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.verified_rounded,
                                                    color: Colors.teal.shade700,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          volunteer['full_name'] ?? 'Name not available',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        if (volunteer['latitude'] != null && volunteer['longitude'] != null)
                                          Container(
                                            height: 90,
                                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.teal.shade200, width: 2),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: FlutterMap(
                                                options: MapOptions(
                                                  initialCenter: LatLng(
                                                    volunteer['latitude'] is String ? double.parse(volunteer['latitude']) : volunteer['latitude'].toDouble(),
                                                    volunteer['longitude'] is String ? double.parse(volunteer['longitude']) : volunteer['longitude'].toDouble(),
                                                  ),
                                                  initialZoom: 14.0,
                                                  interactionOptions: const InteractionOptions(
                                                    flags: InteractiveFlag.none, // Make it a static preview map
                                                  ),
                                                ),
                                                children: [
                                                  TileLayer(
                                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                    userAgentPackageName: 'com.wellnesswings.app',
                                                  ),
                                                  MarkerLayer(
                                                    markers: [
                                                      Marker(
                                                        point: LatLng(
                                                          volunteer['latitude'] is String ? double.parse(volunteer['latitude']) : volunteer['latitude'].toDouble(),
                                                          volunteer['longitude'] is String ? double.parse(volunteer['longitude']) : volunteer['longitude'].toDouble(),
                                                        ),
                                                        width: 40,
                                                        height: 40,
                                                        child: const Icon(
                                                          Icons.location_on,
                                                          color: Colors.red,
                                                          size: 30,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('Location not available', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '₹${volunteer['price_per_hour']}/hr',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                        ),
                                        if (volunteer['has_experience'] == true &&
                                            volunteer['experience_details'] != null &&
                                            volunteer['experience_details'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              volunteer['experience_details'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildActionButton(
                                                icon: Icons.phone_rounded,
                                                label: 'Call',
                                                color: Colors.green.shade600,
                                                onPressed: () {
                                                  // Secure Anonymous Voice Call via ZegoCloud 
                                                  ZegoUIKitPrebuiltCallInvitationService().send(
                                                    invitees: [
                                                      ZegoCallUser(
                                                        'volunteer_${volunteer['id']}',
                                                        volunteer['full_name'] ?? 'Volunteer',
                                                      ),
                                                    ],
                                                    isVideoCall: false,
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildActionButton(
                                                icon: Icons.message_rounded,
                                                label: 'Book',
                                                color: Colors.teal.shade700,
                                                onPressed: () => _sendWhatsAppMessage(volunteer),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.teal.shade700,
          size: 14,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }
} 