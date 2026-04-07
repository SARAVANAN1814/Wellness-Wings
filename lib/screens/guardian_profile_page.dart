import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class GuardianProfilePage extends StatefulWidget {
  final Map<String, dynamic> guardianData;

  const GuardianProfilePage({super.key, required this.guardianData});

  @override
  State<GuardianProfilePage> createState() => _GuardianProfilePageState();
}

class _GuardianProfilePageState extends State<GuardianProfilePage> {
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedRelation;
  bool _isLoading = false;
  bool _isEditing = false;

  // Password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPasswordSection = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final List<String> _relations = [
    'Son', 'Daughter', 'Spouse', 'Sibling', 'Grandchild', 'Friend', 'Neighbor', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guardianData['full_name'] ?? '');
    _emailController = TextEditingController(text: widget.guardianData['email'] ?? '');
    _phoneController = TextEditingController(text: widget.guardianData['phone_number'] ?? '');
    _selectedRelation = widget.guardianData['relation'] ?? 'Other';
    if (!_relations.contains(_selectedRelation)) {
      _selectedRelation = 'Other';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields', Colors.orange);
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address', Colors.orange);
      return;
    }

    // Phone validation
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{7,15}$');
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) {
      _showSnackBar('Please enter a valid phone number', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.updateGuardianProfile(
      id: widget.guardianData['id'],
      fullName: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      relation: _selectedRelation,
    );
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    if (result['success'] == true) {
      _showSnackBar('Profile updated successfully!', Colors.green);
      if (result['user'] != null) {
        widget.guardianData.addAll(Map<String, dynamic>.from(result['user']));
      }
    } else {
      _showSnackBar(result['message'] ?? 'Update failed', Colors.red);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please fill in all password fields', Colors.orange);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('New password must be at least 6 characters', Colors.orange);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('New passwords do not match', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.changeGuardianPassword(
      id: widget.guardianData['id'],
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar('Password changed successfully!', Colors.green);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordSection = false);
    } else {
      _showSnackBar(result['message'] ?? 'Password change failed', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            stops: const [0.0, 0.3, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context, widget.guardianData),
                    ),
                    Expanded(
                      child: Text(
                        'My Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!_isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => setState(() => _isEditing = true),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // Avatar
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  (widget.guardianData['full_name'] ?? 'G')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.guardianData['full_name'] ?? 'Guardian',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Member since ${_formatDate(widget.guardianData['created_at'])}',
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
              ),

              const SizedBox(height: 16),

              // Profile form
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle('Personal Information'),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _buildRelationDropdown(),
                        ]),

                        if (_isEditing) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _nameController.text = widget.guardianData['full_name'] ?? '';
                                      _emailController.text = widget.guardianData['email'] ?? '';
                                      _phoneController.text = widget.guardianData['phone_number'] ?? '';
                                      _selectedRelation = widget.guardianData['relation'] ?? 'Other';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Password section
                        _buildSectionTitle('Security'),
                        const SizedBox(height: 12),
                        _buildCard([
                          InkWell(
                            onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline, color: Colors.deepPurple.shade400),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Change Password',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15),
                                  ),
                                ),
                                Icon(
                                  _showPasswordSection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          if (_showPasswordSection) ...[
                            const Divider(height: 24),
                            _buildPasswordField(
                              controller: _currentPasswordController,
                              label: 'Current Password',
                              obscure: _obscureCurrent,
                              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                            ),
                            const SizedBox(height: 12),
                            _buildPasswordField(
                              controller: _newPasswordController,
                              label: 'New Password',
                              obscure: _obscureNew,
                              onToggle: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                            const SizedBox(height: 12),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm New Password',
                              obscure: _obscureConfirm,
                              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Update Password'),
                            ),
                          ],
                        ]),

                        const SizedBox(height: 24),

                        // Logout
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                          },
                          icon: Icon(Icons.logout, color: Colors.red.shade700),
                          label: Text('Logout', style: TextStyle(color: Colors.red.shade700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade900,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade400),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
        ),
      ),
    );
  }

  Widget _buildRelationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _isEditing ? Colors.grey.shade50 : Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.family_restroom, color: Colors.deepPurple.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRelation,
                isExpanded: true,
                items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: _isEditing ? (v) => setState(() => _selectedRelation = v!) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.deepPurple.shade400),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}
