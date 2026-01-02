String parserName(dynamic value) {
  if (value == null) return '';

  if (value is Map<String, dynamic>) {
    return value['name']?.toString() ?? '';
  }

  if (value is String) {

    if (!value.contains('{')) return value;
    
    final nameMatch = RegExp(r'name\s*:\s*([^,}]+)').firstMatch(value);
    if (nameMatch != null) {
      return nameMatch.group(1)!.trim();
    }

    return value; // fallback
  }

  return value.toString();
}