import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//constant
import 'package:worxvisitorapp/core/constants/server_link.dart';

//service
import 'package:worxvisitorapp/services/helper/device_info.dart';

//outline
// 1. authenticateDevice
// 2. fetch Visitor Contacts

class ApiService {
  static const String baseUrl = ServerLink.mainServerURL;

  //authenticateDevice :  payload {tablet_setup_code,device_name} - post to server with token for log in
  static Future<Map<String, dynamic>> authenticateDevice({
    //required parameters
    required String setupCode,
    String? deviceName,
    w,
  }) async {
    try {
      //1.Get deivice information
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

      //debugPrint(response.statusCode);
      //debugPrint(response.body);

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
          //debugPrint("return response from server");
          //debugPrint(data);
          return data;
        }

        return <String, dynamic>{
          'access_token': raw,
          // Backend doesn't have refresh_token / user info yet, can be expanded later
          // 'refresh_token': null,
          // 'user_id': null,
          // 'email': null,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Invalid setup code. Please scan a valid QR code.');
      } else {
        throw Exception(
          'Error code: ${response.statusCode}, please contact developer.',
        );
      }
    } catch (e) {
      debugPrint('Authentication error : $e');
      rethrow;
    }
  }

  //get: payload {token}  ---------- SITES
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
        //print("Sites list---------------");
        //print(data);
        return data;
      } else {
        throw Exception('Failed to fetch contacts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  //get: payload {token}  ---------- CONTACTS
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
        //print("contact list---------------");
        //print(data);
        return data;
      } else {
        throw Exception('Failed to fetch contacts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  //get: payload {token}  ---------- CLIENT
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
        //print("client list---------------");
        //print(data);
        return data;
      } else {
        throw Exception('Failed to fetch contacts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch site-specific induction questions
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

  /// Submit visitor sign-in ledger
  /// Required: site_id, name, email, questions
  /// Optional: organisation, phone, address, work_type, supervisor, sign_in_time
  /// Returns: {"message": "Login Complete", "visitor_id": "VIS12345"}
  /// Or throws exception with error message
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
  }) async {
    try {
      // Required fields
      final payload = <String, dynamic>{
        'site_id': siteId,
        'name': name,
        'email': email,
        'questions': questions,
        'unique_id': uniqueId,
      };

      // Add optional fields only if provided
      if (organisation != null && organisation.isNotEmpty) {
        payload['organisation'] = organisation;
      }
      if (phone != null && phone.isNotEmpty) {
        payload['phone'] = phone;
      }
      if (address != null && address.isNotEmpty) {
        payload['address'] = address;
      }
      if (workType != null && workType.isNotEmpty) {
        payload['work_type'] = workType;
      }
      if (supervisor != null && supervisor.isNotEmpty) {
        payload['supervisor'] = supervisor;
      }
      if (signInTime != null && signInTime.isNotEmpty) {
        payload['sign_in_time'] = signInTime;
      }

      //debugPrint('📤 Submitting sign-in ledger:--------------------------------');
      //debugPrint(jsonEncode(payload));

      final response = await http
          .post(
            Uri.parse(ServerLink.pushVisitorSignInLedge),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      //debugPrint('📥 Sign-in response: ${response.statusCode}------------------------');
      //debugPrint(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Check for error messages in response
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        if (data.containsKey('message') && data['message'] == 'Evacuate') {
          throw Exception('Site is in evacuation mode');
        }

        return data;
      } else {
        // Try to parse error message from response
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;

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
          throw Exception('Failed to submit sign-in: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error submitting sign-in ledger: $e');
      rethrow;
    }
  }

  /// Send email notification
  static Future<bool> sendEmail({
    required String token,
    required String userId,
    required String name,
    String? email,
    String? phone,
    required String message,
    String? logoUrl,
  }) async {
    try {
      final url = '$baseUrl/api/visitor/send_email';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'name': name,
              'email': email ?? '',
              'phone': phone ?? '',
              'message': message,
              'logo_url': logoUrl ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }

  /// Revoke visitor token (logout)
  /// POST request with Authorization header only
  static Future<bool> revokeVisitorToken(String token) async {
    String? deviceName;
    try {
      //1.Get deivice information
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

  /// Sign out a visitor by visitor_id
  /// POST /api/visitor/sign_out
  /// Payload: {"visitor_id": "VISITOR123"}
  /// Returns: {success: bool, message: string}
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
}


/*
SELECT * FROM `personal_access_tokens` WHERE `abilities` LIKE '%[\"visitor_app\"]%'

QR URL code
https://app.worxsafety.com.au/qr-login/ada81466-a91e-4a7c-852b-231d09f22db1

 return response from server
{access_token: 104|WJ8BbFvMLZlNBsDvEncmxOvywC7RRSeupz2pAdMZ3387160b}

✅ Auth token saved securely
✅ Authentication success, token saved.

client list 
{logo: https://storage.worxsafety.com.au/site/public/22080/pblogo.svg, name: HUGH ARTHUR TORNEY, trading_name: Pink Batteries}

contact list---------------
{count: 19, data: [{id: 31, name: Luke One, email: luke.1@neboengineering.com.au, phone: 0405756899, mobile: 0405765432, emergencyContact: Luke Two, emergencyPhone: null, workType: {id: 20, name: Engineering}, residency: Australian Citizen, residencyDetails: null, residencyExpiry: 2025-12-08T04:34:16+00:00, dob: 1978-10-05T00:00:00+00:00, role: user, approved: 0, approvalDate: 2025-12-08T04:34:16+00:00, approver: {id: null, name: null}, status: Pending, revokeReason: Your induction has expired please redo your induction., createdOn: 2021-10-05T06:34:45+00:00, active: 1}, {id: 3231, name: David Moodie, email: david@101design.com.au, phone: 02 4226 2102, mobile: 0402 681 626, emergencyContact: Good Luck, emergencyPhone: null, workType: {id: 59, name: IT Services}, residency: Australian Citizen, residencyDetails: null, residencyExpiry: 2025-12-08T04:34:16+00:00, dob: 1979-05-28T00:00:00+00:00, role: admin, approved: 1, approvalDate: 2024-09-09T02:12:47+00:00, approver: {id: 23, name: Hugh Torney}, status: Appro

Sites list---------------
{count : 37, data: [{id: 1, name: 1002567 Thirroul Development - Alternate Loc 1002567 Thirroul Development - Alternate Loc, address: 50 Redman Ave1, THIRROUL, NSW, 25001, Australia, streetAddress: 50 Redman Ave1, suburb: null, state: NSW, postcode: 25001, country: Australia, latitude: -34.27741962, longitude: 150.95425334, contact: 04057654387, managerName: Luke One1, customerName: Test CLIENT1, customerContact: 0400000123, supervisor: {id: 25214, name: Barry Weep Admin}, createdOn: 2021-08-10T03:59:45+00:00}, {id: 4198, name: Super Numerary Project, address: 65 Princess Hwy, Fairy Meadow, NSW, 2500, Australia, streetAddress: 65 Princess Hwy, suburb: null, state: NSW, postcode: 2500, country: Australia, latitude: -34.3951246, longitude: 150.892491, contact: 0422 502 693, managerName: Hugh PB User, customerName: null, customerContact: null, supervisor: {id: 23, name: Hugh Torney}, createdOn: 2024-04-05T03:54:40+00:00}, {id: 4199, name: Hugh Torney, address: Unit 2 / 1 Myrtle Street, CONISTOwN, NSW, 2500, Aus

visitor contacts ==================================
[{id: 31, name: Luke One, email: luke.1@neboengineering.com.au, phone: 0405756899, mobile: 0405765432, emergencyContact: Luke Two, emergencyPhone: null, workType: {id: 20, name: Engineering}, residency: Australian Citizen, residencyDetails: null, residencyExpiry: 2025-12-08T09:06:46+00:00, dob: 1978-10-05T00:00:00+00:00, role: user, approved: 0, approvalDate: 2025-12-08T09:06:46+00:00, approver: {id: null, name: null}, status: Pending, revokeReason: Your induction has expired please redo your induction., createdOn: 2021-10-05T06:34:45+00:00, active: 1}, {id: 3231, name: David Moodie, email: david@101design.com.au, phone: 02 4226 2102, mobile: 0402 681 626, emergencyContact: Good Luck, emergencyPhone: null, workType: {id: 59, name: IT Services}, residency: Australian Citizen, residencyDetails: null, residencyExpiry: 2025-12-08T09:06:46+00:00, dob: 1979-05-28T00:00:00+00:00, role: admin, approved: 1, approvalDate: 2024-09-09T02:12:47+00:00, approver: {id: 23, name: Hugh Torney}, status: Approved, revokeReason:

site questions - default question ===================
[I have been advised of the required minimum PPE for this site., Observe all safety signage, read and follow site rules & instructions of the Site Supervisor., Not smoke on site except in Designated Areas., Be escorted by an authorised Pink Batteries representative at all times., In the event of fire or emergency evacuation, follow the instructions of Pink Batteries representative., Report any incidents / accident immediately.]

site questions ==================================
Site ID: 1
Token: 110|...6dd0
I/flutter (31977):
Response Type: List<dynamic>
Response Data:
[
  {
    "question": "I know where to find relevant site-specific plans and workplace safety documentation.",
    "default": 0
  },
  {
    "question": "Are you fit for work today?.",
    "default": 0
  },
  {
    "question": "I have correct PPE for my task.",
    "default": 0
  },
  {
    "question": "I have a Safe Work Method Statement (SWMS) for High Risk Construction Work (HRCW).",
    "default": 0
  },
  {
    "question": "Do you agree to the site safety rules?",
    "default": 0
  },
  {
    "question": "Electrical Test & Tag – If using tools, are they all tested and tagged & in good working order.",
    "default": 0
  }
]
*/