// lib/services/badge_generator.dart
//
// Generates visitor badge images for preview and printing
// Ensures the printed badge matches exactly what's shown in preview

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// Data structure for visitor badge information
class BadgeData {
  final String visitorId;  // Unique ID for QR code
  final String? fullName;
  final String? email;
  final String? phone;
  final String? workType;
  final String? company;
  final String? address;
  final String? supervisor;
  final String? signInTime;
  final String siteName;
  final Uint8List? clientLogoBytes;  // Custom client logo bytes (overrides default)
  final String? clientLogoUrl;  // Custom client logo URL (downloaded if provided)
  final Uint8List? visitorPhotoBytes;  // Visitor photo captured during sign-in

  const BadgeData({
    required this.visitorId,
    this.fullName,
    this.email,
    this.phone,
    this.workType,
    this.company,
    this.address,
    this.supervisor,
    this.signInTime,
    required this.siteName,
    this.clientLogoBytes,
    this.clientLogoUrl,
    this.visitorPhotoBytes,
  });
}

/// Service for generating visitor badge images
class BadgeGenerator {
  // ========== SVG TO PNG CONVERTER ==========

  /// Convert SVG to PNG using vector_graphics (same method as visitor project)
  static Future<Uint8List?> _convertSvgViaWidgetRender(Uint8List svgBytes, int width, int height) async {
    try {
      // Parse SVG string
      final svgString = String.fromCharCodes(svgBytes);
      final pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );
      // Calculate target dimensions to maintain aspect ratio
      var svgWidth = pictureInfo.size.width;
      var svgHeight = pictureInfo.size.height;

      if (svgWidth == 0 || svgHeight == 0) {
        svgWidth = width.toDouble();
        svgHeight = height.toDouble();
      }

      // Calculate scale to fit SVG in target size while maintaining aspect ratio
      final scaleX = width / svgWidth;
      final scaleY = height / svgHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // Calculate actual output dimensions
      final outputWidth = (svgWidth * scale).toInt();
      final outputHeight = (svgHeight * scale).toInt();

      // Create a picture recorder for the scaled SVG
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Fill with white background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        bgPaint,
      );

      // Draw SVG with scaling
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(outputWidth, outputHeight);

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Dispose resources
      pictureInfo.picture.dispose();
      image.dispose();

