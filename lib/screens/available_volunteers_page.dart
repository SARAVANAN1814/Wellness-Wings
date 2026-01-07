import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wellness_wings/screens/booking_confirmation_page.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    try {
      final result = await _apiService.getAvailableVolunteers(
        serviceType: widget.serviceType,
        emergency: widget.isEmergency,
      );

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
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
                              'No volunteers available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        padding: const EdgeInsets.all(16),
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
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.phone_rounded,
                                    volunteer['phone_number'] ?? 'Not available',
                                  ),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(
                                    Icons.location_on_rounded,
                                    volunteer['place'] ?? 'Location not available',
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
                                      volunteer['experience_details'] != null)
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
                                          onPressed: () async {
                                            final phoneNumber = volunteer['phone_number'];
                                            if (phoneNumber != null) {
                                              final url = Uri.parse('tel:$phoneNumber');
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url);
                                              }
                                            }
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