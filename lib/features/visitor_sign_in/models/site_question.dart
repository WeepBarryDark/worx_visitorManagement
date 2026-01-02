import 'dart:convert';
import 'package:worxvisitorapp/services/secure_storage_service.dart';

/// Site Question Model
/// Represents a question that must be answered during visitor sign-in
class SiteQuestion {
  final String id;
  final String text;
  final List<String> options;

  SiteQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  /// Default site safety questions (used when site has no custom questions)
  /// Dynamically retrieves company name from client data
  static Future<List<SiteQuestion>> getDefaultQuestions() async {
    // Get company name from client data
    String companyName = 'the company';
    try {
      final clientJson = await SecureStorageService.getClient();
      if (clientJson != null && clientJson.isNotEmpty) {
        final client = jsonDecode(clientJson) as Map<String, dynamic>;
        // Use trading_name if available, otherwise fall back to name
        companyName = client['trading_name']?.toString().trim() ??
                      client['name']?.toString().trim() ??
                      'the company';
      }
    } catch (e) {
      // If error occurs, use default company name
      companyName = 'the company';
    }

    return [
      SiteQuestion(
        id: '1',
        text: 'I have been advised of the required minimum PPE for this site.',
        options: ['Yes', 'No'],
      ),
      SiteQuestion(
        id: '2',
        text: 'Observe all safety signage, read and follow site rules & instructions of the Site Supervisor.',
        options: ['Yes', 'No'],
      ),
      SiteQuestion(
        id: '3',
        text: 'Not smoke on site except in Designated Areas.',
        options: ['Yes', 'No'],
      ),
      SiteQuestion(
        id: '4',
        text: 'Be escorted by an authorised $companyName representative at all times.',
        options: ['Yes', 'No'],
      ),
      SiteQuestion(
        id: '5',
        text: 'In the event of fire or emergency evacuation, follow the instructions of $companyName representative.',
        options: ['Yes', 'No'],
      ),
      SiteQuestion(
        id: '6',
        text: 'Report any incidents / accident immediately.',
        options: ['Yes', 'No'],
      ),
    ];
  }

  factory SiteQuestion.fromJson(Map<String, dynamic> json) {
    final List<String> parsedOptions;
    final dynamic rawOptions = json['options'];
    if (rawOptions is List) {
      parsedOptions = rawOptions
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      parsedOptions = [];
    }
    if (parsedOptions.isEmpty) {
      parsedOptions.addAll(['Yes', 'No']);
    }

    return SiteQuestion(
      id: json['id']?.toString() ??
          json['question_id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      text: json['question']?.toString() ??
          json['text']?.toString() ??
          'Untitled Question',
      options: parsedOptions,
    );
  }
}
