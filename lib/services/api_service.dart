import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
//import 'dart:io';
//import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
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
      } else {
        return {
          'success': false,
          'message': 'Server error: Invalid response format',
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
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'],
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
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/volunteer/available?service_type=$serviceType&emergency=$emergency'),
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
