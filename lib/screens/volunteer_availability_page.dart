import 'package:flutter/material.dart';
import 'package:wellness_wings/services/api_service.dart';

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
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final settings = await _apiService.getVolunteerServices(
        volunteerId: widget.volunteerData['volunteer_id'],
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
      final volunteerId = widget.volunteerData['id']?.toString() ?? 
                         widget.volunteerData['volunteer_id']?.toString();
                       
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
    );
  }
} 
