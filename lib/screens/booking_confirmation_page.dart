import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> volunteerDetails;
  final String serviceType;
  final bool isEmergency;
  final Map<String, dynamic> bookingDetails;

  const BookingConfirmationPage({
    super.key,
    required this.volunteerDetails,
    required this.serviceType,
    required this.isEmergency,
    required this.bookingDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Confirmation',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        automaticallyImplyLeading: false,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.teal.shade700,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Booking Request Sent!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Your request has been sent to the volunteer for $serviceType',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailsCard(
                'Volunteer Details',
                Icons.volunteer_activism_rounded,
                [
                  _buildDetailRow(
                    Icons.person_rounded,
                    'Name',
                    volunteerDetails['full_name'] ?? 'Not available',
                  ),
                  _buildDetailRow(
                    Icons.phone_rounded,
                    'Contact',
                    volunteerDetails['phone_number'] ?? 'Not available',
                  ),
                  _buildDetailRow(
                    Icons.location_on_rounded,
                    'Location',
                    volunteerDetails['place'] ?? 'Not available',
                  ),
                  _buildDetailRow(
                    Icons.currency_rupee_rounded,
                    'Price per hour',
                    '₹${volunteerDetails['price_per_hour']}',
                  ),
                  if (volunteerDetails['has_experience'] == true &&
                      volunteerDetails['experience_details'] != null)
                    _buildDetailRow(
                      Icons.work_rounded,
                      'Experience',
                      volunteerDetails['experience_details'],
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailsCard(
                'Booking Details',
                Icons.confirmation_number_rounded,
                [
                  _buildDetailRow(
                    Icons.numbers_rounded,
                    'Booking ID',
                    '#${bookingDetails['id']}',
                  ),
                  _buildDetailRow(
                    Icons.medical_services_rounded,
                    'Service',
                    serviceType,
                  ),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Booking Time',
                    _formatDateTime(bookingDetails['booking_time']),
                  ),
                  _buildDetailRow(
                    Icons.priority_high_rounded,
                    'Emergency',
                    isEmergency ? 'Yes' : 'No',
                    isEmergency ? Colors.red : null,
                  ),
                  _buildDetailRow(
                    Icons.info_rounded,
                    'Status',
                    bookingDetails['status']?.toUpperCase() ?? 'PENDING',
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final phoneNumber = volunteerDetails['phone_number'];
                        if (phoneNumber != null) {
                          final url = Uri.parse('tel:$phoneNumber');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        }
                      },
                      icon: const Icon(Icons.phone_rounded),
                      label: const Text(
                        'Call Volunteer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: Icon(
                  Icons.home_rounded,
                  color: Colors.teal.shade700,
                ),
                label: Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(String title, IconData titleIcon, List<Widget> details) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  titleIcon,
                  color: Colors.teal.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: details.map((detail) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: detail,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.teal.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Not available';
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
} 