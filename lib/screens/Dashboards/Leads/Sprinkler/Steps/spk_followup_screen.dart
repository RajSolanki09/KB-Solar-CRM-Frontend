// lib/screens/Dashboards/Leads/Sprinkler/Steps/followup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';

class SprinklerFollowupScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  final bool isEditing;
  const SprinklerFollowupScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SprinklerFollowupScreen> createState() => _State();
}

class _State extends State<SprinklerFollowupScreen> {
  final _notesC = TextEditingController();
  final _remarksC = TextEditingController();

  DateTime? _followupDate;
  TimeOfDay? _followupTime;
  String? _selectedResponse;
  String? _selectedCustomerType;
  bool _saving = false;

  // ── Customer Type (interest level) ───────────────────────────────────────
  static const _customerTypeOptions = [
    _DropOption(
      value: 'cold',
      label: 'Cold',
      color: AppColors.blue,
      icon: AppSvgAssets.thermometer,
    ),
    _DropOption(
      value: 'medium',
      label: 'Medium',
      color: AppColors.amber,
      icon: AppSvgAssets.activity,
    ),
    _DropOption(
      value: 'hot',
      label: 'Hot',
      color: AppColors.redError,
      icon: AppSvgAssets.sunMedium,
    ),
  ];

  // ── Customer Response ─────────────────────────────────────────────────────
  static const _responseOptions = [
    _DropOption(
      value: 'thinking',
      label: 'Thinking',
      color: AppColors.amber,
      icon: AppSvgAssets.clock,
    ),
    _DropOption(
      value: 'negotiation',
      label: 'Negotiation',
      color: AppColors.purple,
      icon: AppSvgAssets.handshake,
    ),
    _DropOption(
      value: 'revisionNeeded',
      label: 'Revision Needed',
      color: AppColors.cyan600,
      icon: AppSvgAssets.pencil,
    ),
    _DropOption(
      value: 'rejected',
      label: 'Rejected',
      color: AppColors.redError,
      icon: AppSvgAssets.x,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.lead.followupData;
    _remarksC.text = f.remarks ?? '';
    _notesC.text = f.notes ?? '';
    _followupDate = f.followupDate;
    _selectedCustomerType = f.customerType;

    if (f.followupDate != null) {
      final d = f.followupDate!;
      if (d.hour != 0 || d.minute != 0) {
        _followupTime = TimeOfDay(hour: d.hour, minute: d.minute);
      }
    }

    // reverse-map stored API value → display option
    final raw = f.response;
    if (raw != null) {
      final match = _responseOptions
          .where((o) => o.value == raw)
          .map((o) => o.value)
          .firstOrNull;
      _selectedResponse = match ?? raw;
    }

    final rawType = f.customerType;
    if (rawType != null) {
      final match = _customerTypeOptions
          .where((o) => o.value == rawType)
          .map((o) => o.value)
          .firstOrNull;
      _selectedCustomerType = match ?? rawType;
    }
  }

  @override
  void dispose() {
    _notesC.dispose();
    _remarksC.dispose();
    super.dispose();
  }

  // ── Date / time ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final earliest = _followupDate != null && _followupDate!.isBefore(now)
        ? _followupDate!
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _followupDate ?? now.add(const Duration(days: 1)),
      firstDate: earliest,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _followupDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _followupTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _followupTime = picked);
  }

  DateTime? get _mergedDateTime {
    if (_followupDate == null) return null;
    final t = _followupTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      _followupDate!.year,
      _followupDate!.month,
      _followupDate!.day,
      t.hour,
      t.minute,
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SprinklerLeadCubit>();
    final id = widget.lead.id;
    final notes = _notesC.text.trim().isEmpty ? null : _notesC.text.trim();
    final remarks = _remarksC.text.trim().isEmpty
        ? null
        : _remarksC.text.trim();

    if (widget.isEditing) {
      cubit.editFollowup(
        id,
        followupDate: _mergedDateTime,
        response: _selectedResponse,
        customerType: _selectedCustomerType,
        remarks: remarks,
        notes: notes,
      );
    } else {
      cubit.saveFollowup(
        id,
        followupDate: _mergedDateTime,
        response: _selectedResponse,
        customerType: _selectedCustomerType,
        remarks: remarks,
        notes: notes,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (state is SprinklerLeadSaved) Navigator.pop(context);
        if (state is SprinklerLeadError) {
          setState(() => _saving = false);
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: LeadTheme.bg,
        appBar: AppBar(
          backgroundColor: LeadTheme.secondary,
          elevation: 0,
          leading: IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.chevronLeft,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.isEditing ? 'Edit Follow-up' : 'Follow-up',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: LeadTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildBanner(),
            const SizedBox(height: 10),

            // ── Date & Time ────────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Follow-up Schedule'),
                  const SizedBox(height: 8),
                  _buildDateTile(),
                  const SizedBox(height: 8),
                  _buildTimeTile(),
                ],
              ),
            ),

            // ── Customer Type & Response ───────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Lead Status'),
                  const SizedBox(height: 10),

                  _buildFieldLabel('Customer Interest Level'),
                  const SizedBox(height: 6),
                  _buildColoredDropdown(
                    hint: 'Select interest level (optional)',
                    value: _selectedCustomerType,
                    options: _customerTypeOptions,
                    onChanged: (v) => setState(() => _selectedCustomerType = v),
                  ),

                  const SizedBox(height: 14),

                  _buildFieldLabel('Customer Response'),
                  const SizedBox(height: 6),
                  _buildColoredDropdown(
                    hint: 'Select customer response (optional)',
                    value: _selectedResponse,
                    options: _responseOptions,
                    onChanged: (v) => setState(() => _selectedResponse = v),
                  ),
                ],
              ),
            ),

            // ── Notes ──────────────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _notesC,
                    label: 'Additional notes...',
                    icon: AppSvgAssets.fileText,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Coloured dropdown (shared by both customer type & response) ───────────
  Widget _buildColoredDropdown({
    required String hint,
    required String? value,
    required List<_DropOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    final sel = value != null
        ? options.where((o) => o.value == value).firstOrNull
        : null;
    final selColor = sel?.color;

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
        filled: true,
        fillColor: sel != null
            ? selColor!.withValues(alpha: 0.07)
            : LeadTheme.surface,
        // ── prefixIcon removed to prevent double icon after selection ──────
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: sel != null
                ? selColor!.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: sel != null ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: sel != null
                ? selColor!.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: sel != null ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: LeadTheme.secondary, width: 1.5),
        ),
      ),
      isExpanded: true,
      icon: AppSvgIcon(
        AppSvgAssets.chevronDown,
        size: 16,
        color: Colors.grey.shade500,
      ),
      // ── Items list ────────────────────────────────────────────────────────
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'None',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ...options.map(
          (opt) => DropdownMenuItem<String>(
            value: opt.value,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: opt.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: AppSvgIcon(opt.icon, size: 14, color: opt.color),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: opt.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      // ── Selected item display — icon lives here only ───────────────────
      selectedItemBuilder: (_) => [
        Text(
          'None',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
        ...options.map(
          (opt) => Row(
            children: [
              AppSvgIcon(opt.icon, size: 15, color: opt.color),
              const SizedBox(width: 6),
              Text(
                opt.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: opt.color,
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  // ── Lead banner ───────────────────────────────────────────────────────────
  Widget _buildBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: LeadTheme.secondary.withValues(alpha: 0.06),
      border: Border.all(color: LeadTheme.secondary.withValues(alpha: 0.2)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const AppSvgIcon(
          AppSvgAssets.droplet,
          size: 16,
          color: LeadTheme.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lead.customerName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LeadTheme.textPrimary,
                ),
              ),
              Text(
                '${widget.lead.phone}  ·  ${widget.lead.address}',
                style: const TextStyle(
                  fontSize: 11,
                  color: LeadTheme.textSecondary,
                ),
              ),
              if (widget.lead.interestLevel != null) ...[
                const SizedBox(height: 6),
                _buildInterestBadge(widget.lead.interestLevel!),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  // ── Interest badge ───────────────────────────────────────────────────────
  Widget _buildInterestBadge(String interestLevel) {
    final match = _customerTypeOptions
        .where((o) => o.value == interestLevel)
        .firstOrNull;

    if (match == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: match.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(match.icon, size: 12, color: match.color),
          const SizedBox(width: 4),
          Text(
            match.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: match.color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Date tile ─────────────────────────────────────────────────────────────
  Widget _buildDateTile() {
    final has = _followupDate != null;
    final c = has ? Colors.teal : LeadTheme.textSecondary;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: has ? Colors.teal.shade50 : LeadTheme.surface,
          border: Border.all(
            color: has ? Colors.teal.shade300 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AppSvgIcon(AppSvgAssets.calendarDays, size: 16, color: c),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Follow-up Date',
                  style: TextStyle(
                    fontSize: 11,
                    color: LeadTheme.textSecondary,
                  ),
                ),
                Text(
                  has
                      ? '${_followupDate!.day}/${_followupDate!.month}/${_followupDate!.year}'
                      : 'Tap to select date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: has ? c : LeadTheme.textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppSvgIcon(
              has ? AppSvgAssets.circleCheckBig : AppSvgAssets.chevronRight,
              size: 14,
              color: has ? Colors.teal : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Time tile ─────────────────────────────────────────────────────────────
  Widget _buildTimeTile() {
    final has = _followupTime != null;
    final c = has ? Colors.teal : LeadTheme.textSecondary;
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: has ? Colors.teal.shade50 : LeadTheme.surface,
          border: Border.all(
            color: has ? Colors.teal.shade300 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AppSvgIcon(AppSvgAssets.clock, size: 16, color: c),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Follow-up Time',
                  style: TextStyle(
                    fontSize: 11,
                    color: LeadTheme.textSecondary,
                  ),
                ),
                Text(
                  has ? _followupTime!.format(context) : 'Tap to select time',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: has ? c : LeadTheme.textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppSvgIcon(
              has ? AppSvgAssets.circleCheckBig : AppSvgAssets.chevronRight,
              size: 14,
              color: has ? Colors.teal : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String icon,
    int maxLines = 1,
  }) => LeadTextFormField(
    controller: controller,
    label: label,
    svgIcon: icon,
    accentColor: LeadTheme.secondary,
    required: false,
    maxLines: maxLines,
    bottomSpacing: 0,
  );

  // ── Small label ───────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.gray400,
    ),
  );

  // ── Save button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: _saving ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: LeadTheme.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Save Follow-up',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    ),
  );
}

// ── Option model ──────────────────────────────────────────────────────────────
class _DropOption {
  final String value, label, icon;
  final Color color;
  const _DropOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}





