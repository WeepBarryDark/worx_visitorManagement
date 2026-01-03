/// Print Status Model for tracking badge printing progress
/// Used to display real-time printing status in the visitor kiosk
enum PrintStatus {
  /// Initial state before printing starts
  idle,

  /// Connecting to the printer
  connecting,

  /// Sending print job to printer
  sending,

  /// Waiting for printer response
  receiving,

  /// Print job is queued (position in queue)
  queued,

  /// Currently printing
  printing,

  /// Print job completed successfully
  completed,

  /// Print job failed with error
  failed,
}

/// Extension to get user-friendly display text for each status
extension PrintStatusExtension on PrintStatus {
  String get displayText {
    switch (this) {
      case PrintStatus.idle:
        return 'Ready';
      case PrintStatus.connecting:
        return 'Connecting to printer...';
      case PrintStatus.sending:
        return 'Sending print job...';
      case PrintStatus.receiving:
        return 'Waiting for response...';
      case PrintStatus.queued:
        return 'Print job queued';
      case PrintStatus.printing:
        return 'Printing badge...';
      case PrintStatus.completed:
        return 'Print completed';
      case PrintStatus.failed:
        return 'Print failed';
    }
  }

  String get icon {
    switch (this) {
      case PrintStatus.idle:
        return '⏸️';
      case PrintStatus.connecting:
        return '🔌';
      case PrintStatus.sending:
        return '📤';
      case PrintStatus.receiving:
        return '📥';
      case PrintStatus.queued:
        return '⏳';
      case PrintStatus.printing:
        return '🖨️';
      case PrintStatus.completed:
        return '✅';
      case PrintStatus.failed:
        return '❌';
    }
  }

  bool get isInProgress {
    return this == PrintStatus.connecting ||
           this == PrintStatus.sending ||
           this == PrintStatus.receiving ||
           this == PrintStatus.queued ||
           this == PrintStatus.printing;
  }

  bool get isCompleted {
    return this == PrintStatus.completed;
  }

  bool get isFailed {
    return this == PrintStatus.failed;
  }
}

/// Print progress information
class PrintProgress {
  final PrintStatus status;
  final String? message;
  final int? queuePosition; // Position in print queue (if queued)
  final DateTime timestamp;

  PrintProgress({
    required this.status,
    this.message,
    this.queuePosition,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  PrintProgress.idle()
      : status = PrintStatus.idle,
        message = null,
        queuePosition = null,
        timestamp = DateTime.now();

  PrintProgress.connecting()
      : status = PrintStatus.connecting,
        message = 'Establishing connection...',
        queuePosition = null,
        timestamp = DateTime.now();

  PrintProgress.sending()
      : status = PrintStatus.sending,
        message = 'Uploading badge data...',
        queuePosition = null,
        timestamp = DateTime.now();

  PrintProgress.receiving()
      : status = PrintStatus.receiving,
        message = 'Waiting for printer acknowledgment...',
        queuePosition = null,
        timestamp = DateTime.now();

  PrintProgress.queued(int position)
      : status = PrintStatus.queued,
        message = 'Position in queue: $position',
        queuePosition = position,
        timestamp = DateTime.now();

  PrintProgress.printing()
      : status = PrintStatus.printing,
        message = 'Your badge is being printed...',
        queuePosition = null,
        timestamp = DateTime.now();

  PrintProgress.completed()
      : status = PrintStatus.completed,
        message = 'Badge printed successfully!',
        queuePosition = null,
        timestamp = DateTime.now();

  PrintProgress.failed(String errorMessage)
      : status = PrintStatus.failed,
        message = errorMessage,
        queuePosition = null,
        timestamp = DateTime.now();

  String get displayMessage {
    if (message != null) return message!;
    return status.displayText;
  }

  @override
  String toString() {
    return 'PrintProgress(status: ${status.displayText}, message: $message, queuePosition: $queuePosition)';
  }
}
