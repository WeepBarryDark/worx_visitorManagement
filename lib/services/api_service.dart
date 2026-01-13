import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:worxvisitorapp/core/constants/server_link.dart';
import 'package:worxvisitorapp/services/helper/device_info.dart';

/// API Service for all backend communications
/// Handles authentication, data fetching, and visitor operations
class ApiService {
  static const String baseUrl = ServerLink.mainServerURL;

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Authenticate device with setup code
  /// Payload: {tablet_setup_code, device_name}
  /// Returns: {access_token, ...}
  static Future<Map<String, dynamic>> authenticateDevice({
    required String setupCode,
    String? deviceName,
  }) async {
    try {
      // 1. Get device information
      final deviceInfo = await DeviceInfo.getDeviceInfo();
      final finalDeviceName =
          deviceName ?? deviceInfo['device_name'] ?? 'Unknown Device';

      // 2. Prepare request payload
      final payload = {
        'tablet_setup_code': setupCode,
        'device_name': finalDeviceName,
      };

      // 3. Send POST request to authentication endpoint
      final response = await http
          .post(
            Uri.parse(ServerLink.authenticateURL),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Authentication request timed out. Please check your internet connection.',
              );
            },
          );

      // 4. Parse response
      if (response.statusCode == 200) {
        final raw = response.body.trim();
        if (raw.isEmpty) {
          throw Exception('Empty response from server.');
        }

        if (raw.startsWith('{') || raw.startsWith('[')) {
          final data = jsonDecode(raw) as Map<String, dynamic>;

          if (!data.containsKey('access_token')) {
            throw Exception('Invalid response: missing access_token');
          }
          return data;
        }

        return <String, dynamic>{
          'access_token': raw,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Invalid setup code. Please scan a valid QR code.');
      } else {
        throw Exception(
          'Error code: ${response.statusCode}, please contact developer.',
        );
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      rethrow;
    }
  }

