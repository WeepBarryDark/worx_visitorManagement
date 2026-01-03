import 'package:flutter/material.dart';
import '../core/models/print_status.dart';
import '../core/theme/app_theme.dart';

/// Print Progress Widget - Displays real-time printing status
/// Shows detailed progress information during badge printing
class PrintProgressWidget extends StatelessWidget {
  const PrintProgressWidget({
    super.key,
    required this.progress,
    this.showIcon = true,
    this.showTimestamp = false,
  });

  final PrintProgress progress;
  final bool showIcon;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status header
          Row(
            children: [
              if (showIcon) ...[
                _buildStatusIcon(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.status.displayText,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(),
                      ),
                    ),
                    if (progress.message != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        progress.message!,
                        style: tt.bodySmall?.copyWith(
                          color: _getTextColor().withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (progress.status.isInProgress)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTextColor(),
                    ),
                  ),
                ),
            ],
          ),

          // Queue position (if applicable)
          if (progress.queuePosition != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue,
                    size: 18,
                    color: _getTextColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Position in queue: #${progress.queuePosition}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Timestamp (if enabled)
          if (showTimestamp) ...[
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(progress.timestamp),
              style: tt.bodySmall?.copyWith(
                color: _getTextColor().withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    switch (progress.status) {
      case PrintStatus.idle:
        iconData = Icons.pause_circle_outline;
        break;
      case PrintStatus.connecting:
        iconData = Icons.cable;
        break;
      case PrintStatus.sending:
        iconData = Icons.upload;
        break;
      case PrintStatus.receiving:
        iconData = Icons.download;
        break;
      case PrintStatus.queued:
        iconData = Icons.queue;
        break;
      case PrintStatus.printing:
        iconData = Icons.print;
        break;
      case PrintStatus.completed:
        iconData = Icons.check_circle;
        break;
      case PrintStatus.failed:
        iconData = Icons.error;
        break;
    }

    return Icon(
      iconData,
      size: 32,
      color: _getTextColor(),
    );
  }

  Color _getBackgroundColor() {
    if (progress.status.isFailed) {
      return AppTheme.statusBackgroundColor('error');
    } else if (progress.status.isCompleted) {
      return AppTheme.statusBackgroundColor('success');
    } else if (progress.status.isInProgress) {
      return AppTheme.statusBackgroundColor('info');
    } else {
      return AppTheme.statusBackgroundColor('default');
    }
  }

  Color _getBorderColor() {
    if (progress.status.isFailed) {
      return AppTheme.dangerColor;
    } else if (progress.status.isCompleted) {
      return AppTheme.successColor;
    } else if (progress.status.isInProgress) {
      return AppTheme.primaryBlue;
    } else {
      return AppTheme.slate300;
    }
  }

  Color _getTextColor() {
    if (progress.status.isFailed) {
      return AppTheme.dangerColor;
    } else if (progress.status.isCompleted) {
      return AppTheme.successColor;
    } else if (progress.status.isInProgress) {
      return AppTheme.primaryBlue;
    } else {
      return AppTheme.slate700;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Compact version of print progress - single line with icon and text
class PrintProgressCompact extends StatelessWidget {
  const PrintProgressCompact({
    super.key,
    required this.progress,
  });

  final PrintProgress progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress.status.isInProgress)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColor(),
              ),
            ),
          )
        else
          Icon(
            _getIcon(),
            size: 16,
            color: _getColor(),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            progress.displayMessage,
            style: TextStyle(
              fontSize: 13,
              color: _getColor(),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    if (progress.status.isCompleted) return Icons.check_circle;
    if (progress.status.isFailed) return Icons.error;
    return Icons.info;
  }

  Color _getColor() {
    if (progress.status.isFailed) return AppTheme.dangerColor;
    if (progress.status.isCompleted) return AppTheme.successColor;
    if (progress.status.isInProgress) return AppTheme.primaryBlue;
    return AppTheme.slate600;
  }
}

/// Print progress timeline - shows all steps in the printing process
class PrintProgressTimeline extends StatelessWidget {
  const PrintProgressTimeline({
    super.key,
    required this.currentStatus,
  });

  final PrintStatus currentStatus;

  static final List<PrintStatus> _steps = [
    PrintStatus.connecting,
    PrintStatus.sending,
    PrintStatus.printing,
    PrintStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _steps.length; i++)
          _buildTimelineStep(
            _steps[i],
            isActive: i == currentIndex,
            isCompleted: i < currentIndex,
            isLast: i == _steps.length - 1,
          ),
      ],
    );
  }

  Widget _buildTimelineStep(
    PrintStatus status, {
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isActive
                    ? AppTheme.primaryBlue
                    : AppTheme.slate300,
                border: Border.all(
                  color: isActive
                      ? AppTheme.primaryBlue
                      : AppTheme.slate400,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppTheme.primaryBlue : AppTheme.slate300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Status text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayText,
                  style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive || isCompleted
                        ? AppTheme.slate800
                        : AppTheme.slate500,
                  ),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
