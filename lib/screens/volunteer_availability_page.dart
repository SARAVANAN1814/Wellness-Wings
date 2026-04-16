import 'dart:convert';
import 'dart:async';
import '../widgets/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:wellness_wings/services/api_service.dart';
import 'volunteer_edit_profile_page.dart';

class ServiceType {
  final String name;
  final IconData icon;
  final bool isMandatory;
  bool isEnabled;

  ServiceType({
    required this.name,
    required this.icon,
    this.isMandatory = false,
    this.isEnabled = false,
  });

  Map<String, dynamic> toJson() => {
    'service_type': name,
    'is_available': isEnabled,
  };
}

class VolunteerAvailabilityPage extends StatefulWidget {
  final Map<String, dynamic> volunteerData;

  const VolunteerAvailabilityPage({
    super.key,
    required this.volunteerData,
  });

  @override
  State<VolunteerAvailabilityPage> createState() => _VolunteerAvailabilityPageState();
}

class _VolunteerAvailabilityPageState extends State<VolunteerAvailabilityPage> {
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isAvailable = true;
  late Map<String, dynamic> _volunteerData;
  Timer? _pollingTimer;
  Timer? _notificationTimer;
  final Set<int> _notifiedBookingIds = {};

  final List<ServiceType> _services = [
    ServiceType(
      name: 'Hospital Visit',
      icon: Icons.local_hospital_rounded,
      isMandatory: true,
      isEnabled: true,
    ),
    ServiceType(
      name: 'Companion Visit',
      icon: Icons.diversity_3_rounded,
      isEnabled: true,
    ),
    ServiceType(
      name: 'Shopping Visit',
      icon: Icons.shopping_bag_rounded,
      isEnabled: true,
    ),
    ServiceType(
      name: 'Religious Visit',
      icon: Icons.church_rounded,
      isEnabled: true,
    ),
    ServiceType(
      name: 'Bank Visit',
      icon: Icons.account_balance_rounded,
      isEnabled: true,
    ),
    ServiceType(
      name: 'Other Visit',
      icon: Icons.volunteer_activism_rounded,
      isEnabled: true,
    ),
  ];

  void _updateMasterToggle() {
    setState(() {
      _isAvailable = _services
          .where((service) => !service.isMandatory)
          .every((service) => service.isEnabled);
    });
  }

  @override
  void initState() {
    super.initState();
    _volunteerData = widget.volunteerData;
    _loadCurrentSettings();
    _startPollingForRequests();

    // Defensive Zego connection to ensure volunteer can ALWAYS receive calls
      WidgetsBinding.instance.addPostFrameCallback((_) {
      final volunteerId = _volunteerData['id'] ?? _volunteerData['volunteer_id'];
      if (volunteerId != null) {
        ZegoUIKitPrebuiltCallInvitationService().init(
          appID: 494787214,
          appSign: 'feea80e8886ee2d1bd26d1ad0bb6c0b41152ec75b2b952d07261600211bf60cd',
          userID: 'volunteer_$volunteerId',
          userName: _volunteerData['full_name'] ?? 'Volunteer',
          plugins: [ZegoUIKitSignalingPlugin()],
        );

        // Load profile picture in background (not included in login response for speed)
        _loadProfilePicture(volunteerId.toString());
      }
    });
  }

