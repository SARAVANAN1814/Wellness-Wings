import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class GuardianTrackVolunteerPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic>? elderlyData;

  const GuardianTrackVolunteerPage({
    super.key,
    required this.bookingData,
    this.elderlyData,
  });

  @override
  State<GuardianTrackVolunteerPage> createState() =>
      _GuardianTrackVolunteerPageState();
}

class _GuardianTrackVolunteerPageState
    extends State<GuardianTrackVolunteerPage> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  LatLng? _volunteerLocation;
  LatLng? _elderlyLocation;
  String _volunteerName = 'Volunteer';
  bool _isLoading = true;
  String _lastUpdated = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initLocations();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchVolunteerLocation();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initLocations() {
    // Parse elderly location
    if (widget.elderlyData != null) {
      final eLat = _parseDouble(widget.elderlyData!['latitude']);
      final eLng = _parseDouble(widget.elderlyData!['longitude']);
      if (eLat != null && eLng != null) {
        _elderlyLocation = LatLng(eLat, eLng);
      }
    }

    // Parse volunteer ID from booking and fetch location
    _fetchVolunteerLocation();
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _fetchVolunteerLocation() async {
    final volunteerId = widget.bookingData['volunteer_id'] ??
        widget.bookingData['volunteerDetails']?['id'];
    if (volunteerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await _apiService.getVolunteerLiveLocation(
      volunteerId: int.parse(volunteerId.toString()),
    );

    if (mounted && result['success'] == true) {
      final user = result['user'] ?? result['volunteer'];
      if (user != null) {
        final lat = _parseDouble(user['latitude']);
        final lng = _parseDouble(user['longitude']);
        setState(() {
          _volunteerName = user['full_name'] ?? 'Volunteer';
          _isLoading = false;
          _lastUpdated =
              'Updated ${TimeOfDay.now().format(context)}';
          if (lat != null && lng != null) {
            _volunteerLocation = LatLng(lat, lng);
          }
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultCenter = _volunteerLocation ??
        _elderlyLocation ??
        const LatLng(11.0168, 76.9558); // default Coimbatore

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track $_volunteerName',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVolunteerLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple.shade700),
                  const SizedBox(height: 16),
                  Text(
                    'Fetching volunteer location...',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: defaultCenter,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wellnesswings.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Volunteer marker
                        if (_volunteerLocation != null)
                          Marker(
                            point: _volunteerLocation!,
                            width: 50,
                            height: 50,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.volunteer_activism,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Elderly marker
                        if (_elderlyLocation != null)
                          Marker(
                            point: _elderlyLocation!,
                            width: 50,
                            height: 50,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.elderly,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Info overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(Icons.volunteer_activism,
                                  color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _volunteerName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    widget.bookingData['service_type'] ??
                                        'Service',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle,
                                          size: 8, color: Colors.green.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lastUpdated,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildLegend(Colors.blue.shade700,
                                Icons.volunteer_activism, 'Volunteer'),
                            const SizedBox(width: 20),
                            _buildLegend(
                                Colors.red.shade700, Icons.elderly, 'Elderly'),
                          ],
                        ),
                        if (_volunteerLocation == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Volunteer location not available yet',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegend(Color color, IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
