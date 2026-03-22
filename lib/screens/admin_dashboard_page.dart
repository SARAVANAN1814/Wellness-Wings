import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _pendingVolunteers = [];

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getPendingVolunteers();
    if (result['success']) {
      setState(() {
        _pendingVolunteers = result['volunteers'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Fetch failed'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Verification', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchPending),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _pendingVolunteers.isEmpty
            ? const Center(child: Text('No pending volunteers!', style: TextStyle(fontSize: 18, color: Colors.grey)))
            : ListView.builder(
                itemCount: _pendingVolunteers.length,
                itemBuilder: (context, index) {
                  final volunteer = _pendingVolunteers[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade50,
                        child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                      ),
                      title: Text(volunteer['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('ID: ${volunteer['id']} • Applied: ${volunteer['created_at'].toString().substring(0,10)}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context, 
                          '/admin_volunteer_details',
                          arguments: volunteer,
                        );
                        if (result == true) {
                          _fetchPending();
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
