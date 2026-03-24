import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
//import 'dart:io';
//import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.140.62.54:3000/api'; // Machine IP for physical device connectivity
  // static const String baseUrl = 'http://10.255.68.54:3000/api'; // Previous Machine IP
  // static const String baseUrl = 'http://10.64.75.196:3000/api'; // Previous Machine IP
  // static const String baseUrl = 'http://localhost:3000/api'; // Using ADB reverse proxy (adb reverse tcp:3000 tcp:3000)
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android Emulator default host loopback


  Future<Map<String, dynamic>> checkElderlyStatus(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/elderly/profile/$id'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Elderly user not found'};
      }
    } catch (e) {
      print('Check Elderly Status error: $e');
      return {'success': false, 'message': 'Connection error or timeout.'};
    }
  }

  Future<Map<String, dynamic>> checkVolunteerStatus(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/volunteer/profile/$id'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Volunteer not found'};
      }
    } catch (e) {
      print('Check Volunteer Status error: $e');
      return {'success': false, 'message': 'Connection error or timeout.'};
    }
  }

  Future<Map<String, dynamic>> getPendingVolunteers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/pending-volunteers'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Fetch Pending Volunteers error: $e');
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  Future<Map<String, dynamic>> approveVolunteer(int id) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/admin/approve-volunteer/$id'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Approve Volunteer error: $e');
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  Future<Map<String, dynamic>> rejectVolunteer(int id) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/admin/reject-volunteer/$id'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Reject Volunteer error: $e');
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  Future<Map<String, dynamic>> updateElderlyProfile({
    required int id,
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/elderly/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName.trim(),
          'gender': gender,
          'email': email.trim().toLowerCase(),
          'phoneNumber': phoneNumber.trim(),
          'address': address.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final elderlyDetailsStr = prefs.getString('elderly_details');
        if (elderlyDetailsStr != null) {
          Map<String, dynamic> cachedDetails = jsonDecode(elderlyDetailsStr);
          cachedDetails.addAll(responseData['user']);
          await prefs.setString('elderly_details', jsonEncode(cachedDetails));
        }
        
        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('Update Profile error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    }
  }

  Future<Map<String, dynamic>> updateElderlyLocation({
    required int id,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/elderly/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateVolunteerLocation({
    required int id,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteer/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> registerElderly({
    required String fullName,
    required String gender,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/elderly/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'gender': gender,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'address': address,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error',
      };
    }
  }

  Future<Map<String, dynamic>> registerVolunteer({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
    required bool hasExperience,
    required String place,
    required String state,
    required String country,
    required double pricePerHour,
    String? experienceDetails,
    String? idCardPath,
    String? profilePicture,
    String? verificationId,
    String? idType,
    Map<String, String>? interviewAnswers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteer/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'gender': gender,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'has_experience': hasExperience,
          'experience_details': experienceDetails,
          'id_card_path': idCardPath,
          'profile_picture': profilePicture,
          'place': place,
          'state': state,
          'country': country,
          'price_per_hour': pricePerHour,
          'interview_answers': interviewAnswers,
          'verification_id': verificationId,
          'id_type': idType,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> loginElderly({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/elderly/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
          // Store elderly details in shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('elderly_details', jsonEncode(data['user']));
          
          return {
            'success': true,
            'message': data['message'],
            'user': data['user'],
          };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    }
  }

  Future<Map<String, dynamic>> updateVolunteerProfile({
    required int id,
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String place,
    required String state,
    required String country,
    required double pricePerHour,
    required bool hasExperience,
    required String? experienceDetails,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/volunteer/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName.trim(),
          'gender': gender,
          'email': email.trim().toLowerCase(),
          'phoneNumber': phoneNumber.trim(),
          'place': place.trim(),
          'state': state.trim(),
          'country': country.trim(),
          'pricePerHour': pricePerHour,
          'hasExperience': hasExperience,
          'experienceDetails': experienceDetails?.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final volunteerDetailsStr = prefs.getString('volunteer_details');
        if (volunteerDetailsStr != null) {
          Map<String, dynamic> cachedDetails = jsonDecode(volunteerDetailsStr);
          cachedDetails.addAll(responseData['user']);
          await prefs.setString('volunteer_details', jsonEncode(cachedDetails));
        }
        
        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('Update Profile error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    }
  }

  Future<Map<String, dynamic>> loginVolunteer({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteer/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = responseData['user'];
        final userStatus = (user['status'] as String? ?? 'pending').toLowerCase().trim();

        // IMPORTANT: Only cache the session if the volunteer is approved.
        // Pending/rejected users must NOT have a cached session.
        if (userStatus == 'approved') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('volunteer_details', jsonEncode(user));
        } else {
          // Ensure any stale session is cleared
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('volunteer_details');
        }

        return {
          'success': true,
          'message': responseData['message'],
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Invalid email or password',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Login failed. Please check your internet connection.',
      };
    }
  }

  Future<Map<String, dynamic>> getVolunteerServices({
    required String volunteerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/volunteer/services/$volunteerId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to load services',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load services: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateVolunteerServices({
    required String volunteerId,
    required List<Map<String, dynamic>> services,
  }) async {
    try {
      // Ensure volunteerId is an integer
      final id = int.parse(volunteerId);
      
      print('Sending request to: $baseUrl/volunteer/services/$id');
      print('Request body: ${jsonEncode({'services': services})}');

      final response = await http.post(
        Uri.parse('$baseUrl/volunteer/services/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'services': services.map((service) => {
            'service_type': service['service_type'],
            'is_available': service['is_available'],
          }).toList(),
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorBody['message'] ?? 'Failed to update services',
        };
      }
    } catch (e) {
      print('Exception during service update: $e');
      return {
        'success': false,
        'message': 'Failed to update services: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getAvailableVolunteers({
    required String serviceType,
    required bool emergency,
    double? latitude,
    double? longitude,
  }) async {
    try {
      String url = '$baseUrl/volunteer/available?service_type=$serviceType&emergency=$emergency';
      if (latitude != null && longitude != null) {
        url += '&lat=$latitude&lng=$longitude';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch volunteers',
          'volunteers': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'volunteers': [],
      };
    }
  }

  Future<Map<String, dynamic>> getElderlyDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/elderly/details'),
        headers: {
          'Content-Type': 'application/json',
          // Add any necessary authentication headers here
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch elderly details',
        };
      }
    } catch (e) {
      print('Error fetching elderly details: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getVolunteerBookings(String volunteerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/volunteer/bookings/$volunteerId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response body: ${response.body}'); // For debugging

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Error response: ${response.body}'); // For debugging
        return {
          'success': false,
          'message': 'Failed to fetch bookings',
          'bookings': [],
        };
      }
    } catch (e) {
      print('Error fetching bookings: $e'); // For debugging
      return {
        'success': false,
        'message': 'Failed to fetch bookings: ${e.toString()}',
        'bookings': [],
      };
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String volunteerId,
    required Map<String, dynamic> elderlyDetails,
    required String serviceType,
    required String description,
    required bool isEmergency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/volunteer/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'volunteer_id': volunteerId,
          'elderly_id': elderlyDetails['id'].toString(),
          'service_type': serviceType,
          'description': description,
          'is_emergency': isEmergency,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create booking: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update booking status');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating booking status: ${e.toString()}',
      };
    }
  }
}
