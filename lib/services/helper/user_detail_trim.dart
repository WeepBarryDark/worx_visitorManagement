// -------------------------------------------------------------
// sanitizeContactName
// Cleans a raw contact string and extracts a “clean display name”.
// This removes email parts, brackets, separators, extra spaces, etc.
// -------------------------------------------------------------
//
// EXAMPLES:
// sanitizeContactName("John Smith - Manager") → "John Smith"
// sanitizeContactName("John Smith <john@abc.com>") → "John Smith"
// sanitizeContactName("John Smith (Admin)") → "John Smith"
// sanitizeContactName("john.smith@company.com") → "john.smith"
// sanitizeContactName("  Peter   Wong   ") → "Peter Wong"
// sanitizeContactName("Michael Chang\nProject Manager") → "Michael Chang"
//
String sanitizeContactName(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return text;

  final separators = ['\n', '\r', ',', ' - ', ' – ', ' — ', '|', '(', '['];
  for (final separator in separators) {
    final index = text.indexOf(separator);
    if (index > 0) {
      text = text.substring(0, index).trim();
      break;
    }
  }

  final emailBracketIndex = text.indexOf('<');
  if (emailBracketIndex > 0) {
    text = text.substring(0, emailBracketIndex).trim();
  }

  if (text.contains('@')) {
    text = text.split('@').first.trim();
  }

  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}

// -------------------------------------------------------------
// extractContactName
// Extracts a contact name from dynamic data (String/Map/List).
// This function detects common field names like name/full_name/title.
// -------------------------------------------------------------
//
// EXAMPLES:
// extractContactName("John Doe - Manager") → "John Doe"
// extractContactName({"name": "John Doe"}) → "John Doe"
// extractContactName({"full_name": "Anna Smith <anna@company>"}) → "Anna Smith"
// extractContactName(["Michael Wong (Supervisor)"]) → "Michael Wong"
// extractContactName(null) → ""
// extractContactName({"label": "Peter (Admin)"}) → "Peter"
//
String extractContactName(dynamic raw) {
  if (raw == null) return '';

  if (raw is Map) {
    final keys = [
      'name',
      'full_name',
      'display_name',
      'title',
      'contact_name',
      'label'
    ];
    for (final key in keys) {
      final value = raw[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return sanitizeContactName(value.toString());
      }
    }
  }

  if (raw is List && raw.isNotEmpty) {
    return extractContactName(raw.first);
  }

  final text = raw.toString();
  if (text == 'null') return '';
  return sanitizeContactName(text);
}
