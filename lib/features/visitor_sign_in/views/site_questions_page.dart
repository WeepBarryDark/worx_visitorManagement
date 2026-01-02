import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:worxvisitorapp/features/visitor_sign_in/models/site_question.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/core/theme/app_theme.dart';

/// Site Questions Page
/// Displays site-specific induction questions that must be answered before completing visitor sign-in
/// All questions must be answered "Yes" to continue
class SiteQuestionsPage extends StatefulWidget {
  const SiteQuestionsPage({
    super.key,
    required this.siteName,
    required this.questions,
    this.logoBytes,
  });

  final String siteName;
  final List<SiteQuestion> questions;
  final Uint8List? logoBytes;

  @override
  State<SiteQuestionsPage> createState() => _SiteQuestionsPageState();
}

class _SiteQuestionsPageState extends State<SiteQuestionsPage> {
  late final Map<String, String> _answers;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _answers = {};
  }

  bool get _allAnswered =>
      widget.questions.every((q) => _answers.containsKey(q.id));

  void _handleContinue() {
    if (!_allAnswered) return;
    final allYes = _answers.values.every(
      (value) => value.trim().toLowerCase() == 'yes',
    );

    if (!allYes) {
      setState(() {
        _errorText = 'All answers must be "Yes" to continue.';
      });
      return;
    }

    // Return the answers map
    Navigator.pop(context, _answers);
  }

  @override
  Widget build(BuildContext context) {
    return KioskGuard(
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: KioskBody(
              siteTitle: widget.siteName,
              logo1Bytes: widget.logoBytes,
              logo1Url: widget.logoBytes == null
                  ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                  : null,
              logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
              menuContent: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Please answer the following before completing sign in.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...widget.questions.asMap().entries.map(_buildQuestionCard),
                    const SizedBox(height: 16),
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorText!,
                          style: TextStyle(
                            color: AppTheme.dangerColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: _allAnswered ? _handleContinue : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(MapEntry<int, SiteQuestion> entry) {
    final index = entry.key + 1;
    final question = entry.value;
    final selected = _answers[question.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.text}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: question.options.map((option) {
              final isSelected = selected == option;
              return ChoiceChip(
                label: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(option),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _answers[question.id] = option;
                    _errorText = null;
                  });
                },
                selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
