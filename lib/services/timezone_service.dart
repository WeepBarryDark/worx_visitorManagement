class TimezoneSnapshot {
/// Timezone Service - For capturing and formatting timestamps
/// Timezone snapshot - captures both UTC and local time
  final DateTime utcTime;
  final DateTime localTime;
  final String timezone;

  TimezoneSnapshot({
    required this.utcTime,
    required this.localTime,
    required this.timezone,
  });

  /// Get timezone description (e.g., "AEDT (UTC+11)")
  String get timezoneDescription => timezone;

  /// Get formatted UTC time string
  String get formattedUtc => TimezoneService.formatLocal(utcTime);
}

/// Timezone Service
class TimezoneService {
  /// Capture current time in both UTC and local timezone
  static TimezoneSnapshot captureNow() {
    final now = DateTime.now();
    final utc = now.toUtc();

    return TimezoneSnapshot(
      utcTime: utc,
      localTime: now,
      timezone: now.timeZoneName,
    );
  }

  /// Format local time for display
  static String formatLocal(DateTime dateTime) {
    // Format: "Dec 9, 2025 10:30 AM"
    final month = _monthNames[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year $hour:$minute $period';
  }

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
}
