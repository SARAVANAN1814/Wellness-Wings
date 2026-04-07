import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class GuardianNotificationsPage extends StatefulWidget {
  final int guardianId;

  const GuardianNotificationsPage({super.key, required this.guardianId});

  @override
  State<GuardianNotificationsPage> createState() => _GuardianNotificationsPageState();
}

class _GuardianNotificationsPageState extends State<GuardianNotificationsPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  Timer? _pollTimer;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchNotifications(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final result = await _apiService.getGuardianNotifications(
      guardianId: widget.guardianId,
      type: _selectedFilter,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['notifications'] != null) {
          _notifications = List<Map<String, dynamic>>.from(result['notifications']);
        }
      });
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    await _apiService.markNotificationRead(
      guardianId: widget.guardianId,
      bookingId: notification['booking_id'],
    );
    _fetchNotifications(silent: true);
  }

  Future<void> _markAllAsRead() async {
    final result = await _apiService.markAllNotificationsRead(
      guardianId: widget.guardianId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'All marked as read'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _fetchNotifications(silent: true);
    }
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] != true).length;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'in_progress': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Icons.check_circle;
      case 'pending': return Icons.schedule;
      case 'cancelled': return Icons.cancel;
      case 'in_progress': return Icons.directions_run;
      default: return Icons.notifications;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _dateGroup(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final notifDate = DateTime(dt.year, dt.month, dt.day);

      if (notifDate == today) return 'Today';
      if (notifDate == yesterday) return 'Yesterday';
      if (now.difference(dt).inDays < 7) return 'This Week';
      return 'Earlier';
    } catch (_) {
      return 'Unknown';
    }
  }

  Map<String, List<Map<String, dynamic>>> get _groupedNotifications {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final n in _notifications) {
      final group = _dateGroup(n['booking_time']?.toString());
      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white70, size: 18),
              label: const Text('Read All', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.deepPurple.shade900,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', Icons.notifications),
                const SizedBox(width: 8),
                _buildFilterChip('Emergency', 'emergency', Icons.emergency),
                const SizedBox(width: 8),
                _buildFilterChip('Bookings', 'booking', Icons.calendar_month),
              ],
            ),
          ),

          // Unread count banner
          if (_unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.deepPurple.shade50,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.deepPurple.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Notification list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _calculateItemCount(grouped),
                          itemBuilder: (ctx, index) => _buildListItem(grouped, index),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, IconData icon) {
    final isSelected = _selectedFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = key);
          _fetchNotifications();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.deepPurple.shade900 : Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurple.shade900 : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateItemCount(Map<String, List<Map<String, dynamic>>> grouped) {
    int count = 0;
    for (final entry in grouped.entries) {
      count += 1 + entry.value.length; // header + items
    }
    return count;
  }

  Widget _buildListItem(Map<String, List<Map<String, dynamic>>> grouped, int index) {
    int current = 0;
    for (final entry in grouped.entries) {
      if (index == current) {
        // Section header
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
          child: Text(
            entry.key,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        );
      }
      current++;
      if (index < current + entry.value.length) {
        return _buildCard(entry.value[index - current]);
      }
      current += entry.value.length;
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'Booking updates will appear here'
                  : 'No ${_selectedFilter} notifications',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> n) {
    final status = n['status']?.toString() ?? 'pending';
    final color = _statusColor(status);
    final isRead = n['is_read'] == true;

    return GestureDetector(
      onTap: () => _markAsRead(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(_statusIcon(status), color: color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '${n['service_type'] ?? 'Booking'} — ${status.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'For: ${n['elderly_name'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (n['volunteer_name'] != null)
                Text(
                  'Volunteer: ${n['volunteer_name']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              if (n['is_emergency'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🚨 EMERGENCY',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Text(
            _timeAgo(n['booking_time']?.toString()),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
