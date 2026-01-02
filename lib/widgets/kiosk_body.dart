import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:worxvisitorapp/core/theme/app_theme.dart';

/// Custom Dashboard Body Widget
/// Reusable card layout for visitor pages (kiosk, sign-in, etc.)

class KioskBody extends StatelessWidget {
  const KioskBody({
    super.key,
    this.siteTitle,
    this.helpText,
    this.supervisorName,
    required this.menuContent,
    this.logo1Url,
    this.logo2Url,
    this.printerReady = false,
    this.logo1Bytes,
    this.footerAction,
    this.showSupervisorLabel = true,
    this.supervisorTextColor,
    this.quoteSupervisorName = false,
  });

  final String? siteTitle;
  final String? helpText;
  final String? supervisorName;
  final bool showSupervisorLabel;
  final Color? supervisorTextColor;
  final bool quoteSupervisorName;
  final Widget menuContent;
  final String? logo1Url;
  final String? logo2Url;
  final bool printerReady;
  final Uint8List? logo1Bytes;
  final Widget? footerAction;

  String _buildSupervisorLabel() {
    final formatted = _formatSupervisorName();
    if (formatted.isEmpty) return '';
    final name = quoteSupervisorName ? '"$formatted"' : formatted;
    return showSupervisorLabel ? 'Supervisor : $name' : name;
  }

  String _formatSupervisorName() {
    final raw = supervisorName?.trim() ?? '';
    if (raw.isEmpty) return '';
    final trimmed = raw.trim();

    // Try JSON parsing for complex formats
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          final names = decoded
              .map((entry) {
                if (entry is Map<String, dynamic>) {
                  final name =
                      entry['name'] ?? entry['full_name'] ?? entry['title'];
                  if (name != null) return name.toString();
                }
                return entry.toString();
              })
              .where((value) => value.trim().isNotEmpty)
              .toList();
          if (names.isNotEmpty) {
            return names.join(', ');
          }
        } else if (decoded is Map<String, dynamic>) {
          final name =
              decoded['name'] ??
              decoded['full_name'] ??
              decoded['title'] ??
              decoded['value'];
          if (name != null) {
            return name.toString();
          }
        }
      } catch (_) {
        // Continue to manual fallbacks
      }
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final topLogo = _buildLogo(logo1Url, 56, bytes: logo1Bytes);
    final bottomLogo = _buildLogo(logo2Url, 36);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    printerReady ? Icons.print : Icons.print_disabled,
                    color: printerReady ? AppTheme.successColor : Colors.white,
                    size: 20,
                  ),
                  Spacer(),
                  // Top logo
                  if (topLogo != null) Center(child: topLogo),
                  const SizedBox(height: 14),
                  Spacer(),
                ],
              ),
              // Site title
              if (siteTitle != null && siteTitle!.isNotEmpty) ...[
                Text(
                  siteTitle!,
                  textAlign: TextAlign.center,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],

              // Help text
              if (helpText != null && helpText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    helpText!,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(color: cs.tertiary),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 24),

              // Main content
              menuContent,

              const SizedBox(height: 24),
              const Divider(),

              // Bottom row: Supervisor info + Powered by logo
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Supervisor name (if provided)
                      if (supervisorName != null && supervisorName!.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_buildSupervisorLabel()),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.7,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cs.outline),
                              ),
                              child: Text(
                                _buildSupervisorLabel(),
                                style: tt.bodyMedium?.copyWith(
                                  color: supervisorTextColor ?? cs.tertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),

                      // Bottom logo + footer action
                      if (bottomLogo != null || footerAction != null)
                        SizedBox(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (bottomLogo != null)
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: bottomLogo,
                                    ),
                                  ),
                                ),
                              if (footerAction != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: footerAction!,
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build logo widget (SVG or PNG, network or asset)
  Widget? _buildLogo(String? url, double height, {Uint8List? bytes}) {
    if (bytes != null && bytes.isNotEmpty) {
      final snippet = String.fromCharCodes(bytes.take(64));
      final isSvg = snippet.contains('<svg') || snippet.contains('<?xml');
      return isSvg
          ? SvgPicture.memory(bytes, height: height, fit: BoxFit.contain)
          : Image.memory(bytes, height: height, fit: BoxFit.contain);
    }

    if (url == null || url.isEmpty) return null;

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
}
