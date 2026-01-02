import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:worxvisitorapp/services/helper/logo_builder.dart';

// Custom dashboard body widget - reusable card layout for visitor pages
class AuthBody extends StatelessWidget {
  const AuthBody({
    super.key,
    this.siteTitle,
    this.supervisorName,
    required this.menuContent,
    this.logo1Url,
    this.logo2Url,
    this.logo1Bytes,
  });

  final String? siteTitle;
  final String? supervisorName;
  final Widget menuContent;
  final String? logo1Url;
  final String? logo2Url;
  final Uint8List? logo1Bytes;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final topLogo = buildLogo(logo1Url, 56, bytes: logo1Bytes);
    final bottomLogo = buildLogo(logo2Url, 36);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top logo (Worx Safety logo)
              if (topLogo != null) Center(child: topLogo),
              const SizedBox(height: 14),

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
              const SizedBox(height: 16),
              // Main content (buttons, forms, etc.)
              menuContent,
              //bottom spacer
              const SizedBox(height: 24),
              const Divider(),
              if (bottomLogo != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 36,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: bottomLogo,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
