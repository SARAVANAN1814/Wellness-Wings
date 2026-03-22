import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class VolunteerEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> volunteerData;

  const VolunteerEditProfilePage({super.key, required this.volunteerData});

  @override
  _VolunteerEditProfilePageState createState() => _VolunteerEditProfilePageState();
}

class _VolunteerEditProfilePageState extends State<VolunteerEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _placeController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _priceController;
  late TextEditingController _experienceDetailsController;
  
  String? _selectedGender;
  bool _hasExperience = false;
  bool _isLoading = false;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.volunteerData['full_name']);
    _emailController = TextEditingController(text: widget.volunteerData['email']);
    _phoneController = TextEditingController(text: widget.volunteerData['phone_number']);
    _placeController = TextEditingController(text: widget.volunteerData['place']);
    _stateController = TextEditingController(text: widget.volunteerData['state']);
    _countryController = TextEditingController(text: widget.volunteerData['country']);
    
    final price = widget.volunteerData['price_per_hour'];
    _priceController = TextEditingController(text: price != null ? price.toString() : '');
    
    _hasExperience = widget.volunteerData['has_experience'] == true;
    _experienceDetailsController = TextEditingController(text: widget.volunteerData['experience_details']);
    
    final genderStr = widget.volunteerData['gender']?.toString();
    if (['Male', 'Female', 'Other'].contains(genderStr)) {
      _selectedGender = genderStr;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _placeController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _priceController.dispose();
    _experienceDetailsController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _apiService.updateVolunteerProfile(
          id: widget.volunteerData['id'],
          fullName: _nameController.text,
          gender: _selectedGender!,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          place: _placeController.text,
          state: _stateController.text,
          country: _countryController.text,
          pricePerHour: double.parse(_priceController.text),
          hasExperience: _hasExperience,
          experienceDetails: _hasExperience ? _experienceDetailsController.text : null,
        );

        if (!mounted) return;

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update failed. Please try again.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.teal.shade700,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Update Your Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),
                
                // Gender
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.people_outline, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600),
                    ),
                  ),
                  value: _selectedGender,
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please select your gender' : null,
                ),
                const SizedBox(height: 20),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(fontSize: 16, color: Colors.black87),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    if (value.length != 10) return 'Please enter exactly 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Location Details Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _placeController,
                        decoration: InputDecoration(
                          labelText: 'Place/City',
                          prefixIcon: const Icon(Icons.location_city, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade600),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: InputDecoration(
                          labelText: 'State',
                          prefixIcon: const Icon(Icons.map, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade600),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Country & Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: InputDecoration(
                          labelText: 'Country',
                          prefixIcon: const Icon(Icons.public, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade600),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price/Hour',
                          prefixIcon: const Icon(Icons.currency_rupee, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade600),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Experience Switch
                SwitchListTile(
                  title: const Text('Do you have prior experience?'),
                  subtitle: const Text('Medical/caregiver experience'),
                  value: _hasExperience,
                  onChanged: (bool value) {
                    setState(() {
                      _hasExperience = value;
                    });
                  },
                  activeColor: Colors.teal,
                ),
                
                // Experience Details
                if (_hasExperience) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _experienceDetailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Experience Details',
                      hintText: 'Describe your previous experience...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade600),
                      ),
                    ),
                    validator: (value) {
                      if (_hasExperience && (value == null || value.isEmpty)) {
                        return 'Please detail your experience';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
