import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'secure_storage_service.dart';

class NotificationService {
  static const String _smsEndpoint = '${ApiService.baseUrl}/api/visitor/send_sms';

  /// Sends SMS payload to backend. Returns true if API responded with success.
  static Future<bool> sendTextMessage({
    required String userId,
    required String mobile,
    required String message,
  }) async {
    try {
      final authToken = await SecureStorageService.getAuthToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      /*debugPrint(
        'SENDING SMS | '
        'Endpoint: $_smsEndpoint | '
        'Recipient User ID: $userId | '
        'Phone Number: $mobile | '
        'Message: $message'
      );*/
      final response = await http
          .post(
            Uri.parse(_smsEndpoint),
            headers: headers,
            body: jsonEncode({
              'user_id': userId,
              'mobile': mobile,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final success = response.statusCode >= 200 && response.statusCode < 300;
      /* debugPrint(
        'SMS RESPONSE | '
        'Status Code: ${response.statusCode} | '
        'Success: $success | '
        'Body: ${response.body}'
      );*/
      return success;
    } catch (e) {
      debugPrint('SMS send error: $e');
      return false;
    }
  }

  static String buildVisitorSignInMessage({
    required String siteName,
    required String visitorName,
    String? company,
    String? phoneNumber,
    String? workType,
  }) {
    final buffer = StringBuffer();
    buffer.write('$siteName: ');

    final displayName =
        visitorName.isEmpty ? 'A visitor' : visitorName.trim();
    buffer.write(displayName);

    if (workType != null && workType.trim().isNotEmpty) {
      buffer.write(' the ${workType.trim().toLowerCase()}');
    } else {
      buffer.write(' the visitor');
    }

    if (company != null && company.trim().isNotEmpty) {
      buffer.write(' from ${company.trim()}');
    }

    buffer.write(' has signed in as a visitor.');

    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      buffer.write(' Ph: ${phoneNumber.trim()}');
    }
    return buffer.toString();
  }

  static String buildVisitorSignOutMessage({
    required String siteName,
    required String visitorName,
  }) {
    final displayName =
        visitorName.isEmpty ? 'A visitor' : visitorName.trim();
    return '$siteName: $displayName has signed out.';
  }

  static String buildDeliveryArrivalMessage({
    required String siteName,
    required String companyName,
  }) {
    final trimmed = companyName.trim();
    final body = trimmed.isEmpty
        ? 'A delivery has arrived to site.'
        : 'A delivery from $trimmed has arrived to site.';
    return '$siteName: $body';
  }

  static Map<String, String> buildVisitorSignInEmail({
    required String siteName,
    required String visitorName,
    String? company,
    String? phoneNumber,
    String? workType,
  }) {
    final subject = 'Visitor signed in - $siteName';
    final buffer = StringBuffer();
    buffer.writeln('Site: $siteName');
    buffer.writeln('Visitor: ${visitorName.isEmpty ? 'Unknown visitor' : visitorName}');
    if (company != null && company.trim().isNotEmpty) {
      buffer.writeln('Company: ${company.trim()}');
    }
    if (workType != null && workType.trim().isNotEmpty) {
      buffer.writeln('Work type: ${workType.trim()}');
    }
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      buffer.writeln('Phone: ${phoneNumber.trim()}');
    }
    buffer.writeln('');
    buffer.write('This visitor has signed in via the Worx Companion kiosk.');
    return {'subject': subject, 'body': buffer.toString()};
  }

  static Map<String, String> buildVisitorSignOutEmail({
    required String siteName,
    required String visitorName,
  }) {
    final subject = 'Visitor signed out - $siteName';
    final buffer = StringBuffer();
    buffer.writeln('Site: $siteName');
    buffer.writeln('Visitor: ${visitorName.isEmpty ? 'Unknown visitor' : visitorName}');
    buffer.writeln('');
    buffer.write('This visitor has signed out via the Worx Companion kiosk.');
    return {'subject': subject, 'body': buffer.toString()};
  }

  static Map<String, String> buildDeliveryArrivalEmail({
    required String siteName,
    required String companyName,
  }) {
    final subject = 'Delivery arrival - $siteName';
    final buffer = StringBuffer();
    buffer.writeln('Site: $siteName');
    if (companyName.trim().isNotEmpty) {
      buffer.writeln('Delivery from: ${companyName.trim()}');
    } else {
      buffer.writeln('Delivery: Unspecified company');
    }
    buffer.writeln('');
    buffer.write('A delivery has arrived at the site. Please follow your standard receiving process.');
    return {'subject': subject, 'body': buffer.toString()};
  }

  /// Send email notification
  /// Returns true if API responded with success
  static Future<bool> sendEmail({
    required String userId,
    required String name,
    String? email,
    String? phone,
    required String message,
    String? logoUrl,
    String? visitorPhoto,  // Base64 encoded visitor photo
  }) async {
    try {
      final authToken = await SecureStorageService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('Email send failed: No auth token');
        return false;
      }

      /* debugPrint(
        'SENDING EMAIL | '
        'Endpoint: ${ApiService.baseUrl}/api/visitor/send_email | '
        'Recipient User ID: $userId | '
        'Recipient Name: $name | '
        'Email Address: ${email ?? "(empty)"} | '
        'Phone Number: ${phone ?? "(empty)"} | '
        'Message Length: ${message.length} chars | '
        'Logo URL: ${logoUrl ?? "(none)"} | '
        'Visitor Photo: ${visitorPhoto != null ? "Included" : "(none)"}'
      );
      */

      final success = await ApiService.sendEmail(
        token: authToken,
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        message: message,
        logoUrl: logoUrl,
        visitorPhoto: visitorPhoto,
      );
      debugPrint('Email Response: Success: $success ');
      return success;
    } catch (e) {
      debugPrint('Email send error: $e');
      return false;
    }
  }
}