  Future<void> _loadProfilePicture(String volunteerId) async {
    try {
      final profilePicture = await _apiService.getVolunteerProfilePicture(volunteerId);
      if (profilePicture != null && mounted) {
        setState(() {
          _volunteerData['profile_picture'] = profilePicture;
        });
        // Also update cached data
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('volunteer_details');
        if (cached != null) {
          final cachedData = jsonDecode(cached) as Map<String, dynamic>;
          cachedData['profile_picture'] = profilePicture;
          await prefs.setString('volunteer_details', jsonEncode(cachedData));
        }
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startPollingForRequests() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final volunteerId = _volunteerData['volunteer_id'] ?? _volunteerData['id'];
        if (volunteerId == null) return;
        
        final result = await _apiService.getVolunteerRequests(volunteerId.toString());
        if (result['success'] && mounted) {
          final requests = List<Map<String, dynamic>>.from(result['requests']);
          if (requests.isNotEmpty) {
            for (var request in requests) {
              final bookingId = request['booking_id'];
              if (!_notifiedBookingIds.contains(bookingId)) {
                _notifiedBookingIds.add(bookingId);
                _showNewRequestPopup(request);
              }
            }
          }
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  void _showNewRequestPopup(Map<String, dynamic> request) {
    if (!mounted) return;

    FlutterRingtonePlayer().playNotification();
    HapticFeedback.vibrate();

    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      FlutterRingtonePlayer().playNotification();
      HapticFeedback.vibrate();
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            SizedBox(width: 8),
            Text('New Request'),
          ],
        ),
        content: Text('You have a new booking request for ${request['service_type']} from ${request['elderly_name']}.'),
        actions: [
          TextButton(
            onPressed: () {
              _notificationTimer?.cancel();
              _apiService.updateBookingStatus(
                bookingId: request['booking_id'].toString(), 
                status: 'rejected'
              );
              Navigator.pop(ctx);
            },
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationTimer?.cancel();
              Navigator.pop(ctx);
              Navigator.pushNamed(
                context,
                '/volunteer_bookings',
                arguments: (_volunteerData['id'] ?? _volunteerData['volunteer_id']).toString(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('View Details', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVolunteerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final volunteerDetailsStr = prefs.getString('volunteer_details');
    if (volunteerDetailsStr != null) {
      if (mounted) {
        setState(() {
          _volunteerData = jsonDecode(volunteerDetailsStr);
        });
      }
    }
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final settings = await _apiService.getVolunteerServices(
        volunteerId: _volunteerData['volunteer_id'] ?? _volunteerData['id'], // use fallback id if volunteer_id is null
      );
      
      if (settings['success']) {
        setState(() {
          final services = settings['services'] as List;
          for (var service in services) {
            final index = _services.indexWhere(
              (s) => s.name == service['service_type']
            );
            if (index != -1) {
              _services[index].isEnabled = service['is_available'];
            }
          }
          _updateMasterToggle();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load current settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAvailabilitySettings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final volunteerId = _volunteerData['id']?.toString() ?? 
                         _volunteerData['volunteer_id']?.toString();
                       
      if (volunteerId == null) {
        throw Exception('Volunteer ID not found');
      }

      print('Volunteer ID: $volunteerId');

      final servicesToSend = _services.map((service) => {
        'service_type': service.name,
        'is_available': service.isEnabled,
      }).toList();

      print('Services to send: $servicesToSend');

      final result = await _apiService.updateVolunteerServices(
        volunteerId: volunteerId,
        services: servicesToSend,
      );

      if (!mounted) return;

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home page and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', 
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: ${e.toString()}'),
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
        title: const Text(
          'Service Availability',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: _volunteerData['profile_picture'] != null
                      ? MemoryImage(base64Decode(_volunteerData['profile_picture']))
                      : null,
                  child: _volunteerData['profile_picture'] == null
                      ? Icon(Icons.person, color: Colors.teal.shade700)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Row(
                children: [
                  Text(
                    _volunteerData['full_name'] ?? 'Volunteer Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (_volunteerData['has_experience'] == true) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                  ],
                ],
              ),
              accountEmail: Text(_volunteerData['email'] ?? 'No email provided'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _volunteerData['profile_picture'] != null
                    ? MemoryImage(base64Decode(_volunteerData['profile_picture']))
                    : null,
                child: _volunteerData['profile_picture'] == null
                    ? Icon(Icons.person, size: 40, color: Colors.teal.shade700)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_rounded, color: Colors.teal),
              title: const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_volunteerData['phone_number']?.toString() ?? 'Not provided'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_rounded, color: Colors.teal),
              title: const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${_volunteerData['place'] ?? 'Unknown'}, ${_volunteerData['state'] ?? 'Unknown'}'),
            ),
            ListTile(
              leading: const Icon(Icons.currency_rupee_rounded, color: Colors.teal),
              title: const Text('Price per Hour', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('₹${_volunteerData['price_per_hour'] ?? '0'}/hr'),
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
                    builder: (context) => VolunteerEditProfilePage(volunteerData: _volunteerData),
                  ),
                );
                if (result == true) {
                  _loadVolunteerDetails(); 
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
                // Rapido/Ola style offline enforcement: Force them fully Offline when they exit.
                try {
                  final volunteerId = _volunteerData['id']?.toString() ?? _volunteerData['volunteer_id']?.toString();
                  if (volunteerId != null) {
                    final servicesToSend = _services.map((service) => {
                      'service_type': service.name,
                      'is_available': false,
                    }).toList();
                    
                    await _apiService.updateVolunteerServices(
                      volunteerId: volunteerId,
                      services: servicesToSend,
                    );
                  }
                } catch(e) {}
                
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('volunteer_details');
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
            colors: [Colors.teal.shade700, Colors.white],
            stops: const [0.0, 0.2],
          ),
        ),
        child: Center(
          child: ResponsiveContainer(
            maxWidth: 800,
            child: Column(
              children: <Widget>[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
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
                          Icons.check_circle_rounded,
                          color: Colors.teal.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Available for all Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: (bool value) {
                          setState(() {
                            _isAvailable = value;
                            for (var service in _services) {
                              if (!service.isMandatory) {
                                service.isEnabled = value;
                              }
                            }
                          });
                        },
                        activeColor: Colors.teal.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _services.length,
                itemBuilder: (BuildContext context, int index) {
                  final service = _services[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: service.isEnabled
                              ? Colors.teal.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          service.icon,
                          color: service.isEnabled
                              ? Colors.teal.shade700
                              : Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        service.name,
                        style: TextStyle(
                          fontWeight: service.isMandatory
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: service.isMandatory
                          ? Text(
                              'Mandatory service',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            )
                          : null,
                      trailing: Switch(
                        value: service.isEnabled,
                        onChanged: service.isMandatory
                            ? null
                            : (bool value) {
                                setState(() {
                                  service.isEnabled = value;
                                  _updateMasterToggle();
                                });
                              },
                        activeColor: Colors.teal.shade700,
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.teal.shade700),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/volunteer_bookings',
                              arguments: widget.volunteerData['id']?.toString() ??
                                  widget.volunteerData['volunteer_id']?.toString(),
                            );
                          },
                          icon: Icon(Icons.calendar_month_rounded,
                              color: Colors.teal.shade700),
                          label: const Text(
                            'My Bookings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _saveAvailabilitySettings,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
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
