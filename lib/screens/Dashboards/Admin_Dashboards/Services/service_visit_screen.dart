// lib/screens/Dashboards/Admin_Dashboards/Services/service_visit_screen.dart
// Technician work screen — before/after photos, notes, mark done

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';

class ServiceVisitScreen extends StatefulWidget {
  final ServiceRequestModel service;
  const ServiceVisitScreen({super.key, required this.service});
  @override
  State<ServiceVisitScreen> createState() => _State();
}

class _State extends State<ServiceVisitScreen> {
  late ServiceRequestModel _service;
  final _problemCtrl = TextEditingController();
  final _repairCtrl = TextEditingController();
  final _partsCtrl = TextEditingController();

  final _picker = ImagePicker();

  // Before photos
  final List<PickedPhoto> _beforePhotos = [];
  // After photos
  final List<PickedPhoto> _afterPhotos = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _problemCtrl.text = _service.issueDescription ?? '';
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    _repairCtrl.dispose();
    _partsCtrl.dispose();
    super.dispose();
  }

  // ── Pick photos ────────────────────────────────────────────────────────────
  Future<void> _pickPhoto(bool isBefore) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final photo = PickedPhoto(bytes: bytes, filename: file.name);
      setState(() {
        if (isBefore) {
          _beforePhotos.add(photo);
        } else {
          _afterPhotos.add(photo);
        }
      });
    } catch (_) {}
  }

  Future<void> _takePhoto(bool isBefore) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final photo = PickedPhoto(bytes: bytes, filename: file.name);
      setState(() {
        if (isBefore) {
          _beforePhotos.add(photo);
        } else {
          _afterPhotos.add(photo);
        }
      });
    } catch (_) {}
  }

  // ── Save and update status ─────────────────────────────────────────────────
  Future<void> _markDone() async {
    if (_afterPhotos.isEmpty && _service.afterPhotos.isEmpty) {
      AppFeedback.showInfo(context, 'Please upload at least one after photo');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_beforePhotos.isNotEmpty || _afterPhotos.isNotEmpty) {
        await context.read<ServiceLeadCubit>().uploadPhotos(
          _service.id,
          beforePhotos: _beforePhotos,
          afterPhotos: _afterPhotos,
        );
      }

      await context.read<ServiceLeadCubit>().updateService(_service.id, {
        'status': 'Completed',
        if (_buildCompletedServiceNotes() != null)
          'serviceNotes': _buildCompletedServiceNotes(),
      });
      if (mounted) {
        AppFeedback.showSuccess(context, 'Service marked as completed');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _buildCompletedServiceNotes() {
    final sections = <String>[];
    final existing = _service.serviceNotes?.trim();
    final repair = _repairCtrl.text.trim();
    final parts = _partsCtrl.text.trim();

    if (existing != null && existing.isNotEmpty) {
      sections.add(existing);
    }
    if (repair.isNotEmpty) {
      sections.add('Repair Work: $repair');
    }
    if (parts.isNotEmpty) {
      sections.add('Parts: $parts');
    }

    if (sections.isEmpty) return null;
    return sections.join('\n\n');
  }

  Future<void> _startService() async {
    setState(() => _saving = true);
    try {
      await context.read<ServiceLeadCubit>().updateService(_service.id, {
        'status': 'In Progress',
      });
      setState(() {
        _service.status = 'In Progress';
        _saving = false;
      });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiceLeadCubit, ServiceLeadState>(
      listener: (_, state) {
        if (state is ServiceLeadError) {
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor:   AppColors.lightBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
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
              const Text(
                'Service Visit',
                style: TextStyle(
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
              // ── Customer Info ───────────────────────────────────────────
              _Section(
                title: 'Customer Info',
                icon: AppSvgAssets.userRound,
                color: AppColors.blue,
                child: Column(
                  children: [
                    _InfoRow('Name', _service.customerName),
                    _InfoRow('Phone', _service.phone),
                    _InfoRow('Address', _service.address),
                    if (_service.issueType?.isNotEmpty == true)
                      _InfoRow('Issue', _service.issueType!),
                  ],
                ),
              ),

              // ── Problem Notes ───────────────────────────────────────────
              _Section(
                title: 'Problem Description',
                icon: AppSvgAssets.triangleAlert,
                color: AppColors.primary,
                child: TextField(
                  controller: _problemCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDec('Describe the problem...'),
                ),
              ),

              // ── Before Photos ───────────────────────────────────────────
              _Section(
                title: 'Before Repair Photos',
                icon: AppSvgAssets.camera,
                color: AppColors.primary,
                child: Column(
                  children: [
                    if (_beforePhotos.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _beforePhotos.length,
                          itemBuilder: (_, i) => Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: MemoryImage(
                                      Uint8List.fromList(
                                        _beforePhotos[i].bytes,
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _beforePhotos.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const AppSvgIcon(
                                      AppSvgAssets.x,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _PhotoButtons(
                      onGallery: () => _pickPhoto(true),
                      onCamera: kIsWeb ? null : () => _takePhoto(true),
                    ),
                  ],
                ),
              ),

              // ── Repair Description ──────────────────────────────────────
              _Section(
                title: 'Repair Work Done',
                icon: AppSvgAssets.cog,
                color: AppColors.primary,
                child: Column(
                  children: [
                    TextField(
                      controller: _repairCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDec('Describe the repair work done...'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _partsCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDec('Parts used (if any)...'),
                    ),
                  ],
                ),
              ),

              // ── After Photos ────────────────────────────────────────────
              _Section(
                title: 'After Repair Photos',
                icon: AppSvgAssets.camera,
                color: AppColors.primary,
                child: Column(
                  children: [
                    if (_afterPhotos.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _afterPhotos.length,
                          itemBuilder: (_, i) => Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: MemoryImage(
                                      Uint8List.fromList(_afterPhotos[i].bytes),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _afterPhotos.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const AppSvgIcon(
                                      AppSvgAssets.x,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _PhotoButtons(
                      onGallery: () => _pickPhoto(false),
                      onCamera: kIsWeb ? null : () => _takePhoto(false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Action Buttons ──────────────────────────────────────────
              if (_service.isComplete)
                _DoneBar()
              else if (_service.status == 'Assigned') ...[
                _ActionBtn(
                  'Start Service',
                  AppColors.primary,
                  AppSvgAssets.play,
                  _saving,
                  _startService,
                ),
              ] else if (_service.status == 'In Progress') ...[
                _ActionBtn(
                  'Mark as Completed',
                  AppColors.primary,
                  AppSvgAssets.circleCheckBig,
                  _saving,
                  _markDone,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Assigned':
        return AppColors.blue;
      case 'In Progress':
        return AppColors.primary;
      case 'Completed':
        return AppColors.green;
      default:
        return AppColors.primary;
    }
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.green),
    ),
  );
}

// ── Photo Buttons ─────────────────────────────────────────────────────────────
class _PhotoButtons extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback? onCamera;
  const _PhotoButtons({required this.onGallery, this.onCamera});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onGallery,
          icon: const AppSvgIcon(AppSvgAssets.images, size: 16),
          label: const Text('Gallery', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor:   AppColors.green,
            side: const BorderSide(color: AppColors.green),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
      if (onCamera != null) ...[
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCamera,
            icon: const AppSvgIcon(AppSvgAssets.camera, size: 16),
            label: const Text('Camera', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    ],
  );
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final String icon;
  final Color color;
  final Widget child;
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
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
            AppSvgIcon(icon, size: 14, color: color),
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
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
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
    height: 50,
    child: ElevatedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : AppSvgIcon(icon, size: 20, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class _DoneBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(AppSvgAssets.circleCheckBig, color: AppColors.primary, size: 20),
        SizedBox(width: 8),
        Text(
          'Service Completed',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}




