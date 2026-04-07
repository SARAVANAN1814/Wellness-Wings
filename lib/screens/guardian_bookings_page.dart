import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../services/api_service.dart';
import 'guardian_track_volunteer_page.dart';

class GuardianBookingsPage extends StatefulWidget {
  final Map<String, dynamic> elderlyData;
  final int guardianId;

  const GuardianBookingsPage({
    super.key,
    required this.elderlyData,
    required this.guardianId,
  });

  @override
  State<GuardianBookingsPage> createState() => _GuardianBookingsPageState();
}

class _GuardianBookingsPageState extends State<GuardianBookingsPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  Map<String, dynamic>? _stats;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'All', 'icon': Icons.list, 'color': Colors.deepPurple},
    {'key': 'pending', 'label': 'Pending', 'icon': Icons.schedule, 'color': Colors.orange},
    {'key': 'in_progress', 'label': 'Active', 'icon': Icons.directions_run, 'color': Colors.blue},
    {'key': 'completed', 'label': 'Done', 'icon': Icons.check_circle, 'color': Colors.green},
    {'key': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getElderlyBookingsForGuardian(
      elderlyId: widget.elderlyData['id'],
      guardianId: widget.guardianId,
      status: _selectedFilter,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['bookings'] != null) {
          _bookings = List<Map<String, dynamic>>.from(result['bookings']);
        }
        if (result['stats'] != null) {
          _stats = Map<String, dynamic>.from(result['stats']);
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_searchQuery.isEmpty) return _bookings;
    return _bookings.where((b) {
      final volunteerName = (b['volunteer_name'] ?? '').toString().toLowerCase();
      final serviceType = (b['service_type'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return volunteerName.contains(query) || serviceType.contains(query);
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'in_progress': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _serviceIcon(String serviceType) {
    final lower = serviceType.toLowerCase();
    if (lower.contains('hospital') || lower.contains('medical')) return Icons.local_hospital;
    if (lower.contains('grocery') || lower.contains('shopping')) return Icons.shopping_cart;
    if (lower.contains('companion') || lower.contains('visit')) return Icons.people;
    if (lower.contains('transport')) return Icons.directions_car;
    if (lower.contains('emergency')) return Icons.emergency;
    return Icons.miscellaneous_services;
  }

  void _trackVolunteer(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianTrackVolunteerPage(
          bookingData: booking,
          elderlyData: widget.elderlyData,
        ),
      ),
    );
  }

  void _videoCallVolunteer(Map<String, dynamic> booking) {
    final volunteerId = booking['volunteer_id']?.toString();
    final volunteerName = booking['volunteer_name'] ?? 'Volunteer';
    if (volunteerId != null) {
      ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [ZegoCallUser('volunteer_$volunteerId', volunteerName)],
        isVideoCall: true,
      );
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Cancel Booking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel this ${booking['service_type']} booking?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Why are you cancelling?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.cancelBooking(
      bookingId: booking['booking_id'],
      guardianId: widget.guardianId,
      reason: reasonController.text.isNotEmpty ? reasonController.text : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Done'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (result['success'] == true) _fetchBookings();
    }
  }

  Future<void> _rateVolunteer(Map<String, dynamic> booking) async {
    int selectedRating = (booking['rating'] is int && booking['rating'] > 0) ? booking['rating'] : 0;
    final reviewController = TextEditingController(text: booking['review']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text('Rate Volunteer'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was ${booking['volunteer_name']}?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber.shade700,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRating == 0 ? 'Tap to rate'
                    : selectedRating == 1 ? 'Poor'
                    : selectedRating == 2 ? 'Fair'
                    : selectedRating == 3 ? 'Good'
                    : selectedRating == 4 ? 'Very Good'
                    : 'Excellent',
                style: TextStyle(
                  color: selectedRating == 0 ? Colors.grey : Colors.amber.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Review (optional)',
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: selectedRating == 0 ? null : () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result != true || selectedRating == 0) return;

    final rateResult = await _apiService.rateVolunteer(
      bookingId: booking['booking_id'],
      guardianId: widget.guardianId,
      volunteerId: booking['volunteer_id'],
      rating: selectedRating,
      review: reviewController.text.isNotEmpty ? reviewController.text : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rateResult['message'] ?? 'Done'),
          backgroundColor: rateResult['success'] == true ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (rateResult['success'] == true) _fetchBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.elderlyData['full_name']}\'s Bookings',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats bar
          if (_stats != null)
            Container(
              color: Colors.deepPurple.shade900,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat('${_stats!['active'] ?? 0}', 'Active', Colors.orange.shade300),
                  _buildMiniStat('${_stats!['completed'] ?? 0}', 'Done', Colors.green.shade300),
                  _buildMiniStat('${_stats!['cancelled'] ?? 0}', 'Cancelled', Colors.red.shade300),
                  _buildMiniStat('${_stats!['total'] ?? 0}', 'Total', Colors.white70),
                ],
              ),
            ),

          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by volunteer or service...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filters.length,
              itemBuilder: (ctx, i) {
                final filter = _filters[i];
                final isSelected = _selectedFilter == filter['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label'] as String),
                    avatar: Icon(filter['icon'] as IconData, size: 16, color: isSelected ? Colors.white : (filter['color'] as Color)),
                    selected: isSelected,
                    selectedColor: (filter['color'] as Color),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter['key'] as String);
                      _fetchBookings();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Booking list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchBookings,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildBookingCard(filtered[index]),
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/elderly_purpose_selection', arguments: widget.elderlyData);
        },
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book Volunteer'),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _selectedFilter == 'all' ? 'No bookings yet' : 'No $_selectedFilter bookings',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter == 'all'
                    ? 'Book a volunteer for ${widget.elderlyData['full_name']}.'
                    : 'Try a different filter or create a new booking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);
    final serviceType = booking['service_type']?.toString() ?? 'Service';
    final isActive = status.toLowerCase() == 'pending' || status.toLowerCase() == 'in_progress';
    final isCompleted = status.toLowerCase() == 'completed';
    final existingRating = (booking['rating'] is int) ? booking['rating'] as int : 0;

    String timeStr = '';
    if (booking['booking_time'] != null) {
      try {
        final dt = DateTime.parse(booking['booking_time'].toString());
        timeStr = '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        timeStr = booking['booking_time'].toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_serviceIcon(serviceType), color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serviceType, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                      if (timeStr.isNotEmpty)
                        Text(timeStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            if (booking['volunteer_name'] != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('Volunteer: ${booking['volunteer_name']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  if (existingRating > 0) ...[
                    const Spacer(),
                    ...List.generate(5, (i) => Icon(
                      i < existingRating ? Icons.star : Icons.star_border,
                      size: 14,
                      color: Colors.amber.shade700,
                    )),
                  ],
                ],
              ),
            ],

            if (booking['review'] != null && booking['review'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.format_quote, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking['review'].toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (booking['is_emergency'] == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text('Emergency',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (isActive || isCompleted) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isActive) ...[
                    _buildActionButton(Icons.location_on, 'Track', Colors.blue.shade700, () => _trackVolunteer(booking)),
                    _buildActionButton(Icons.video_call, 'Video Call', Colors.green.shade700, () => _videoCallVolunteer(booking)),
                    _buildActionButton(Icons.cancel_outlined, 'Cancel', Colors.red.shade700, () => _cancelBooking(booking)),
                  ],
                  if (isCompleted)
                    _buildActionButton(
                      existingRating > 0 ? Icons.edit : Icons.star,
                      existingRating > 0 ? 'Edit Rating' : 'Rate',
                      Colors.amber.shade800,
                      () => _rateVolunteer(booking),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
      ),
    );
  }
}
