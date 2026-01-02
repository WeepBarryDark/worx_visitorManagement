import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Helper function to build logo widgets (SVG or PNG, network or asset)
Widget? buildLogo(String? url, double height, {Uint8List? bytes}) {
  if (bytes != null && bytes.isNotEmpty) {
    final snippet = String.fromCharCodes(bytes.take(64));
    final isSvg = snippet.contains('<svg') || snippet.contains('<?xml');
    return isSvg
        ? SvgPicture.memory(bytes, height: height, fit: BoxFit.contain)
        : Image.memory(bytes, height: height, fit: BoxFit.contain);
  }

  if (url == null || url.isEmpty) return null;

  // Check if it's a network image
  final isNetwork = url.startsWith('http://') || url.startsWith('https://');
  final isSvg = url.toLowerCase().endsWith('.svg');

  if (isSvg) {
    return isNetwork
        ? SvgPicture.network(url, height: height, fit: BoxFit.contain)
        : SvgPicture.asset(url, height: height, fit: BoxFit.contain);
  } else {
    return isNetwork
        ? Image.network(url, height: height, fit: BoxFit.contain)
        : Image.asset(url, height: height, fit: BoxFit.contain);
  }
}