  /// Revoke visitor token (logout)
  /// POST request with Authorization header
  static Future<bool> revokeVisitorToken(String token) async {
    String? deviceName;
    try {
      // Get device information
      final deviceInfo = await DeviceInfo.getDeviceInfo();
      final finalDeviceName =
          deviceName ?? deviceInfo['device_name'] ?? 'Unknown Device';

      final response = await http
          .post(
            Uri.parse(ServerLink.revokeVisitorToken),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: {'device_name': finalDeviceName},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Token revoked successfully');
        return true;
      } else {
        debugPrint('Failed to revoke token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error revoking token: $e');
      return false;
    }
  }

  // ============================================================================
  // DATA FETCHING (Sites, Contacts, Client, Questions)
  // ============================================================================

  /// Fetch visitor sites
  /// GET with Authorization header
  /// Returns: {count: int, data: [sites...]}
  static Future<Map<String, dynamic>> fetchVisitorSites(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(ServerLink.fetchVisitorSites),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to fetch sites: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch visitor contacts
  /// GET with Authorization header
  /// Returns: {count: int, data: [contacts...]}
  static Future<Map<String, dynamic>> fetchVisitorContacts(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(ServerLink.fetchVisitorContacts),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to fetch contacts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch visitor client data (logo, background, company name)
  /// GET with Authorization header
  /// Returns: {logo: string, background_image: string, name: string, trading_name: string}
  static Future<Map<String, dynamic>> fetchVisitorClient(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(ServerLink.fetchVisitorClient),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to fetch client: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch site-specific induction questions
  /// POST with site_id in body
  /// Returns: List of questions or empty list if none configured
  static Future<List<dynamic>> fetchSiteQuestions(
    String token,
    String siteId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ServerLink.fetchVisitorQuestions),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'site_id': siteId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map<String, dynamic>) {
          // Try to extract from common wrapper keys
          final questions =
              data['data'] ?? data['questions'] ?? data['results'];
          if (questions is List) {
            return questions;
          }
        }
        return [];
      } else if (response.statusCode == 404) {
        // No questions configured for this site
        return [];
      } else {
        throw Exception(
          'Failed to fetch site questions: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching site questions: $e');
      return []; // Return empty list on error
    }
  }

  // ============================================================================
  // VISITOR OPERATIONS (Sign In, Sign Out)
  // ============================================================================

  /// Submit visitor sign-in ledger
  /// Required: site_id, name, email, questions, unique_id
  /// Optional: organisation, phone, address, work_type, supervisor, sign_in_time, photo
  /// Returns: {message: "Login Complete", visitor_id: "VIS12345", unique_id: "VIS12345"}
  static Future<Map<String, dynamic>> submitSignInLedger({
    required String token,
    required String siteId,
    required String name,
    required String email,
    required Map<String, dynamic> questions,
    required String uniqueId,
    // Optional fields
    String? organisation,
    String? phone,
    String? address,
    String? workType,
    String? supervisor,
    String? signInTime,
    Uint8List? visitorPhotoBytes,
    String? visitorPhotoFilename,
  }) async {
    try {
      final uri = Uri.parse(ServerLink.pushVisitorSignInLedge);
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      // Required fields
      request.fields['site_id'] = siteId;
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['questions'] = jsonEncode(questions);
      request.fields['unique_id'] = uniqueId;

      // Optional fields
      if (organisation != null && organisation.isNotEmpty) {
        request.fields['organisation'] = organisation;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      if (workType != null && workType.isNotEmpty) {
        request.fields['work_type'] = workType;
      }
      if (supervisor != null && supervisor.isNotEmpty) {
        request.fields['supervisor'] = supervisor;
      }
      if (signInTime != null && signInTime.isNotEmpty) {
        request.fields['sign_in_time'] = signInTime;
      }

      // Add visitor photo as multipart file if available
      if (visitorPhotoBytes != null && visitorPhotoBytes.isNotEmpty) {
        final filename = visitorPhotoFilename ?? 'visitor_photo.jpg';

        // Determine MIME type based on filename extension
        String contentType = 'image/jpeg';
        if (filename.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        } else if (filename.toLowerCase().endsWith('.jpg') ||
                   filename.toLowerCase().endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'photo', // Field name that server expects
            visitorPhotoBytes,
            filename: filename,
            contentType: http.MediaType.parse(contentType),
          ),
        );
      } else {
        debugPrint('No photo to upload');
      }

      debugPrint(
        'Submitting visitor sign-in (multipart) to: ${ServerLink.pushVisitorSignInLedge}',
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 10));
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('Response status: ${streamedResponse.statusCode}');
      debugPrint('Response body: $responseBody');

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;

        // Check for error messages in response
        if (data.containsKey('error')) {
          debugPrint('Error in response: ${data['error']}');
          throw Exception(data['error']);
        }
        if (data.containsKey('message') && data['message'] == 'Evacuate') {
          debugPrint('Site is in evacuation mode');
          throw Exception('Site is in evacuation mode');
        }

        debugPrint('Sign-in submitted successfully');
        if (data.containsKey('visitor_id') || data.containsKey('unique_id')) {
          debugPrint(
            '  Visitor ID: ${data['visitor_id'] ?? data['unique_id']}',
          );
        }

        return data;
      } else {
        // Try to parse error message from response
        try {
          final errorData = jsonDecode(responseBody) as Map<String, dynamic>;

          // Extract error message from various possible formats
          String errorMessage = 'Failed to submit sign-in';

          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          } else if (errorData.containsKey('errors')) {
            // Handle Laravel validation errors format: {"errors": {"email": ["error1", "error2"]}}
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];
            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessages.addAll(messages.map((m) => m.toString()));
              } else {
                errorMessages.add(messages.toString());
              }
            });
            errorMessage = errorMessages.join('\n');
          }

          throw Exception(errorMessage);
        } catch (e) {
          // If JSON parsing fails, use status code
          if (e is Exception &&
              e.toString().startsWith('Exception: Failed to submit sign-in') ==
                  false) {
            rethrow;
          }
          throw Exception(
            'Failed to submit sign-in: ${streamedResponse.statusCode}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error submitting sign-in ledger: $e');
      rethrow;
    }
  }
  /// Sign out a visitor by visitor_id
  /// POST /api/visitor/sign_out
  /// Payload: {visitor_id: "VISITOR123"}
  /// Returns: {success: bool, message: string, data: {...}}
  static Future<Map<String, dynamic>> signOutVisitor({
    required String visitorId,
    required String authToken,
  }) async {
    try {
      final payload = {'visitor_id': visitorId};

      final response = await http
          .post(
            Uri.parse(ServerLink.pushVisitorSignOutLedge),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Sign-out request timed out');
            },
          );
          
      // Handle redirects (302, etc) - usually means auth failed
      if (response.statusCode >= 300 && response.statusCode < 400) {
        debugPrint(
          'Sign-out failed: Redirect ${response.statusCode} (Authentication issue?)',
        );
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('Visitor signed out successfully');
          return {
            'success': true,
            'message': data['message'] ?? 'Sign-out successful',
            'data': data,
          };
        } catch (e) {
          debugPrint(
            'Response not JSON, but status OK: ${response.statusCode}',
          );
          return {'success': true, 'message': 'Sign-out completed'};
        }
      } else {
        // Try to parse error message
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'message':
                errorBody['message'] ?? errorBody['error'] ?? 'Sign-out failed',
          };
        } catch (e) {
          // Response is not JSON (HTML, etc)
          return {
            'success': false,
            'message': 'Sign-out failed (HTTP ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      debugPrint('Error signing out visitor: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================================================
  // NOTIFICATIONS (Email)
  // ============================================================================

  /// Send email notification with optional visitor photo
  /// POST /api/visitor/send_email
  /// Payload: {user_id, name, email, phone, message, logo_url, visitor_photo}
  /// Returns: true if email sent successfully
  static Future<bool> sendEmail({
    required String token,
    required String userId,
    required String name,
    String? email,
    String? phone,
    required String message,
    String? logoUrl,
    String? visitorPhoto, // Base64 encoded visitor photo
  }) async {
    try {
      final url = '$baseUrl/api/visitor/send_email';
      final payload = {
        'user_id': userId,
        'name': name,
        'email': email ?? '',
        'phone': phone ?? '',
        'message': message,
        'logo_url': logoUrl ?? '',
      };

      // Add visitor photo if provided
      if (visitorPhoto != null && visitorPhoto.isNotEmpty) {
        payload['visitor_photo'] = visitorPhoto;
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }

  // ============================================================================
  // FETCH SIGNED IN VISITORS
  // ============================================================================

  /// Fetch all signed in visitors for a site
  /// POST /api/visitor/site_visitors
  /// Payload: {"site_id": "..."}
  /// Returns: List of signed in visitors
  static Future<List<Map<String, dynamic>>> fetchSignedInVisitors({
    required String token,
    required String siteId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ServerLink.fetchSignedInvisitor),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'site_id': siteId}),
          )
          .timeout(const Duration(seconds: 10));

          debugPrint(ServerLink.fetchSignedInvisitor);
          debugPrint(siteId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(ServerLink.fetchSignedInvisitor);
        debugPrint(siteId);
        debugPrint('===============================');
        debugPrint(jsonEncode(data));

        // Handle different response formats
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          // Check common keys for visitor lists
          if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          } else if (data['visitors'] is List) {
            return List<Map<String, dynamic>>.from(data['visitors']);
          } else if (data['site_visitors'] is List) {
            return List<Map<String, dynamic>>.from(data['site_visitors']);
          } else if (data['events'] is List) {
            return List<Map<String, dynamic>>.from(data['events']);
          }
        }

        // Fallback: return empty list
        return [];
      } else {
        throw Exception('Failed to fetch signed in visitors: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching signed in visitors: $e');
      rethrow;
    }
  }
}
