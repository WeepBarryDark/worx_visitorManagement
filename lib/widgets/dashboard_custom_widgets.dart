import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../core/theme/app_theme.dart';
import '../core/constants/app_routes.dart';
import '../features/dashboard/controllers/dashboard_controller.dart';

/// Key-Value pair widget for displaying information rows
class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: AppTheme.slate600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Printer Status Card
class PrintStatusCard extends StatefulWidget {
  const PrintStatusCard({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<PrintStatusCard> createState() => _PrintStatusCardState();
}

class _PrintStatusCardState extends State<PrintStatusCard> {
  final TextEditingController _ipController = TextEditingController();
  bool _isAddingManualPrinter = false;
  bool _showManualInput = false;
  String? _manualInputError;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _addManualPrinter() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() {
        _manualInputError = 'Please enter an IP address';
      });
      return;
    }

    setState(() {
      _isAddingManualPrinter = true;
      _manualInputError = null;
    });

    final success = await widget.controller.printerService.addManualPrinter(ip);

    if (!mounted) return;

    setState(() {
      _isAddingManualPrinter = false;
    });

    if (success) {
      // Success - printer added
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printer added successfully: $ip'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Select the printer and update controller
      if (widget.controller.printerService.discoveredPrinters.isNotEmpty) {
        final printer =
            widget.controller.printerService.discoveredPrinters.last;
        widget.controller.printerService.selectPrinter(printer);
        widget.controller.updatePrinterConnection(
          printer.name,
          printer.address,
          true,
        );
      }

      // Clear input and hide form
      _ipController.clear();
      setState(() {
        _showManualInput = false;
        _manualInputError = null;
      });
    } else {
      // Failed - show error
      final errorMsg =
          widget.controller.printerService.errorMessage ??
          'Failed to add printer';
      setState(() {
        _manualInputError = errorMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final c = widget.controller;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Printer Status', style: tt.titleMedium)),
                // Show different status based on connection state
                if (!c.hasAttemptedConnection)
                  // Still connecting - show loading indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else if (c.initialized)
                  // Connected successfully
                  Text(
                    '● Connected',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                else
                  // Connection failed
                  Text(
                    '○ Not Connected',
                    style: TextStyle(
                      color: AppTheme.slate400,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            KeyValue('Initialized', c.initialized ? 'Yes' : 'No'),
            KeyValue('Printer', c.printerName),
            KeyValue('IP Address', c.printerIp),

            // Show retry button when connection fails (always show button after first attempt)
            if (!c.initialized && c.hasAttemptedConnection && !kIsWeb) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await c.retryPrinterConnection();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry Connection'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showManualInput = !_showManualInput;
                          _manualInputError = null;
                        });
                      },
                      icon: Icon(
                        _showManualInput ? Icons.close : Icons.edit,
                        size: 18,
                      ),
                      label: Text(_showManualInput ? 'Cancel' : 'Manual IP'),
                    ),
                  ),
                ],
              ),
            ],

            // Manual IP input section
            if (_showManualInput && !c.initialized && !kIsWeb) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.statusBackgroundColor('info'),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_ethernet,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Printer Manually',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.slate800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the IP address of your Brother printer (e.g., 192.168.1.100)',
                      style: TextStyle(fontSize: 13, color: AppTheme.slate700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ipController,
                      enabled: !_isAddingManualPrinter,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Printer IP Address',
                        hintText: '192.168.1.100',
                        prefixIcon: const Icon(Icons.computer),
                        errorText: _manualInputError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isAddingManualPrinter
                          ? null
                          : _addManualPrinter,
                      icon: _isAddingManualPrinter
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.add, size: 18),
                      label: Text(
                        _isAddingManualPrinter
                            ? 'Adding Printer...'
                            : 'Add Printer',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Show detailed explanation ONLY after manual retry fails
            if (!c.initialized &&
                c.hasAttemptedConnection &&
                c.hasManuallyRetried &&
                !kIsWeb &&
                !_showManualInput) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.statusBackgroundColor('warning'),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.warningColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No Printer Found',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.slate800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No Brother printers were found on the network. '
                      'Please check:\n'
                      '• Printer is powered on and ready\n'
                      '• Printer and device are on same WiFi network\n'
                      '• Printer IP address is accessible\n'
                      '• WiFi network allows device communication\n\n'
                      'Try using "Manual IP" to add your printer directly.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.slate700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Print badge toggle (always show)
            const SizedBox(height: 16),
            SwitchListTile(
              value: c.printVisitorBadge,
              onChanged: c.setPrintVisitorBadge,
              title: const Text('Auto-print visitor badges'),
              subtitle: const Text('Print badge when visitor signs in'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

/// Visitor Requirement Fields Card
class VisitorRequirementFieldsCard extends StatelessWidget {
  const VisitorRequirementFieldsCard({
    super.key,
    required this.controller,
    required this.isLoadingContacts,
    this.contactsError,
    required this.loadVisitorContacts,
    required this.onRequirementChange,
  });

  final DashboardController controller;
  final bool isLoadingContacts;
  final String? contactsError;
  final Future<void> Function({bool forceApiFetch}) loadVisitorContacts;
  final void Function(void Function(bool) setter, bool value)
  onRequirementChange;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final c = controller;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Visitor Required Fields', style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Select which fields visitors must fill out when checking in',
              style: tt.bodySmall?.copyWith(color: AppTheme.slate600),
            ),
            const SizedBox(height: 16),

            // Required Fields Checkboxes
            CheckboxListTile(
              value: c.reqFullName,
              onChanged: null, // Name is always required, cannot be disabled
              title: const Text('Full name (required)'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: c.reqEmail,
              onChanged: null, // Email is always required, cannot be disabled
              title: const Text('Email address (required)'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: c.reqPhone,
              onChanged: (v) => onRequirementChange(c.setReqPhone, v ?? false),
              title: const Text('Phone number'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: c.reqWorkType,
              onChanged: (v) =>
                  onRequirementChange(c.setReqWorkType, v ?? false),
              title: const Text('Work type'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: c.reqCompany,
              onChanged: (v) =>
                  onRequirementChange(c.setReqCompany, v ?? false),
              title: const Text('Company name'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: c.reqAddress,
              onChanged: (v) =>
                  onRequirementChange(c.setReqAddress, v ?? false),
              title: const Text('Address'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: c.reqSupervisor,
              onChanged: (v) async {
                final newValue = v ?? false;
                onRequirementChange(c.setReqSupervisor, newValue);
                if (newValue) {
                  await loadVisitorContacts(forceApiFetch: true);
                }
              },
              title: const Text('Person Visiting'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (c.reqSupervisor && isLoadingContacts)
              Padding(
                padding: const EdgeInsets.only(left: 44, bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading visitor contacts...',
                      style: TextStyle(color: AppTheme.slate600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (c.reqSupervisor && contactsError != null)
              Padding(
                padding: const EdgeInsets.only(left: 44, bottom: 8),
                child: Text(
                  'Contacts error: $contactsError',
                  style: TextStyle(color: AppTheme.dangerColor, fontSize: 12),
                ),
              ),
            CheckboxListTile(
              value: c.reqSignInTime,
              onChanged: (v) =>
                  onRequirementChange(c.setReqSignInTime, v ?? false),
              title: const Text('Sign in time'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                c.generatePreview();
              },
              child: const Text('Preview Visitor Badge'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge Preview Card
class BadgePreviewCard extends StatelessWidget {
  const BadgePreviewCard({
    super.key,
    required this.controller,
    required this.onNotificationChange,
  });

  final DashboardController controller;
  final void Function(void Function(bool) setter, bool value)
  onNotificationChange;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final c = controller;

    if (!c.showPreview) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Visitor Badge Preview', style: tt.titleMedium),
            const SizedBox(height: 16),

            // Preview image (actual print output)
            if (c.previewImageBytes != null)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant, width: 2),
                    ),
                    child: Image.memory(
                      c.previewImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notification Settings', style: tt.titleMedium),
                  const SizedBox(height: 8),
                  if (c.reqSupervisor) ...[
                    Text(
                      'Person Visiting',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CheckboxListTile(
                      value: c.notifyVisitorSms,
                      onChanged: (v) => onNotificationChange(
                        c.setNotifyVisitorSms,
                        v ?? false,
                      ),
                      title: const Text('SMS text'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),
                    CheckboxListTile(
                      value: c.notifyVisitorEmail,
                      onChanged: (v) => onNotificationChange(
                        c.setNotifyVisitorEmail,
                        v ?? false,
                      ),
                      title: const Text('Email'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Delivery - Notify Site Supervisor',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  CheckboxListTile(
                    value: c.notifyDeliverySms,
                    onChanged: (v) => onNotificationChange(
                      c.setNotifyDeliverySms,
                      v ?? false,
                    ),
                    title: const Text('SMS text'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  CheckboxListTile(
                    value: c.notifyDeliveryEmail,
                    onChanged: (v) => onNotificationChange(
                      c.setNotifyDeliveryEmail,
                      v ?? false,
                    ),
                    title: const Text('Email'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Confirm button - Navigate to kiosk
            FilledButton.icon(
              onPressed: () async {
                // Validate printer status if printing is enabled
                if (c.printVisitorBadge && !c.initialized) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Error: Printer is not connected. Please connect a printer or disable "Auto-print visitor badges" option.',
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  return;
                }

                // Navigate to visitor kiosk page with settings
                Navigator.pushNamed(
                  context,
                  AppRoutes.visitorKiosk,
                  arguments: c,
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
