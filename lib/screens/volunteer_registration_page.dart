import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wellness_wings/services/api_service.dart';
//import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

class VolunteerRegistrationPage extends StatefulWidget {
  const VolunteerRegistrationPage({super.key});

  @override
  _VolunteerRegistrationPageState createState() => _VolunteerRegistrationPageState();
}

class _InterviewQuestion {
  final String question;
  final List<String> options;
  String? selectedAnswer;

  _InterviewQuestion({
    required this.question,
    required this.options,
  });
}

class _VolunteerRegistrationPageState extends State<VolunteerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _selectedGender;
  String? _selectedFileName;
  bool _agreedToTerms = false;
  bool _hasExperience = false;
  bool _interviewCompleted = false;
  final _apiService = ApiService();
  final _placeController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _priceController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _profileImageBytes;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<Uint8List?> _compressImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Calculate new dimensions while maintaining aspect ratio
      int maxWidth = 800; // Max width for the image
      int maxHeight = 800; // Max height for the image
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (image.width > maxWidth) {
        newWidth = maxWidth;
        newHeight = (image.height * maxWidth / image.width).round();
      }
      
      if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = (image.width * maxHeight / image.height).round();
      }

      // Resize the image
      img.Image resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
      );

      // Encode the image to jpg with quality (0-100)
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final originalBytes = result.files.first.bytes;
        if (originalBytes != null) {
          // Compress the image
          final compressedBytes = await _compressImage(originalBytes);
          if (compressedBytes != null) {
            setState(() {
              _profileImageBytes = compressedBytes;
              print('Compressed image size: ${compressedBytes.length} bytes');
            });
          } else {
            throw Exception('Failed to compress image');
          }
        }
      }
    } catch (e) {
      print('Error picking profile picture: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting profile picture. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Volunteer Terms and Conditions'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Volunteer Responsibilities',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '• Commit to providing reliable transportation assistance\n'
                  '• Maintain punctuality for all scheduled appointments\n'
                  '• Treat elderly and physically challenged individuals with respect and dignity\n'
                  '• Maintain confidentiality of user information',
                ),
                SizedBox(height: 10),
                Text(
                  '2. Safety and Security',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '• Follow all traffic laws and safety regulations\n'
                  '• Maintain a valid driver\'s license and clean driving record\n'
                  '• Ensure vehicle is properly maintained and insured\n'
                  '• Report any incidents or accidents immediately',
                ),
                SizedBox(height: 10),
                Text(
                  '3. Code of Conduct',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '• Maintain professional boundaries with users\n'
                  '• No acceptance of monetary gifts from users\n'
                  '• No discrimination based on race, religion, or gender\n'
                  '• Report any inappropriate behavior or concerns',
                ),
                SizedBox(height: 10),
                Text(
                  '4. Commitment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Volunteers are expected to commit to a minimum number of hours per month and provide advance notice for any schedule changes.',
                ),
                SizedBox(height: 10),
                Text(
                  '5. Background Check',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'All volunteers must pass a background check and provide valid identification.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  final List<_InterviewQuestion> _interviewQuestions = [
    _InterviewQuestion(
      question: '1. Why do you want to volunteer with elderly and physically challenged individuals?',
      options: [
        'To gain work experience in healthcare',
        'To make a positive impact in others\' lives',
        'To fulfill community service requirements',
        'To spend my free time productively'
      ],
    ),
    _InterviewQuestion(
      question: '2. How would you handle an emergency situation while assisting someone?',
      options: [
        'Call emergency services immediately',
        'Contact the person\'s family first',
        'Try to handle the situation myself',
        'Ask nearby people for help'
      ],
    ),
    _InterviewQuestion(
      question: '3. What is your understanding of patient confidentiality?',
      options: [
        'Never share patient information with anyone',
        'Share information only with family members',
        'Share information only when necessary',
        'Share information with other volunteers'
      ],
    ),
    _InterviewQuestion(
      question: '4. How many hours per week can you commit to volunteering?',
      options: [
        'Less than 5 hours',
        '5-10 hours',
        '10-15 hours',
        'More than 15 hours'
      ],
    ),
    _InterviewQuestion(
      question: '5. What is your approach to helping elderly individuals?',
      options: [
        'Being patient and understanding',
        'Being quick and efficient',
        'Being professional and distant',
        'Being casual and friendly'
      ],
    ),
  ];

  void _showInterviewQuestions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Volunteer Interview Questions',
                style: TextStyle(color: Colors.teal),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please answer all questions to proceed:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ..._interviewQuestions.map((question) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.question,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...question.options.map((option) {
                            return RadioListTile<String>(
                              title: Text(option),
                              value: option,
                              groupValue: question.selectedAnswer,
                              onChanged: (value) {
                                setState(() {
                                  question.selectedAnswer = value;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: () {
                    bool allAnswered = _interviewQuestions.every(
                        (question) => question.selectedAnswer != null);
                    if (allAnswered) {
                      this.setState(() {
                        _interviewCompleted = true;
                      });
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Thank you for completing the interview questions. Our team will review your responses.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please answer all questions'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfilePictureSelector() {
    return Column(
      children: [
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_a_photo),
          label: Text(_profileImageBytes != null ? 'Change Profile Picture' : 'Add Profile Picture'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _pickProfilePicture,
        ),
        if (_profileImageBytes != null) ...[
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: ClipOval(
                  child: Image.memory(
                    _profileImageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return const Icon(Icons.error);
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle),
                  color: Colors.red,
                  onPressed: () {
                    setState(() {
                      _profileImageBytes = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Volunteer Registration',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                // Header section
                const Text(
                  'Join Our Community',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Make a difference in someone\'s life',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Picture Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildProfilePictureSelector(),
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Account Information Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.people_outline, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              .map((gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Location Information Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _placeController,
                          decoration: InputDecoration(
                            labelText: 'Place',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your place';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            labelText: 'State',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.map_outlined, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your state';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _countryController,
                          decoration: InputDecoration(
                            labelText: 'Country',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.public_outlined, color: Colors.teal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your country';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Experience Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Experience & Pricing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SwitchListTile(
                          title: Text(
                            'Do you have volunteering experience?',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          value: _hasExperience,
                          activeColor: Colors.teal.shade600,
                          onChanged: (bool value) {
                            setState(() {
                              _hasExperience = value;
                            });
                          },
                        ),
                        if (_hasExperience) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _experienceController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Experience Details',
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              prefixIcon: const Icon(Icons.work_outline, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                return 'Please describe your volunteering experience';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.quiz_outlined),
                            label: const Text('Take Interview Questions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _showInterviewQuestions,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price per hour (in Rs)',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(Icons.currency_rupee, color: Colors.teal),
                            prefixText: '₹ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.teal.shade600),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your price per hour';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Terms and Register Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            activeColor: Colors.teal.shade600,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsDialog,
                              child: Text(
                                'I agree to the Terms and Conditions',
                                style: TextStyle(
                                  color: Colors.teal.shade700,
                                  decoration: TextDecoration.underline,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            if (!_agreedToTerms) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please agree to the Terms and Conditions'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              if (!_hasExperience && !_interviewCompleted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please complete the interview questions'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() {
                                  _isLoading = false;
                                });
                                return;
                              }

                              String? base64Image;
                              if (_profileImageBytes != null) {
                                base64Image = base64Encode(_profileImageBytes!);
                              }

                              final result = await _apiService.registerVolunteer(
                                fullName: _nameController.text.trim(),
                                gender: _selectedGender!,
                                email: _emailController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                password: _passwordController.text,
                                hasExperience: _hasExperience,
                                experienceDetails: _hasExperience ? _experienceController.text : null,
                                idCardPath: _selectedFileName,
                                profilePicture: base64Image,
                                place: _placeController.text.trim(),
                                state: _stateController.text.trim(),
                                country: _countryController.text.trim(),
                                pricePerHour: double.tryParse(_priceController.text) ?? 0,
                                interviewAnswers: !_hasExperience ? {
                                  for (var q in _interviewQuestions)
                                    q.question: q.selectedAnswer ?? ''
                                } : null,
                              );

                              setState(() {
                                _isLoading = false;
                              });

                              if (result['success']) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Registration successful'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pushReplacementNamed(context, '/volunteer_login');
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Registration failed'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Registration failed: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
