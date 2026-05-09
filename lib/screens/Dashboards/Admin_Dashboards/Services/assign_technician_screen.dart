// lib/screens/Dashboards/Admin_Dashboards/Services/assign_technician_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/data/Models/admin_user_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

class AssignTechnicianScreen extends StatefulWidget {
  final ServiceRequestModel service;
  const AssignTechnicianScreen({super.key, required this.service});
  @override
  State<AssignTechnicianScreen> createState() => _State();
}

class _State extends State<AssignTechnicianScreen> {
  List<UserModel> _techs = [];
  bool _loadingTech = true;
  String? _selectedTechId;
  String? _selectedTechName;
  DateTime? _visitDate;
  TimeOfDay? _visitTime;
  String _priority = 'Medium';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if already assigned
    _selectedTechId = widget.service.assignedToId;
    _selectedTechName = widget.service.assignedToName;
    _visitDate = widget.service.serviceDate;
    _priority = widget.service.priority;
    _notesCtrl.text = widget.service.serviceNotes ?? '';
    if (widget.service.serviceDate != null) {
      final d = widget.service.serviceDate!;
      _visitTime = TimeOfDay(hour: d.hour, minute: d.minute);
    }
    _loadTechs();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTechs() async {
    try {
      final data = await ApiService().getStaff(role: 'service');
      final all = data.map((e) => UserModel.fromJson(e)).toList();
      setState(() {
        _techs = all;
        _loadingTech = false;
      });
    } catch (_) {
      setState(() => _loadingTech = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.success),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _visitDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _visitTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.success),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _visitTime = t);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Future<void> _assign() async {
    if (_selectedTechId == null) {
      AppFeedback.showInfo(context, 'Please select a technician');
      return;
    }
    if (_visitDate == null) {
      AppFeedback.showInfo(context, 'Please select a visit date');
      return;
    }
    if (_visitTime == null) {
      AppFeedback.showInfo(context, 'Please select a visit time');
      return;
    }

    setState(() => _saving = true);
    try {
      // Save date and time together in assignment.serviceDate.
      final serviceDate = DateTime(
        _visitDate!.year,
        _visitDate!.month,
        _visitDate!.day,
        _visitTime!.hour,
        _visitTime!.minute,
      );

      await context.read<ServiceLeadCubit>().updateService(widget.service.id, {
        'assignedTo': _selectedTechId,
        'status': 'Assigned',
        'priority': _priority,
        if (_notesCtrl.text.trim().isNotEmpty)
          'serviceNotes': _notesCtrl.text.trim(),
        'assignment': {
          'assignedAt': DateTime.now().toIso8601String(),
          'serviceDate': serviceDate.toIso8601String(),
        },
      });

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'Assigned to $_selectedTechName successfully',
        );
        Navigator.pop(context);
      }
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
          setState(() => _saving = false);
        }
      },
      child: Scaffold(
        backgroundColor:  AppColors.background,
        appBar: AppBar(
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
                'Assign Technician',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                widget.service.customerName,
                style: const TextStyle(fontSize: 11, color: AppColors.textGray),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 40),
          child: Column(
            children: [
              // ── Service Summary Card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppSvgIcon(
                          AppSvgAssets.cog,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Service Summary',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        _PriorityBadge(widget.service.priority),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SRow(AppSvgAssets.userRound, widget.service.customerName),
                    _SRow(AppSvgAssets.phone, widget.service.phone),
                    _SRow(AppSvgAssets.mapPin, widget.service.address),
                    if (widget.service.issueType?.isNotEmpty == true)
                      _SRow(
                        AppSvgAssets.triangleAlert,
                        widget.service.issueType!,
                      ),
                    _SRow(
                      AppSvgAssets.clipboardList,
                      widget.service.chargeType,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Select Technician ─────────────────────────────────────
              _Card(
                title: 'Select Technician',
                svgAsset: AppSvgAssets.cog,
                child: _loadingTech
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: AppColors.success,
                          ),
                        ),
                      )
                    : _techs.isEmpty
                    ? const Text(
                        'No service technicians found.\n'
                        'Add technicians from Manage Users.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      )
                    : Column(
                        children: [
                          // Tech cards
                          ..._techs.map((tech) {
                            final selected = _selectedTechId == tech.id;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedTechId = tech.id;
                                _selectedTechName = tech.name;
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(
                                          0xFF43E97B,
                                        ).withValues(alpha: 0.08)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ?  AppColors.success
                                        : AppColors.divider,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: selected
                                          ? const Color(
                                              0xFF43E97B,
                                            ).withValues(alpha: 0.2)
                                          : AppColors.divider,
                                      child: Text(
                                        tech.name.isNotEmpty
                                            ? tech.name[0].toUpperCase()
                                            : 'T',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ?  AppColors.success
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tech.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: selected
                                                  ?  AppColors.success
                                                  :  AppColors.textDark,
                                            ),
                                          ),
                                          if (tech.phone.isNotEmpty)
                                            Text(
                                              tech.phone,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const AppSvgIcon(
                                        AppSvgAssets.circleCheckBig,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
              ),

              const SizedBox(height: 8),

              // ── Visit Schedule ────────────────────────────────────────
              _Card(
                title: 'Visit Schedule',
                svgAsset: AppSvgAssets.calendarDays,
                child: Column(
                  children: [
                    // Date
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _visitDate != null
                              ?  AppColors.success.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _visitDate != null
                                ?  AppColors.success
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.calendarDays,
                              size: 18,
                              color: _visitDate != null
                                  ?  AppColors.success
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _visitDate != null
                                  ? _fmtDate(_visitDate!)
                                  : 'Select Visit Date *',
                              style: TextStyle(
                                fontSize: 13,
                                color: _visitDate != null
                                    ?  AppColors.textDark
                                    : Colors.grey,
                                fontWeight: _visitDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            AppSvgIcon(
                              AppSvgAssets.chevronRight,
                              size: 12,
                              color: AppColors.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Time
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _visitTime != null
                              ?  AppColors.success.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _visitTime != null
                                ?  AppColors.success
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppSvgIcon(
                              AppSvgAssets.clock,
                              size: 18,
                              color: _visitTime != null
                                  ?  AppColors.success
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _visitTime != null
                                  ? _fmtTime(_visitTime!)
                                  : 'Select Visit Time *',
                              style: TextStyle(
                                fontSize: 13,
                                color: _visitTime != null
                                    ?  AppColors.textDark
                                    : Colors.grey,
                                fontWeight: _visitTime != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            AppSvgIcon(
                              AppSvgAssets.chevronRight,
                              size: 12,
                              color: AppColors.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Priority ──────────────────────────────────────────────
              _Card(
                title: 'Priority',
                svgAsset: AppSvgAssets.triangleAlert,
                child: Row(
                  children: [
                    ...['Low', 'Medium', 'High', 'Urgent'].map((p) {
                      final col = p == 'Urgent'
                          ? AppColors.error
                          : p == 'High'
                          ? AppColors.solar
                          : p == 'Low'
                          ? AppColors.success
                          : AppColors.primary;
                      final sel = _priority == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? col.withValues(alpha: 0.15)
                                  : AppColors.divider,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? col : Colors.grey.shade300,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? col : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Notes ─────────────────────────────────────────────────
              _Card(
                title: 'Notes for Technician',
                svgAsset: AppSvgAssets.fileText,
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Any special instructions...',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
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
                      borderSide: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Assign Button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _assign,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.surface,
                            strokeWidth: 2,
                          ),
                        )
                      : const AppSvgIcon(
                          AppSvgAssets.userRound,
                          size: 20,
                          color: AppColors.surface,
                        ),
                  label: Text(
                    _saving ? 'Assigning...' : 'Assign Job',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final String svgAsset;
  final Widget child;
  const _Card({
    required this.title,
    required this.svgAsset,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 4),
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
            AppSvgIcon(svgAsset, size: 14, color:  AppColors.success),
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

class _SRow extends StatelessWidget {
  final String svgAsset;
  final String value;
  const _SRow(this.svgAsset, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        AppSvgIcon(svgAsset, size: 12, color: AppColors.background),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
      ],
    ),
  );
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge(this.priority);
  @override
  Widget build(BuildContext context) {
    final color = priority == 'Urgent'
        ? AppColors.error
        : priority == 'High'
        ? AppColors.solar
        : priority == 'Low'
        ? AppColors.success
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
