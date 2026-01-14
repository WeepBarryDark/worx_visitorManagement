import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:worxvisitorapp/services/printer_service.dart';

/// Stress test for printer service
/// Tests long-running stability, resource management, and error handling
class PrinterStressTest {
  final PrinterService printerService;

  int successCount = 0;
  int failureCount = 0;
  int totalAttempts = 0;
  final List<String> errors = [];

  PrinterStressTest(this.printerService);

  /// Simulate continuous printing for stress testing
  /// [count] - number of print jobs to execute
  /// [delayMs] - delay between each print job in milliseconds
  Future<Map<String, dynamic>> runContinuousPrintTest({
    required int count,
    int delayMs = 1000,
  }) async {
    /*
    debugPrint('========================================');
    debugPrint('STRESS TEST: Continuous Printing');
    debugPrint('Total jobs: $count');
    debugPrint('Delay between jobs: ${delayMs}ms');
    debugPrint('========================================');
    */

    final startTime = DateTime.now();

    for (int i = 0; i < count; i++) {
      totalAttempts++;
      debugPrint('\n--- Print Job $totalAttempts/$count ---');

      try {
        final image = await _createTestImage(i);

        final result = await printerService.printImage(
          image,
          onStatusUpdate: (progress) {
            debugPrint('  Status: ${progress.message}');
          },
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint('  ⚠️ Print job timeout');
            return false;
          },
        );

        // Clean up image
        image.dispose();

        if (result) {
          successCount++;
          debugPrint('  ✅ SUCCESS ($successCount/$totalAttempts)');
        } else {
          failureCount++;
          final error = printerService.errorMessage ?? 'Unknown error';
          errors.add('Job $totalAttempts: $error');
          debugPrint('  ❌ FAILED: $error ($failureCount failures)');
        }
      } catch (e, stackTrace) {
        failureCount++;
        errors.add('Job $totalAttempts: Exception - $e');
        debugPrint('  💥 EXCEPTION: $e');
        debugPrint('  Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      }

      // Memory check
      if (i % 10 == 0 && i > 0) {
        debugPrint('\n📊 Progress Report:');
        debugPrint('   Jobs completed: $i/$count');
        debugPrint('   Success: $successCount, Failed: $failureCount');
        debugPrint('   Success rate: ${((successCount / totalAttempts) * 100).toStringAsFixed(1)}%');
      }

      // Delay between jobs
      if (i < count - 1) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    final report = {
      'total_attempts': totalAttempts,
      'success_count': successCount,
      'failure_count': failureCount,
      'success_rate': (successCount / totalAttempts * 100),
      'duration_seconds': duration.inSeconds,
      'avg_time_per_job_ms': duration.inMilliseconds / totalAttempts,
      'errors': errors,
    };

    _printFinalReport(report);

    return report;
  }

  /// Test concurrent printing from multiple clients
  Future<Map<String, dynamic>> runConcurrentPrintTest({
    required int clientCount,
    required int jobsPerClient,
  }) async {
    debugPrint('========================================');
    debugPrint('STRESS TEST: Concurrent Printing');
    debugPrint('Clients: $clientCount');
    debugPrint('Jobs per client: $jobsPerClient');
    debugPrint('Total jobs: ${clientCount * jobsPerClient}');
    debugPrint('========================================');

    final startTime = DateTime.now();

    // Launch multiple concurrent clients
    final futures = List.generate(clientCount, (clientId) async {
      int clientSuccess = 0;
      int clientFailed = 0;

      for (int jobId = 0; jobId < jobsPerClient; jobId++) {
        try {
          debugPrint('Client $clientId - Job $jobId: Starting...');

          final image = await _createTestImage(jobId);

          final result = await printerService.printImage(
            image,
            onStatusUpdate: (progress) {
              debugPrint('Client $clientId - Job $jobId: ${progress.message}');
            },
          ).timeout(
            const Duration(seconds: 90), // Longer timeout for concurrent
            onTimeout: () {
              debugPrint('Client $clientId - Job $jobId: ⚠️ Timeout');
              return false;
            },
          );

          image.dispose();

          if (result) {
            clientSuccess++;
            debugPrint('Client $clientId - Job $jobId: ✅ SUCCESS');
          } else {
            clientFailed++;
            debugPrint('Client $clientId - Job $jobId: ❌ FAILED');
          }

          // Small delay between jobs from same client
          await Future.delayed(const Duration(milliseconds: 500));

        } catch (e) {
          clientFailed++;
          debugPrint('Client $clientId - Job $jobId: 💥 EXCEPTION: $e');
        }
      }

      return {
        'client_id': clientId,
        'success': clientSuccess,
        'failed': clientFailed,
      };
    });

    // Wait for all clients to finish
    final results = await Future.wait(futures);

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    int totalSuccess = 0;
    int totalFailed = 0;

    for (var result in results) {
      totalSuccess += result['success'] as int;
      totalFailed += result['failed'] as int;
    }

    final report = {
      'total_clients': clientCount,
      'jobs_per_client': jobsPerClient,
      'total_jobs': clientCount * jobsPerClient,
      'total_success': totalSuccess,
      'total_failed': totalFailed,
      'success_rate': (totalSuccess / (totalSuccess + totalFailed) * 100),
      'duration_seconds': duration.inSeconds,
      'client_results': results,
    };

    debugPrint('\n========================================');
    debugPrint('CONCURRENT TEST RESULTS');
    debugPrint('========================================');
    debugPrint('Total jobs: ${report['total_jobs']}');
    debugPrint('Success: ${report['total_success']}');
    debugPrint('Failed: ${report['total_failed']}');
    debugPrint('Success rate: ${(report['success_rate'] as double).toStringAsFixed(1)}%');
    debugPrint('Duration: ${report['duration_seconds']}s');
    debugPrint('========================================\n');

    return report;
  }

  /// Create a test image
  Future<ui.Image> _createTestImage(int jobNumber) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);

    const double width = 400;
    const double height = 200;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, height), paint);

    final textPainter = painting.TextPainter(
      text: painting.TextSpan(
        text: 'Stress Test Job #$jobNumber\n${DateTime.now()}',
        style: const painting.TextStyle(
          color: ui.Color(0xFF000000),
          fontSize: 16,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width - 40);
    textPainter.paint(canvas, const ui.Offset(20, 20));

    final picture = recorder.endRecording();
    return await picture.toImage(width.toInt(), height.toInt());
  }

  void _printFinalReport(Map<String, dynamic> report) {
    debugPrint('\n========================================');
    debugPrint('STRESS TEST FINAL REPORT');
    debugPrint('========================================');
    debugPrint('Total attempts: ${report['total_attempts']}');
    debugPrint('✅ Success: ${report['success_count']}');
    debugPrint('❌ Failed: ${report['failure_count']}');
    debugPrint('Success rate: ${(report['success_rate'] as double).toStringAsFixed(2)}%');
    debugPrint('Duration: ${report['duration_seconds']}s');
    debugPrint('Avg time/job: ${(report['avg_time_per_job_ms'] as double).toStringAsFixed(0)}ms');

    if (errors.isNotEmpty) {
      debugPrint('\n⚠️ Errors (${errors.length}):');
      for (int i = 0; i < errors.length && i < 10; i++) {
        debugPrint('  ${i + 1}. ${errors[i]}');
      }
      if (errors.length > 10) {
        debugPrint('  ... and ${errors.length - 10} more errors');
      }
    }

    debugPrint('========================================\n');
  }

  /// Reset counters
  void reset() {
    successCount = 0;
    failureCount = 0;
    totalAttempts = 0;
    errors.clear();
  }
}
