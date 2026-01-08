import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;

import 'package:another_brother/printer_info.dart' as printer;
import 'package:another_brother/label_info.dart' show QL700;
import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:worxvisitorapp/core/models/paper_type.dart';
import 'package:worxvisitorapp/core/models/print_status.dart';

/// Network printer data
class DiscoveredPrinter {
  final String name;
  final String address;
  final String model;
  final printer.PrinterInfo? printerInfo;

  DiscoveredPrinter({
    required this.name,
    required this.address,
    required this.model,
    this.printerInfo,
  });
}

/// Printer Service - network discovery and print jobs
class PrinterService {
  List<DiscoveredPrinter> discoveredPrinters = [];
  DiscoveredPrinter? selectedPrinter;
  String? errorMessage;

  /// Supported models
  static const List<String> supportedModels = [
    'QL-820NWB',
    'QL-720NW',
  ];

  /// Discover printers on local network
  Future<void> discoverPrinters() async {
    if (kIsWeb) {
      return;
    }

    discoveredPrinters.clear();
    errorMessage = null;

    try {
      // Get local IP address
      final interfaces = await NetworkInterface.list();
      debugPrint('Network interfaces found: ${interfaces.length}');

      String? localIp;

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }

      if (localIp == null) {
        errorMessage = 'Could not determine local IP address';
        debugPrint('ERROR: $errorMessage');
        return;
      }


      final subnet = localIp.substring(0, localIp.lastIndexOf('.'));

      if (Platform.isAndroid) {
        await _scanNetworkWithBrotherSDK(subnet);
      } else {
        await _scanNetworkManually(subnet);
      }

    } catch (e) {
      errorMessage = 'Error during printer discovery: $e';
      debugPrint('ERROR: $errorMessage  Stack trace: ${StackTrace.current}');
    }
  }

  /// Scan network using Brother SDK (Android)
  Future<void> _scanNetworkWithBrotherSDK(String subnet) async {
    //debugPrint('Using Brother SDK mDNS discovery...');

    try {
      final printerInstance = printer.Printer();
      final scanTimeout = const Duration(seconds: 20);

      //debugPrint('Timeout: ${scanTimeout.inSeconds} seconds');
      //debugPrint('Searching for models: $supportedModels');
      //debugPrint('');

      final netPrinters = await printerInstance
          .getNetPrinters(supportedModels)
          .timeout(
            scanTimeout,
            onTimeout: () {
              debugPrint('Network scan timed out after ${scanTimeout.inSeconds}s');
              return [];
            },
          );

      debugPrint('Network scan completed. Found ${netPrinters.length} printer(s)');

      for (var netPrinter in netPrinters) {

        final model = _detectModelFromString(netPrinter.modelName);
        if (model != null) {
          final printerInfo = printer.PrinterInfo(
            printerModel: model,
            port: printer.Port.NET,
            ipAddress: netPrinter.ipAddress,
            macAddress: netPrinter.macAddress,
          );

          final discovered = DiscoveredPrinter(
            name: netPrinter.modelName,
            address: netPrinter.ipAddress,
            model: _getModelName(model),
            printerInfo: printerInfo,
          );

          discoveredPrinters.add(discovered);
          debugPrint('  ✓ Added to list');
          await _saveDiscoveredPrinter(discovered);
        }
      }
    } catch (e) {
      debugPrint('Brother SDK scan error: $e');
      await _scanNetworkManually(subnet);
    }
  }

  /// Manual network scan with priority IPs
  Future<void> _scanNetworkManually(String subnet) async {
    // Priority IPs (most common printer addresses)
    final priorityIPs = [
      191, 192, 193, 190, 194, 195,
      100, 101, 102, 103, 104,
      200, 201, 202, 203,
      150, 151, 152,
      50, 51, 52,
      10, 11, 12,
      1,
    ];

    debugPrint('📍 Phase 1: Scanning ${priorityIPs.length} priority IPs...');

    const batchSize = 6;
    for (int i = 0; i < priorityIPs.length; i += batchSize) {
      final batch = priorityIPs.skip(i).take(batchSize);
      final batchFutures = batch.map((host) => _checkPrinterAtAddress('$subnet.$host'));
      await Future.wait(batchFutures);
      if (discoveredPrinters.isNotEmpty) {
        debugPrint('Found printer at ${discoveredPrinters.first.address}!');
        return;
      }
    }
    // Phase 2: Full subnet scan

    const fullScanBatchSize = 30;
    final allHosts = List.generate(254, (i) => i + 1)
        .where((host) => !priorityIPs.contains(host))
        .toList();

    for (int i = 0; i < allHosts.length; i += fullScanBatchSize) {
      final batch = allHosts.skip(i).take(fullScanBatchSize);
      final batchFutures = batch.map((host) => _checkPrinterAtAddress('$subnet.$host'));

      await Future.wait(batchFutures);

      if (discoveredPrinters.isNotEmpty) {
        debugPrint('Found printer, stopping scan');
        return;
      }

    }
    debugPrint('Scan complete - checked ${priorityIPs.length + allHosts.length} IPs');
  }

  /// Check printer at IP (HTTP + SDK verification)
  Future<void> _checkPrinterAtAddress(String ip) async {
    try {
      final knownBrotherIPs = ['192.168.1.191'];

      if (knownBrotherIPs.any((known) => ip.endsWith(known.split('.').last))) {
        try {
          final socket = await Socket.connect(ip, 9100, timeout: const Duration(milliseconds: 300));
          socket.destroy();

          debugPrint('Fast track: Known printer at $ip');
          final printerInfo = printer.PrinterInfo(
            printerModel: printer.Model.QL_820NWB,
            port: printer.Port.NET,
            ipAddress: ip,
          );

          final discovered = DiscoveredPrinter(
            name: 'Brother QL-820NWB at $ip',
            address: ip,
            model: 'QL-820NWB',
            printerInfo: printerInfo,
          );

          discoveredPrinters.add(discovered);
          await _saveDiscoveredPrinter(discovered);
          return;
        } catch (e) {
          debugPrint('Port not open, continue with normal verification');
        }
      }

      await _checkPrinterAtAddressInternal(ip).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          return;
        },
      );
    } catch (e) {
      return;
    }
  }

  /// Brother-specific verification
  Future<void> _checkPrinterAtAddressInternal(String ip) async {

    // Check port 9100
    Socket? socket;
    try {
      socket = await Socket.connect(
        ip,
        9100,
        timeout: const Duration(milliseconds: 200),
      );
    } catch (e) {
      debugPrint('Port 9100 closed');
      return;
    }

    try {
      socket.destroy();
    } catch (e) {
      debugPrint('socket.destroy $e');
    }

    // Check hostname pattern (BRN*/BRW*)
    try {
      final hostname = await InternetAddress(ip).reverse().timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => throw TimeoutException('DNS timeout'),
      );

      debugPrint('   Node Name: ${hostname.host}');
      final isBrotherNode = hostname.host.toUpperCase().startsWith('BRN') ||
          hostname.host.toUpperCase().startsWith('BRW');
      debugPrint('   Is Brother Node Name: $isBrotherNode');

      if (!isBrotherNode) {
        debugPrint('Does not match Brother naming pattern (BRN*/BRW*)');
      } else {
        debugPrint('Brother naming pattern detected!');
      }
    } catch (e) {
      debugPrint('Node name check skipped (${e.toString().split(':').first})');
    }

    // HTTP verification
    try {
      final modelInfo = await _queryPrinterModelViaHTTP(ip).timeout(
        const Duration(milliseconds: 400),
        onTimeout: () {
          debugPrint('⏱️ HTTP timeout (400ms)');
          return null;
        },
      );

      if (modelInfo != null) {

        final model = modelInfo['model'] ?? '';
        final manufacturer = modelInfo['manufacturer'] ?? '';

        if (manufacturer.toUpperCase().contains('BROTHER')) {
          final isSupported = supportedModels.any((m) {
            final normalized = model.toUpperCase().replaceAll('-', '');
            final supportedNormalized = m.replaceAll('-', '');
            final matches = normalized.contains(supportedNormalized);
            debugPrint('   "$normalized" contains "$supportedNormalized": $matches');
            return matches;
          });
          if (isSupported) {
            final brotherModel = _detectModelFromString(model);
            if (brotherModel != null) {
              await _addDiscoveredPrinter(ip, model, brotherModel, 'HTTP');
              return;
            } 
          } else {
            debugPrint('Model not supported (need QL-820NWB/QL-720NW)');
            return;
          }
        } else if (manufacturer.isNotEmpty) {
          debugPrint('Not a Brother printer (manufacturer: "$manufacturer")');
          return;
        } else {
          debugPrint('Manufacturer field is empty, will try SDK');
        }
      }
    } catch (e) {
      debugPrint('HTTP error: $e');
    }

    // SDK verification (fallback)
    await _verifyViaBrotherSDK(ip);
  }

  /// Brother SDK verification
  Future<void> _verifyViaBrotherSDK(String ip) async {
    for (final modelName in supportedModels) {
      final brotherModel = _detectModelFromString(modelName);

      if (brotherModel == null) {
        //debugPrint('Could not map to SDK enum');
        continue;
      }

      try {
        final testPrinterInfo = printer.PrinterInfo(
          printerModel: brotherModel,
          port: printer.Port.NET,
          ipAddress: ip,
        );

        final testPrinter = printer.Printer();
        printer.Printer.setUserPrinterInfo(testPrinterInfo);

        //debugPrint('Calling getPrinterStatus() with 400ms timeout...');
        final status = await testPrinter.getPrinterStatus().timeout(
          const Duration(milliseconds: 400),
          onTimeout: () {
            debugPrint('      ⏱️ SDK timeout after 400ms');
            throw TimeoutException('SDK timeout');
          },
        );
        final isValid = status.errorCode == printer.ErrorCode.ERROR_NONE ||
            status.errorCode.getName().contains('COVER_OPEN') ||
            status.errorCode.getName().contains('PAPER');

        if (isValid) {
          await _addDiscoveredPrinter(ip, modelName, brotherModel, 'SDK');
          return;
        }
      } catch (e) {
        debugPrint('Error: $e');
        // Not this model or timeout, try next
        continue;
      }
    }
  }

  /// Add printer to list
  Future<void> _addDiscoveredPrinter(
    String ip,
    String modelName,
    printer.Model brotherModel,
    String method,
  ) async {
    if (discoveredPrinters.any((p) => p.address == ip)) return;

    final printerInfo = printer.PrinterInfo(
      printerModel: brotherModel,
      port: printer.Port.NET,
      ipAddress: ip,
    );

    final discovered = DiscoveredPrinter(
      name: 'Brother $modelName at $ip',
      address: ip,
      model: modelName,
      printerInfo: printerInfo,
    );

    discoveredPrinters.add(discovered);
    await _saveDiscoveredPrinter(discovered);
  }

  /// Query model via HTTP
  Future<Map<String, String>?> _queryPrinterModelViaHTTP(String ip) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 300);

      final endpoints = [
        '/general/information.html',
        '/',
      ];

      for (final endpoint in endpoints) {
        try {
          final request = await client.getUrl(Uri.parse('http://$ip$endpoint'));
          final response = await request.close().timeout(const Duration(milliseconds: 400));

          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();

            final hasBrother = responseBody.toUpperCase().contains('BROTHER');

            final modelMatch = RegExp(r'QL-?[0-9]{3}[A-Z]*', caseSensitive: false)
                .firstMatch(responseBody);

            if (modelMatch != null) {
              final model = modelMatch.group(0)!.toUpperCase();

              String manufacturer = 'Unknown';
              if (hasBrother) {
                manufacturer = 'Brother';
              } else {
                final mfgMatch = RegExp(
                  r'(?:Manufacturer|Vendor|Brand)[^:]*:\s*([A-Za-z]+)',
                  caseSensitive: false
                ).firstMatch(responseBody);
                if (mfgMatch != null) {
                  manufacturer = mfgMatch.group(1)!;
                }
              }

              final serialMatch = RegExp(
                r'Serial[^:]*:\s*([A-Z0-9]+)',
                caseSensitive: false
              ).firstMatch(responseBody);

              return {
                'model': model,
                'manufacturer': manufacturer,
                'serial': serialMatch?.group(1) ?? 'Unknown',
              };
            }

            if (responseBody.contains('HP') ||
                responseBody.contains('Canon') ||
                responseBody.contains('Epson') ||
                responseBody.contains('Lexmark')) {
              return {
                'model': 'Non-Brother',
                'manufacturer': 'Other',
                'serial': 'N/A',
              };
            }
          }
        } catch (e) {
          continue;
        }
      }

      client.close();
    } catch (e) {
      debugPrint('error $e');
    }
    return null;
  }

  /// Detect model from string
  printer.Model? _detectModelFromString(String modelName) {
    final normalized = modelName.toUpperCase().replaceAll('-', '_').replaceAll(' ', '');

    if (normalized.contains('QL_820') ||
        normalized.contains('QL820') ||
        normalized.contains('820NWB')) {
      return printer.Model.QL_820NWB;
    }

    if (normalized.contains('QL_720') ||
        normalized.contains('QL720') ||
        normalized.contains('720NW')) {
      return printer.Model.QL_720NW;
    }

    debugPrint('Unsupported model: $modelName');
    return null;
  }

  /// Get model name from enum
  String _getModelName(printer.Model model) {
    if (model == printer.Model.QL_820NWB) {
      return 'QL-820NWB';
    } else if (model == printer.Model.QL_720NW) {
      return 'QL-720NW';
    } else {
      return 'Unknown';
    }
  }

  /// Select printer
  void selectPrinter(DiscoveredPrinter printer) {
    selectedPrinter = printer;
    //debugPrint('Selected printer: ${printer.name} at ${printer.address}');
    
  }

  /// Add printer manually with validation
  Future<bool> addManualPrinter(String ipAddress) async {
    errorMessage = null;
    if (!_isValidIPAddress(ipAddress)) {
      errorMessage = 'Invalid IP address format';
      debugPrint('Error: $errorMessage');
      return false;
    }

    try {
      final socket = await Socket.connect(
        ipAddress,
        9100,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
    } catch (e) {
      errorMessage = 'No printer at this IP';
      debugPrint('Error: $errorMessage');
      return false;
    }

    final modelInfo = await _queryPrinterModelViaHTTP(ipAddress).timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );

    if (modelInfo != null) {
      final manufacturer = modelInfo['manufacturer'] ?? '';
      final model = modelInfo['model'] ?? '';

      if (!manufacturer.toUpperCase().contains('BROTHER')) {
        errorMessage = 'Not a Brother printer';
        debugPrint('Error: $errorMessage');
        return false;
      }

      final isSupported = supportedModels.any((m) =>
        model.toUpperCase().replaceAll('-', '').contains(m.replaceAll('-', ''))
      );

      if (!isSupported) {
        errorMessage = 'Model not supported. Need QL-820NWB or QL-720NW';
        debugPrint('Error: $errorMessage (found: $model)');
        return false;
      }

      final brotherModel = _detectModelFromString(model);
      if (brotherModel != null) {
        await _addDiscoveredPrinter(ipAddress, model, brotherModel, 'Manual');
        debugPrint('✓ Printer added: $model at $ipAddress');
        return true;
      }
    }

    debugPrint('Trying SDK verification...');
    for (final modelName in supportedModels) {
      final brotherModel = _detectModelFromString(modelName);
      if (brotherModel == null) continue;

      try {
        final testPrinterInfo = printer.PrinterInfo(
          printerModel: brotherModel,
          port: printer.Port.NET,
          ipAddress: ipAddress,
        );

        final testPrinter = printer.Printer();
        printer.Printer.setUserPrinterInfo(testPrinterInfo);

        final status = await testPrinter.getPrinterStatus().timeout(
          const Duration(seconds: 3),
        );

        final isValid = status.errorCode == printer.ErrorCode.ERROR_NONE ||
            status.errorCode.getName().contains('COVER_OPEN') ||
            status.errorCode.getName().contains('PAPER');

        if (isValid) {
          await _addDiscoveredPrinter(ipAddress, modelName, brotherModel, 'Manual');
          debugPrint('✓ Printer added: $modelName at $ipAddress');
          return true;
        }
      } catch (e) {
        continue;
      }
    }

    errorMessage = 'Could not verify printer model';
    debugPrint('Error: $errorMessage');
    return false;
  }

  /// Validate IP format
  bool _isValidIPAddress(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }

    return true;
  }

  /// Set printer by IP (no validation)
  void setManualPrinter({
    required String ipAddress,
    String model = 'QL-820NWB',
  }) {
    printer.Model brotherModel;
    if (model.contains('820')) {
      brotherModel = printer.Model.QL_820NWB;
    } else if (model.contains('720')) {
      brotherModel = printer.Model.QL_720NW;
    } else {
      brotherModel = printer.Model.QL_820NWB;
    }

    final printerInfo = printer.PrinterInfo(
      printerModel: brotherModel,
      port: printer.Port.NET,
      ipAddress: ipAddress,
    );

    selectedPrinter = DiscoveredPrinter(
      name: 'Brother $model at $ipAddress',
      address: ipAddress,
      model: model,
      printerInfo: printerInfo,
    );

  }

  /// Save printer for quick reconnection
  Future<void> _saveDiscoveredPrinter(DiscoveredPrinter printer) async {
    await SecureStorageService.saveLastPrinter(
      name: printer.name,
      address: printer.address,
      model: printer.model,
    );
  }

  /// Try saved printer (quick reconnect)
  Future<bool> tryConnectToSavedPrinter() async {
    try {
      final savedPrinter = await SecureStorageService.getLastPrinter();
      if (savedPrinter == null) {
        debugPrint('No saved printer, will scan');
        return false;
      }

      final name = savedPrinter['name']?.toString() ?? 'Saved Brother Printer';
      final address = savedPrinter['address']?.toString() ?? '';
      final modelName = savedPrinter['model']?.toString() ?? 'QL-820NWB';

      if (address.isEmpty) {
        await SecureStorageService.clearLastPrinter();
        return false;
      }

      final brotherModel = _detectModelFromString(modelName) ?? printer.Model.QL_820NWB;
      final printerInfo = printer.PrinterInfo(
        printerModel: brotherModel,
        port: printer.Port.NET,
        ipAddress: address,
      );

      selectedPrinter = DiscoveredPrinter(
        name: name,
        address: address,
        model: _getModelName(brotherModel),
        printerInfo: printerInfo,
      );
      final ok = await testPrinterConnection();
      if (ok) {
        return true;
      }
      await SecureStorageService.clearLastPrinter();
      selectedPrinter = null;
      return false;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  /// Test connection
  Future<bool> testPrinterConnection() async {
    if (selectedPrinter == null) {
      errorMessage = 'No printer selected';
      return false;
    }

    final ip = selectedPrinter!.address;

    try {
      final socket = await Socket.connect(
        ip,
        9100,
        timeout: const Duration(seconds: 5),
      );

      await socket.close();
      return true;
    } catch (e) {
      errorMessage = 'Connection test failed: $e';
      return false;
    }
  }

  /// Auto-detect paper type from printer
  /// Returns the detected PaperType, or null if detection fails
  Future<PaperType?> detectPaperType() async {
    if (selectedPrinter?.printerInfo == null) {
      debugPrint('Cannot detect paper type: No printer selected');
      return null;
    }

    try {
      final printerInstance = printer.Printer();
      printer.Printer.setUserPrinterInfo(selectedPrinter!.printerInfo!);

      final status = await printerInstance.getPrinterStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Paper type detection timeout');
          throw TimeoutException('Detection timeout');
        },
      );

      // Check for errors first
      if (status.errorCode != printer.ErrorCode.ERROR_NONE) {
        debugPrint('Printer error during detection: ${status.errorCode.getName()}');
        return null;
      }

      // Get label information
      final labelId = status.labelId;
      final labelType = status.labelType;
      final labelColor = status.labelColor;

      debugPrint('===== PAPER DETECTION DEBUG =====');
      debugPrint('labelId: $labelId');
      debugPrint('labelType: $labelType');
      debugPrint('labelColor: $labelColor');

      // Determine if it's special tape (Red/Black) based on labelColor
      // LabelColor enum values (from Brother SDK):
      // - White = standard Black/White tape (DK-22205)
      // - Other = Red/Black tape (DK-22251)
      // - RedWhite = Red/Black tape
      bool isSpecialTape = false;
      final colorName = labelColor.getName();
      debugPrint('labelColor.getName(): $colorName');

      // Check if it's a special (Red/Black) tape
      // If color contains "Other" or "Red" -> Red/Black tape (DK-22251)
      // If color contains "White" only -> Black/White tape (DK-22205)
      if (colorName.contains('Other') || colorName.contains('Red')) {
        isSpecialTape = true;
      } else if (colorName.contains('White')) {
        isSpecialTape = false;
      } else {
        // Unknown color, default to Black/White
        debugPrint('WARNING: Unknown color "$colorName", defaulting to Black/White');
        isSpecialTape = false;
      }

      debugPrint('Is special tape (Red/Black): $isSpecialTape');
      

      // Map labelId to labelNameIndex
      // For DK-22205 and DK-22251, both use labelNameIndex 17 (62mm continuous)
      int labelNameIndex = labelId; // Default to 62mm continuous

      debugPrint('Using labelNameIndex: $labelNameIndex');

      // Find matching paper type
      final detectedType = PaperType.supportedTypes.firstWhere(
        (type) => type.labelNameIndex == labelNameIndex &&
                  type.isSpecialTape == isSpecialTape,
        orElse: () {
          debugPrint('WARNING: No exact match found, using default type');
          return PaperType.defaultType;
        },
      );

      debugPrint('Auto-detected paper type: ${detectedType.name}');
      debugPrint('================================');

      // Save the detected paper type
      final paperTypeJson = jsonEncode(detectedType.toJson());
      await SecureStorageService.savePaperType(paperTypeJson);

      return detectedType;
    } catch (e) {
      debugPrint('Error detecting paper type: $e');
      return null;
    }
  }

  /// Print image with optional status callback
  Future<bool> printImage(
    dynamic image, {
    void Function(PrintProgress)? onStatusUpdate,
  }) async {
    if (image is! ui.Image) {
      errorMessage = 'Invalid image format';
      onStatusUpdate?.call(PrintProgress.failed('Invalid image format'));
      return false;
    }

    if (selectedPrinter == null) {
      errorMessage = 'No printer selected';
      onStatusUpdate?.call(PrintProgress.failed('No printer selected'));
      return false;
    }

    try {
      if (kIsWeb) {
        //Web printing not implemented'
        onStatusUpdate?.call(PrintProgress.failed('Web printing not supported'));
        return false;
      } else {
        return await _printMobile(image, onStatusUpdate: onStatusUpdate);
      }
    } catch (e) {
      errorMessage = 'Print failed: $e';
      debugPrint('Print error: $e');
      onStatusUpdate?.call(PrintProgress.failed('Print failed: $e'));
      return false;
    }
  }

  /// Print using Brother SDK with status updates
  Future<bool> _printMobile(
    ui.Image image, {
    void Function(PrintProgress)? onStatusUpdate,
  }) async {
    if (selectedPrinter?.printerInfo == null) {
      errorMessage = 'Printer info not available';
      onStatusUpdate?.call(PrintProgress.failed('Printer info not available'));
      return false;
    }

    try {
      // Status: Connecting
      onStatusUpdate?.call(PrintProgress.connecting());
      await Future.delayed(const Duration(milliseconds: 300));

      final printerInfo = selectedPrinter!.printerInfo!;

      // Get saved paper type or use default
      int labelNameIndex = 17; // Default: 62mm continuous
      bool isSpecialTape = false; // Default: Black/White

      final savedPaperTypeJson = await SecureStorageService.getPaperType();
      if (savedPaperTypeJson != null) {
        try {
          final paperTypeData = jsonDecode(savedPaperTypeJson) as Map<String, dynamic>;
          final paperType = PaperType.fromJson(paperTypeData);
          labelNameIndex = paperType.labelNameIndex;
          isSpecialTape = paperType.isSpecialTape;
          debugPrint('Using saved paper type: ${paperType.name}');
        } catch (e) {
          debugPrint('Error parsing paper type, using defaults: $e');
        }
      }

      debugPrint('===== PRINT JOB CONFIGURATION =====');
      debugPrint('labelNameIndex: $labelNameIndex');
      debugPrint('isSpecialTape: $isSpecialTape (${isSpecialTape ? "Red/Black" : "Black/White"})');

      // Status: Preparing print job
      onStatusUpdate?.call(PrintProgress.sending());

      printerInfo.paperSize = printer.PaperSize.CUSTOM;
      printerInfo.orientation = printer.Orientation.PORTRAIT;
      printerInfo.isAutoCut = true;
      printerInfo.isCutAtEnd = true;
      printerInfo.printMode = printer.PrintMode.FIT_TO_PAGE;
      printerInfo.halftone = printer.Halftone.ERRORDIFFUSION;

      // SOLUTION: Use QL700 enum directly to force correct label type
      // Using .index to get the ordinal value of the enum

      printerInfo.skipStatusCheck = false;

      // Force specific label name using QL700 enum
      if (isSpecialTape) {
        // DK-22251: Red/Black 62mm continuous
        final labelIndex = QL700.ordinalFromID(QL700.W62RB.getId());
        printerInfo.labelNameIndex = labelIndex;
        printerInfo.isSpecialTape = true;
        debugPrint('Using QL700.W62RB (Red/Black mode) - labelNameIndex: $labelIndex');
      } else {
        // DK-22205: Black/White 62mm continuous
        final labelIndex = QL700.ordinalFromID(QL700.W62.getId());
        printerInfo.labelNameIndex = labelIndex;
        printerInfo.isSpecialTape = false;
        debugPrint('Using QL700.W62 (Monochrome mode) - labelNameIndex: $labelIndex');
      }

      printerInfo.workPath = '';

      debugPrint('PrinterInfo configured successfully');

      final printerInstance = printer.Printer();
      printer.Printer.setUserPrinterInfo(printerInfo);

      // Get current printer status before printing
      try {
        final currentStatus = await printerInstance.getPrinterStatus().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Status check timeout'),
        );
        debugPrint('Current printer status:');
        debugPrint('  errorCode: ${currentStatus.errorCode.getName()}');
        debugPrint('  labelId: ${currentStatus.labelId}');
        debugPrint('  labelType: ${currentStatus.labelType}');
        debugPrint('  labelColor: ${currentStatus.labelColor?.getName()}');
      } catch (e) {
        debugPrint('Could not get current status: $e');
      }

      await Future.delayed(const Duration(milliseconds: 300));

      // Status: Sending to printer
      onStatusUpdate?.call(PrintProgress.printing());

      debugPrint('Sending print job to printer...');
      final printResult = await printerInstance.printImage(image).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Print operation timeout after 30 seconds');
        },
      );

      debugPrint('Print result errorCode: ${printResult.errorCode.getName()}');

      if (printResult.errorCode != printer.ErrorCode.ERROR_NONE) {
        errorMessage = 'Print error: ${printResult.errorCode.getName()}';
        debugPrint('===== PRINT FAILED =====');
        debugPrint('Error: $errorMessage');
        debugPrint('Possible causes:');
        debugPrint('  1. Wrong paper type selected (labelNameIndex mismatch)');
        debugPrint('  2. Wrong color mode (isSpecialTape mismatch)');
        debugPrint('  3. Paper not loaded correctly');
        debugPrint('  4. Paper cover open');
        debugPrint('=======================');
        onStatusUpdate?.call(PrintProgress.failed(errorMessage!));
        return false;
      }

      debugPrint('===== PRINT SUCCESS =====');

      // Status: Completed
      onStatusUpdate?.call(PrintProgress.completed());
      return true;
    } catch (e) {
      debugPrint(' Print error: $e');
      errorMessage = 'Print error: $e';
      onStatusUpdate?.call(PrintProgress.failed(errorMessage!));
      return false;
    }
  }

  /// Print badge (legacy - use printImage)
  Future<bool> printBadge(List<int> imageBytes) async {
    if (kIsWeb) {
      //Web print dialog
      return true;
    }
    if (selectedPrinter == null) {
      debugPrint('No printer selected');
      return false;
    }
    debugPrint('Deprecated: use printImage');
    return false;
  }

  /// Cleanup
  void dispose() {
    discoveredPrinters.clear();
    selectedPrinter = null;
  }

  /// Simple test print (text-based) to verify connection and paper type
  Future<bool> printTestLabel() async {
    if (kIsWeb) {
      errorMessage = 'Web printing not supported';
      return false;
    }
    if (selectedPrinter?.printerInfo == null) {
      errorMessage = 'No printer selected';
      return false;
    }

    ui.Image? image;
    try {
      // Build a small placeholder image as test content
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..color = ui.Color(0xFFFFFFFF);
      const double width = 400;
      const double height = 200;
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, height), paint);

      final textPainter = painting.TextPainter(
        text: painting.TextSpan(
          text: 'Test print\n Paper type verification successful.',
          style: painting.TextStyle(color: ui.Color(0xFF000000), fontSize: 18),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - 40);
      textPainter.paint(canvas, ui.Offset(20, 20));

      final picture = recorder.endRecording();
      image = await picture.toImage(width.toInt(), height.toInt());

      final result = await _printMobile(
        image,
        onStatusUpdate: (progress) {
          debugPrint('Test print status: ${progress.message}');
        },
      );

      // Dispose image to free resources
      image.dispose();

      return result;
    } catch (e, stackTrace) {
      errorMessage = 'Test print failed: $e';
      debugPrint(errorMessage);
      debugPrint('Stack trace: $stackTrace');

      // Ensure image is disposed even if error occurs
      image?.dispose();

      return false;
    }
  }
}
