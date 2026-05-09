// lib/screens/Dashboards/Admin_Dashboards/Services/service_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Services/assign_technician_screen.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Services/service_visit_screen.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceRequestModel service;
  final bool isAdmin;
  const ServiceDetailScreen({
    super.key,
    required this.service,
    this.isAdmin = false,
  });
  @override
  State<ServiceDetailScreen> createState() => _State();
}

class _State extends State<ServiceDetailScreen> {
  late ServiceRequestModel _service;
  final _amountCtrl = TextEditingController();
  String _payMode = 'Cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open':
        return Colors.grey;
      case 'Assigned':
        return AppColors.primary;
      case 'In Progress':
        return AppColors.solar;
      case 'Completed':
      case 'Resolved':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String? get _serviceNote {
    final note = _service.serviceNotes?.trim();
    if (note == null || note.isEmpty) return null;
    return note;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _saving = true);
    try {
      await context.read<ServiceLeadCubit>().updateService(_service.id, {
        'status': newStatus,
      });
      setState(() {
        _service.status = newStatus;
        _saving = false;
      });
      if (mounted) {
        AppFeedback.showSuccess(context, 'Status updated to $newStatus');
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPayment() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      AppFeedback.showInfo(context, 'Enter valid amount');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ServiceLeadCubit>().addPayment(
        _service.id,
        amount,
        _payMode,
      );
      _amountCtrl.clear();
      setState(() => _saving = false);
      if (mounted) {
        Navigator.pop(context);
        AppFeedback.showSuccess(context, 'Payment added');
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiceLeadCubit, ServiceLeadState>(
      listener: (ctx, state) {
        if (state is ServiceLeadError) {
          AppFeedback.showError(ctx, state.message);
        }
        if (state is ServiceLeadsLoaded) {
          final updated = state.services
              .where((s) => s.id == _service.id)
              .toList();
          if (updated.isNotEmpty) {
            setState(() {
              _service = updated.first;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor:  AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.chevronLeft,
              color: AppColors.textDark,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _service.serviceId.isNotEmpty
                    ? _service.serviceId
                    : 'Service Detail',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                _service.customerName,
                style: const TextStyle(fontSize: 11, color: AppColors.textGray),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(_service.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _statusColor(_service.status).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _service.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(_service.status),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 40),
          child: Column(
            children: [
              // ── Customer Info ─────────────────────────────────────────
              _Card(
                title: 'Customer Info',
                icon: AppSvgAssets.userRound,
                children: [
                  _Row(AppSvgAssets.userRound, 'Name', _service.customerName),
                  _Row(AppSvgAssets.phone, 'Phone', _service.phone),
                  _Row(AppSvgAssets.mapPin, 'Address', _service.address),
                ],
              ),

              // ── Issue Details ─────────────────────────────────────────
              _Card(
                title: 'Issue Details',
                icon: AppSvgAssets.triangleAlert,
                children: [
                  if (_service.issueType?.isNotEmpty == true)
                    _Row(
                      AppSvgAssets.clipboardList,
                      'Type',
                      _service.issueType!,
                    ),
                  if (_service.issueDescription?.isNotEmpty == true)
                    _Row(
                      AppSvgAssets.fileText,
                      'Description',
                      _service.issueDescription!,
                    ),
                  _Row(
                    AppSvgAssets.triangleAlert,
                    'Priority',
                    _service.priority,
                  ),
                  _Row(
                    AppSvgAssets.clipboardList,
                    'Charge',
                    _service.chargeType,
                  ),
                  if (_service.isPaid)
                    _Row(
                      AppSvgAssets.indianRupee,
                      'Amount',
                      '₹${_service.amount.toStringAsFixed(0)}',
                    ),
                ],
              ),

              // ── Assignment ────────────────────────────────────────────
              _Card(
                title: 'Assignment',
                icon: AppSvgAssets.userRound,
                children: [
                  _Row(
                    AppSvgAssets.cog,
                    'Technician',
                    _service.assignedToName ?? 'Not assigned',
                  ),
                  if (_service.assignedToPhone != null)
                    _Row(
                      AppSvgAssets.phone,
                      'Tech Phone',
                      _service.assignedToPhone!,
                    ),
                  if (_service.serviceDate != null)
                    _Row(
                      AppSvgAssets.calendarDays,
                      'Service Date & Time',
                      '${_fmtDate(_service.serviceDate!)} ${_fmtTime(_service.serviceDate!)}',
                    ),
                  if (_serviceNote != null) ...[
                    const SizedBox(height: 8),
                    _NotePanel(text: _serviceNote!),
                  ],
                ],
              ),

              // ── Payment (if paid) ─────────────────────────────────────
              if (_service.isPaid)
                _Card(
                  title: 'Payment',
                  icon: AppSvgAssets.indianRupee,
                  children: [
                    _Row(
                      AppSvgAssets.indianRupee,
                      'Total',
                      '₹${_service.amount.toStringAsFixed(0)}',
                    ),
                    _Row(
                      AppSvgAssets.circleCheckBig,
                      'Paid',
                      '₹${_service.paidAmount.toStringAsFixed(0)}',
                    ),
                    _Row(
                      AppSvgAssets.clock,
                      'Remaining',
                      '₹${_service.remaining.toStringAsFixed(0)}',
                    ),
                    if (_service.paymentStatus != null)
                      _Row(
                        AppSvgAssets.triangleAlert,
                        'Status',
                        _service.paymentStatus!,
                      ),
                    if (_service.paymentMode != null)
                      _Row(AppSvgAssets.idCard, 'Mode', _service.paymentMode!),
                    if (!_service.isComplete && _service.remaining > 0) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showPaymentSheet(context),
                          icon: const AppSvgIcon(AppSvgAssets.plus, size: 16),
                          label: const Text('Add Payment'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

              if (_service.beforePhotos.isNotEmpty)
                _Card(
                  title: 'Before Photos',
                  icon: AppSvgAssets.camera,
                  children: [_PhotoStrip(photos: _service.beforePhotos)],
                ),

              if (_service.afterPhotos.isNotEmpty)
                _Card(
                  title: 'After Photos',
                  icon: AppSvgAssets.camera,
                  children: [_PhotoStrip(photos: _service.afterPhotos)],
                ),

              // ── Action Buttons ────────────────────────────────────────
              if (!_service.isComplete) ...[
                const SizedBox(height: 8),

                // Admin: Assign / Reassign Technician
                if (widget.isAdmin)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<ServiceLeadCubit>(),
                              child: AssignTechnicianScreen(service: _service),
                            ),
                          ),
                        );
                        if (mounted) {
                          context.read<ServiceLeadCubit>().fetchAllServices();
                        }
                      },
                      icon: const AppSvgIcon(AppSvgAssets.userRound, size: 18),
                      label: Text(
                        _service.assignedToId != null
                            ? 'Reassign Technician'
                            : 'Assign Technician',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Service Visit button
                if (_service.status == 'Assigned' ||
                    _service.status == 'In Progress')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<ServiceLeadCubit>(),
                              child: ServiceVisitScreen(service: _service),
                            ),
                          ),
                        );
                        if (mounted) {
                          context.read<ServiceLeadCubit>().fetchAllServices();
                        }
                      },
                      icon: const AppSvgIcon(
                        AppSvgAssets.cog,
                        size: 18,
                        color: AppColors.surface,
                      ),
                      label: const Text(
                        'Open Service Visit',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Quick status buttons
                if (_service.status == 'Assigned')
                  _ActionBtn(
                    'Start Service',
                    AppColors.solar,
                    AppSvgAssets.play,
                    _saving,
                    () => _updateStatus('In Progress'),
                  ),
                if (_service.status == 'In Progress')
                  _ActionBtn(
                    'Mark as Done',
                    AppColors.success,
                    AppSvgAssets.circleCheckBig,
                    _saving,
                    () => _updateStatus('Completed'),
                  ),
              ] else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppSvgIcon(
                        AppSvgAssets.circleCheckBig,
                        color: AppColors.success,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Service Completed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const AppSvgIcon(AppSvgAssets.indianRupee, size: 16),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _payMode,
              icon: const AppSvgIcon(AppSvgAssets.chevronDown, size: 18),
              decoration: InputDecoration(
                labelText: 'Payment Mode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              items: [
                'Cash',
                'UPI',
                'Bank Transfer',
                'Cheque',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _payMode = v);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _addPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(
                        color: AppColors.surface,
                        strokeWidth: 2,
                      )
                    : const Text(
                        'Add Payment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final String icon;
  final bool loading;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.color, this.icon, this.loading, this.onTap);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppColors.surface,
                strokeWidth: 2,
              ),
            )
          : AppSvgIcon(icon, size: 18, color: AppColors.surface),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.surface,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final String title;
  final String icon;
  final List<Widget> children;
  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppSvgIcon(icon, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSvgIcon(icon, size: 12, color: AppColors.background),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textGray),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NotePanel extends StatelessWidget {
  final String text;
  const _NotePanel({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technician Note',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppColors.textDark,
          ),
        ),
      ],
    ),
  );
}

class _PhotoStrip extends StatelessWidget {
  final List<String> photos;
  const _PhotoStrip({required this.photos});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: photos.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final imageUrl = ApiConstants.imageUrl(photos[index]);
        return GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 220,
                      child: Center(child: Text('Unable to load image')),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 96,
              height: 96,
              color: AppColors.divider,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => AppSvgIcon(
                  AppSvgAssets.imageOff,
                  color: AppColors.textLight,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}
