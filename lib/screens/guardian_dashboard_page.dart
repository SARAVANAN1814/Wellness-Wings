import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../services/api_service.dart';
import 'guardian_bookings_page.dart';
import 'guardian_notifications_page.dart';
import 'guardian_emergency_page.dart';
import 'guardian_track_volunteer_page.dart';
import 'guardian_profile_page.dart';

class GuardianDashboardPage extends StatefulWidget {
  final Map<String, dynamic> guardianData;

  const GuardianDashboardPage({super.key, required this.guardianData});

  @override
  State<GuardianDashboardPage> createState() => _GuardianDashboardPageState();
}

class _GuardianDashboardPageState extends State<GuardianDashboardPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _linkedElderly = [];
  bool _isLoading = true;
  int _notificationCount = 0;
  Timer? _notifTimer;
  Map<String, dynamic>? _dashboardStats;

  @override
  void initState() {
    super.initState();
    _initZegoCloud();
    _fetchLinkedElderly();
    _fetchNotificationCount();
    _fetchDashboardStats();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchNotificationCount();
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  void _initZegoCloud() {
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 494787214,
      appSign: 'feea80e8886ee2d1bd26d1ad0bb6c0b41152ec75b2b952d07261600211bf60cd',
      userID: 'guardian_${widget.guardianData['id']}',
      userName: widget.guardianData['full_name'] ?? 'Guardian',
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  Future<void> _fetchLinkedElderly() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getLinkedElderly(
      guardianId: widget.guardianData['id'],
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['elderly'] != null) {
          _linkedElderly = List<Map<String, dynamic>>.from(result['elderly']);
        }
      });
    }
  }

  Future<void> _fetchNotificationCount() async {
    final result = await _apiService.getNotificationCount(
      guardianId: widget.guardianData['id'],
    );
    if (mounted) {
      setState(() {
        _notificationCount = result['count'] ?? 0;
      });
    }
  }

  Future<void> _fetchDashboardStats() async {
    final result = await _apiService.getGuardianDashboardStats(
      guardianId: widget.guardianData['id'],
    );
    if (mounted && result['success'] == true) {
      setState(() {
        _dashboardStats = result['stats'];
      });
    }
  }

  Future<void> _showLinkElderlyDialog() async {
    final phoneController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.link, color: Colors.deepPurple.shade700),
            const SizedBox(width: 8),
            const Text('Link Elderly Person'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the phone number of the elderly person you want to care for.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Elderly Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (phoneController.text.isEmpty) return;
              final linkResult = await _apiService.linkElderly(
                guardianId: widget.guardianData['id'],
                elderlyPhone: phoneController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx, linkResult['success'] == true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(linkResult['message'] ?? 'Done'),
                    backgroundColor: linkResult['success'] == true ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
    if (result == true) {
      _fetchLinkedElderly();
      _fetchDashboardStats();
    }
  }

  Future<void> _unlinkElderly(Map<String, dynamic> elderly) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.link_off, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Unlink Elderly'),
          ],
        ),
        content: Text(
          'Are you sure you want to unlink ${elderly['full_name']}? You will no longer be able to monitor their bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.unlinkElderly(
      guardianId: widget.guardianData['id'],
      elderlyId: elderly['id'],
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
      if (result['success'] == true) {
        _fetchLinkedElderly();
        _fetchDashboardStats();
      }
    }
  }

  void _viewBookings(Map<String, dynamic> elderly) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianBookingsPage(
          elderlyData: elderly,
          guardianId: widget.guardianData['id'],
        ),
      ),
    );
  }

  void _bookVolunteer(Map<String, dynamic> elderly) {
    Navigator.pushNamed(context, '/elderly_purpose_selection', arguments: elderly);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianNotificationsPage(
          guardianId: widget.guardianData['id'],
        ),
      ),
    ).then((_) => _fetchNotificationCount());
  }

  void _openEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianEmergencyPage(
          guardianData: widget.guardianData,
          linkedElderly: _linkedElderly,
        ),
      ),
    ).then((_) {
      _fetchLinkedElderly();
      _fetchDashboardStats();
    });
  }

  void _openProfile() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianProfilePage(
          guardianData: widget.guardianData,
        ),
      ),
    );
    if (updatedData != null && updatedData is Map<String, dynamic>) {
      setState(() {
        widget.guardianData.addAll(updatedData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardian = widget.guardianData;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade800,
              Colors.grey.shade100,
              Colors.grey.shade100,
            ],
            stops: const [0.0, 0.25, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _openProfile,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          (guardian['full_name'] ?? 'G')[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${guardian['full_name'] ?? 'Guardian'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Relation: ${guardian['relation'] ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white, size: 26),
                          onPressed: _openNotifications,
                        ),
                        if (_notificationCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _notificationCount > 9 ? '9+' : '$_notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline, color: Colors.white70),
                      onPressed: _openProfile,
                      tooltip: 'My Profile',
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchLinkedElderly();
                      await _fetchNotificationCount();
                      await _fetchDashboardStats();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wellness Summary
                          if (_dashboardStats != null) ...[
                            Text(
                              'Wellness Summary',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatsRow(),
                            const SizedBox(height: 20),
                          ],

                          // Quick Actions
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.emergency,
                                  label: 'SOS',
                                  color: Colors.red,
                                  onTap: _openEmergency,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.person_add,
                                  label: 'Link Elderly',
                                  color: Colors.indigo,
                                  onTap: _showLinkElderlyDialog,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.notifications_active,
                                  label: 'Alerts',
                                  color: Colors.amber.shade800,
                                  onTap: _openNotifications,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.settings,
                                  label: 'Profile',
                                  color: Colors.teal,
                                  onTap: _openProfile,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Linked Elderly
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Linked Elderly',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade900,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showLinkElderlyDialog,
                                icon: Icon(Icons.add_circle_outline, color: Colors.deepPurple.shade700),
                                label: Text('Link New', style: TextStyle(color: Colors.deepPurple.shade700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (_isLoading)
                            _buildShimmerLoading()
                          else if (_linkedElderly.isEmpty)
                            _buildOnboardingState()
                          else
                            ..._linkedElderly.map((elderly) => _buildElderlyCard(elderly)),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _dashboardStats!;
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          Icons.people,
          '${stats['linked_elderly_count'] ?? 0}',
          'Linked',
          Colors.indigo,
        )),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(
          Icons.pending_actions,
          '${stats['active_bookings'] ?? 0}',
          'Active',
          Colors.orange,
        )),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(
          Icons.check_circle_outline,
          '${stats['completed_bookings'] ?? 0}',
          'Completed',
          Colors.green,
        )),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(
          Icons.calendar_month,
          '${stats['bookings_this_month'] ?? 0}',
          'This Month',
          Colors.deepPurple,
        )),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(2, (index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 14, width: 120, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 180, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildOnboardingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.route, size: 56, color: Colors.deepPurple.shade300),
          const SizedBox(height: 16),
          Text(
            'Get Started',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900),
          ),
          const SizedBox(height: 20),
          _buildOnboardingStep(1, 'Link Elderly', 'Add your loved one using their phone number', Icons.person_add, true),
          _buildOnboardingStep(2, 'Book a Volunteer', 'Find nearby help for medical, grocery, or companionship', Icons.search, false),
          _buildOnboardingStep(3, 'Track & Monitor', 'Watch live location and get real-time updates', Icons.location_on, false),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showLinkElderlyDialog,
              icon: const Icon(Icons.add),
              label: const Text('Link Elderly Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingStep(int step, String title, String subtitle, IconData icon, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isCurrent ? Colors.deepPurple.shade700 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCurrent
                  ? const Icon(Icons.arrow_forward, color: Colors.white, size: 18)
                  : Text('$step', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: isCurrent ? Colors.deepPurple.shade900 : Colors.grey.shade600)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElderlyCard(Map<String, dynamic> elderly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade50,
              child: Icon(Icons.elderly, color: Colors.deepPurple.shade700),
            ),
            title: Text(
              elderly['full_name'] ?? 'Unknown',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📞 ${elderly['phone_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
                if (elderly['address'] != null)
                  Text('📍 ${elderly['address']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'unlink') _unlinkElderly(elderly);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'unlink',
                  child: Row(
                    children: [
                      Icon(Icons.link_off, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text('Unlink', style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _cardButton(Icons.list_alt, 'Bookings', Colors.deepPurple.shade700, () => _viewBookings(elderly)),
                _cardDivider(),
                _cardButton(Icons.add_circle, 'Book', Colors.green.shade700, () => _bookVolunteer(elderly)),
                _cardDivider(),
                _cardButton(Icons.video_call, 'Video Call', Colors.blue.shade700, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video call requires an active booking with a volunteer.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _cardDivider() {
    return Container(width: 1, height: 20, color: Colors.grey.shade300);
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