      return pngBytes;
    } catch (e, stackTrace) {
      debugPrint('Error converting SVG to PNG: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }

  /// Convert SVG bytes to PNG bytes using flutter_svg-based rendering.
  /// No external services or platform-specific web views required.
  static Future<Uint8List?> convertSvgToPng(
    Uint8List svgBytes, {
    int width = 800,
    int height = 400,
  }) async {
    try {
      final widgetResult = await _convertSvgViaWidgetRender(svgBytes, width, height)
          .timeout(const Duration(seconds: 8));
      if (widgetResult != null) {
        return widgetResult;
      }
    } catch (e) {
      debugPrint('Widget rendering timeout/error, falling back to direct conversion: $e');
    }
    // Fallback: Return a small transparent PNG if all conversions fail
    // This shouldn't happen in normal operation
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ========== BADGE GENERATION ==========


  // Badge dimensions (in pixels) - Portrait orientation (top to bottom)
  // Brother QL-820NWB uses 62mm width labels
  // At 300 DPI: 62mm ≈ 730 pixels
  // Portrait mode: width is the paper width, height is the feed direction
  static const double badgeWidth = 730.0;  // Paper width (62mm)
  static const double badgeHeight = 1100.0; // Base feed direction (longer)
  static const double logoDisplayHeight = 140.0;  // Reduced from 160
  static const double qrCodeSize = 420.0;  // Reduced from 600 for better aesthetics

  /// Generate a visitor badge image from badge data
  /// This image is used for BOTH preview display and printing
  /// Returns: ui.Image that can be displayed or printed
  static Future<ui.Image> generateBadgeImage(BadgeData data) async {
    /*debugPrint(
    'BADGE GENERATOR: generateBadgeImage CALLED | '
    'Visitor ID: ${data.visitorId} | '
    'Client Logo URL: ${data.clientLogoUrl ?? "NULL"} | '
    'Client Logo Bytes: ${data.clientLogoBytes != null ? "YES (${data.clientLogoBytes!.length} bytes)" : "NO (NULL)"}'
    );*/

    final double canvasHeight = _calculateCanvasHeight(data);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, badgeWidth, canvasHeight),
      bgPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(
      Rect.fromLTWH(10, 10, badgeWidth - 20, canvasHeight - 20),
      borderPaint,
    );

    double yPosition = 40;

    // Load and draw logo at top (smaller size)
    try {
      ui.Image logoImage;

      // Priority 1: Use provided logo bytes (already downloaded and converted in dashboard)
      if (data.clientLogoBytes != null) {
        logoImage = await _loadImageFromBytes(data.clientLogoBytes!);
      }
      // Priority 2: Try downloading from URL (fallback if bytes not available)
      else if (data.clientLogoUrl != null && data.clientLogoUrl!.isNotEmpty) {
        final logoBytes = await _downloadLogoFromUrl(data.clientLogoUrl!);
        if (logoBytes != null) {
          logoImage = await _loadImageFromBytes(logoBytes);
        } else {
          logoImage = await _loadAssetImage('lib/assets/images/WorxSafety_Logo_NoShadow.png');
        }
      }
      // Priority 3: Use default logo
      else {
        logoImage = await _loadAssetImage('lib/assets/images/WorxSafety_Logo_NoShadow.png');
      }

      final logoHeight = logoDisplayHeight;  // Bigger logo for clearer preview/print
      final logoWidth = logoImage.width * (logoHeight / logoImage.height);
      final logoX = (badgeWidth - logoWidth) / 2;
      /*debugPrint(
        'Logo dimensions: ${logoImage.width}x${logoImage.height} → badge: ${logoWidth.toInt()}x${logoHeight.toInt()} | '
        'Logo position: X=${logoX.toInt()}, Y=${yPosition.toInt()}, Width=${logoWidth.toInt()}, Height=${logoHeight.toInt()} | '
        'Badge Generator: Logo loaded and ready to render'
      );*/
      // Draw logo
      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        Rect.fromLTWH(logoX, yPosition, logoWidth, logoHeight),
        Paint(),
      );

      yPosition += logoHeight + 24;  // Maintain breathing room beneath larger logo
    } catch (e, stackTrace) {
      debugPrint('Error: $e  $stackTrace');
      yPosition += 20;
    }

    // Site name header (centered, bold)
    yPosition = _drawText(
      canvas,
      data.siteName,
      yPosition,
      _siteTitleStyle,
      centered: true,
    );
    yPosition += 30;

    // Visitor information fields
    if (data.fullName != null) {
      yPosition = _drawField(canvas, 'Full Name', data.fullName!, yPosition);
    }

    if (data.email != null) {
      yPosition = _drawField(canvas, 'Email', data.email!, yPosition);
    }

    if (data.phone != null) {
      yPosition = _drawField(canvas, 'Phone', data.phone!, yPosition);
    }

    if (data.workType != null) {
      yPosition = _drawField(canvas, 'Work Type', data.workType!, yPosition);
    }

    if (data.company != null) {
      yPosition = _drawField(canvas, 'Company', data.company!, yPosition);
    }

    if (data.address != null) {
      yPosition = _drawField(canvas, 'Address', data.address!, yPosition);
    }
    
    if (data.supervisor != null) {
      yPosition = _drawField(canvas, 'Person Visiting', data.supervisor!, yPosition);
    }

    if (data.signInTime != null) {
      yPosition = _drawField(canvas, 'Sign In', data.signInTime!, yPosition);
    }

    // Show photo uploaded indicator if visitor photo was captured
    if (data.visitorPhotoBytes != null) {
      yPosition = _drawField(canvas, 'Photo', 'Photo Uploaded', yPosition);
    }

    // Add some spacing before QR code
    yPosition += 40;

    // QR Code at bottom (centered)
    const double qrSize = qrCodeSize;
    try {
      final qrImage = await _generateQrCode(data.visitorId, qrSize.toInt());
      final qrX = (badgeWidth - qrSize) / 2;

      canvas.drawImageRect(
        qrImage,
        Rect.fromLTWH(0, 0, qrImage.width.toDouble(), qrImage.height.toDouble()),
        Rect.fromLTWH(qrX, yPosition, qrSize, qrSize),
        Paint(),
      );
      yPosition += qrSize + 20;

      // Visitor ID below QR code (centered, larger)
      _drawText(
        canvas,
        'ID: ${data.visitorId}',
        yPosition,
        _idTextStyle,
        centered: true,
      );
    } catch (e) {
      debugPrint('Failed to generate QR code: $e');
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(badgeWidth.toInt(), canvasHeight.toInt());
    return image;
  }

  /// Generate badge image as bytes (for widget display)
  static Future<Uint8List> generateBadgeBytes(BadgeData data) async {
    final image = await generateBadgeImage(data);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Generate QR code image
  static Future<ui.Image> _generateQrCode(String data, int size) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('QR code validation failed');
    }

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      gapless: true,
      dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), bgPaint);

    // Draw QR code
    painter.paint(canvas, Size(size.toDouble(), size.toDouble()));

    final picture = recorder.endRecording();
    return await picture.toImage(size, size);
  }

  /// Load asset image
  static Future<ui.Image> _loadAssetImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  /// Download logo from URL (with CORS proxy support for web)
  static Future<Uint8List?> _downloadLogoFromUrl(String url) async {
    try {

      // Use CORS proxy for web platform (same as dashboard)
      final fetchUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}'
          : url;

      debugPrint(kIsWeb ? 'web browser Using CORS proxy for web platform' : 'PC Direct download (native platform)');

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('Failed to download logo: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading logo: $e');
      return null;
    }
  }

  /// Load image from bytes (for client logo) - Supports PNG/JPG and SVG
  /// SVG logos are automatically converted to PNG for badge printing
  static Future<ui.Image> _loadImageFromBytes(Uint8List bytes) async {
    // Check if it's an SVG file
    final String bytesAsString = String.fromCharCodes(bytes.take(100));
    final isSvg = bytesAsString.contains('<svg') || bytesAsString.contains('<?xml');

    if (isSvg) {
      // Try to convert SVG to PNG
      final pngBytes = await convertSvgToPng(bytes, width: 800, height: 400);

      if (pngBytes != null && pngBytes.isNotEmpty) {
        // Successfully converted - ANY size is valid!
        final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        return frameInfo.image;
      } else {
        // SVG conversion failed
        debugPrint('SVG conversion returned null');
        throw Exception('SVG conversion failed');
      }
    }

    // Load PNG/JPG image
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }



  static const TextStyle _fieldLabelStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle _fieldValueStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static const TextStyle _siteTitleStyle = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle _idTextStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  /// Draw a field with label and value
  static double _drawField(Canvas canvas, String label, String value, double yPosition) {
    const leftMargin = 40.0;
    const labelWidth = 180.0;

    // Draw label (bold)
    final labelPainter = _buildTextPainter(
      '$label:',
      _fieldLabelStyle,
      maxWidth: labelWidth,
    );
    final valuePainter = _buildTextPainter(
      value,
      _fieldValueStyle,
      maxWidth: badgeWidth - leftMargin - labelWidth - 40,
    );

    labelPainter.paint(canvas, Offset(leftMargin, yPosition));
    valuePainter.paint(canvas, Offset(leftMargin + labelWidth, yPosition));

    final height = math.max(labelPainter.height, valuePainter.height);
    return yPosition + height + 18;
  }

  static TextPainter _buildTextPainter(
    String text,
    TextStyle style, {
    double maxWidth = badgeWidth - 80,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    painter.layout(maxWidth: maxWidth);
    return painter;
  }

  /// Draw centered text
  static double _drawText(
    Canvas canvas,
    String text,
    double yPosition,
    TextStyle style, {
    bool centered = false,
  }) {
    final textPainter = _buildTextPainter(
      text,
      style,
      maxWidth: badgeWidth - 80,
      align: centered ? TextAlign.center : TextAlign.left,
    );

    final xPosition = centered
        ? (badgeWidth - textPainter.width) / 2
        : 40.0;

    textPainter.paint(canvas, Offset(xPosition, yPosition));
    return yPosition + textPainter.height + 10;
  }

  static double _measureFieldHeight(String label, String value) {
    const leftMargin = 40.0;
    const labelWidth = 180.0;
    final labelHeight = _measureTextHeight(
      '$label:',
      _fieldLabelStyle,
      maxWidth: labelWidth,
    );
    final valueHeight = _measureTextHeight(
      value,
      _fieldValueStyle,
      maxWidth: badgeWidth - leftMargin - labelWidth - 40,
    );
    return math.max(labelHeight, valueHeight) + 18;
  }

  static double _measureTextHeight(
    String text,
    TextStyle style, {
    double maxWidth = badgeWidth - 80,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.height;
  }

  static double _calculateCanvasHeight(BadgeData data) {
    double yPosition = 40;
    yPosition += logoDisplayHeight + 24;

    yPosition += _measureTextHeight(
      data.siteName,
      _siteTitleStyle,
      maxWidth: badgeWidth - 80,
    );
    yPosition += 30;

    void addField(String label, String? value) {
      if (value != null && value.isNotEmpty) {
        yPosition += _measureFieldHeight(label, value);
      }
    }

    addField('Full Name', data.fullName);
    addField('Email', data.email);
    addField('Phone', data.phone);
    addField('Work Type', data.workType);
    addField('Company', data.company);
    addField('Address', data.address);
    addField('Person Visiting', data.supervisor);
    addField('Sign In', data.signInTime);

    // Add visitor photo field height if photo was captured
    if (data.visitorPhotoBytes != null) {
      addField('Photo', 'Photo Uploaded');
    }

    yPosition += 40;
    yPosition += qrCodeSize;
    yPosition += _measureTextHeight(
      'ID: ${data.visitorId}',
      _idTextStyle,
      maxWidth: badgeWidth - 80,
    );

    yPosition += 60;
    return math.max(yPosition, badgeHeight);
  }
}
