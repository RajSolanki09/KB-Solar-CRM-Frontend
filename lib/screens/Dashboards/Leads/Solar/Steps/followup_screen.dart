import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';

class SolarFollowupScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarFollowupScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarFollowupScreen> createState() => _State();
}

class _State extends State<SolarFollowupScreen> {
  final notesC = TextEditingController();
  DateTime? followupDate;
  TimeOfDay? followupTime;
  String? selectedOutcome;
  String? selectedCustomerType;
  bool _saving = false;
  late final List<_DropOption> _responseOptions;

  static const _customerTypeOptions = [
    _DropOption(
      value: 'cold',
      label: 'Cold',
      color: AppColors.textGray,
      icon: AppSvgAssets.activity,
    ),
    _DropOption(
      value: 'medium',
      label: 'Medium',
      color: AppColors.textGray,
      icon: AppSvgAssets.clock,
    ),
    _DropOption(
      value: 'hot',
      label: 'Hot',
      color: AppColors.textGray,
      icon: AppSvgAssets.sun,
    ),
  ];

  static const _baseResponseOptions = [
    _DropOption(
      value: 'thinking',
      label: 'Thinking',
      color: AppColors.textGray,
      icon: AppSvgAssets.history,
    ),
    _DropOption(
      value: 'negotiation',
      label: 'Negotiation',
      color: AppColors.textGray,
      icon: AppSvgAssets.handshake,
    ),
    _DropOption(
      value: 'revisionNeeded',
      label: 'Revision Needed',
      color: AppColors.textGray,
      icon: AppSvgAssets.pencil,
    ),
    _DropOption(
      value: 'rejected',
      label: 'Rejected',
      color: AppColors.textGray,
      icon: AppSvgAssets.x,
    ),
  ];

  List<_DropOption> _buildDynamicResponseOptions(String? initialValue) {
    final list = List<_DropOption>.from(_baseResponseOptions);
    if (initialValue == null || initialValue.trim().isEmpty) return list;

    final exists = list.any((o) => o.value == initialValue);
    if (!exists) {
      list.add(
        _DropOption(
          value: initialValue,
          label: _humanize(initialValue),
          color:  AppColors.textGray,
          icon: AppSvgAssets.history,
        ),
      );
    }
    return list;
  }

  String _humanize(String raw) {
    final spaced = raw
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    if (spaced.isEmpty) return raw;
    return spaced
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    notesC.text = widget.lead.followupData.notes ?? '';

    // ── FIX: pre-fill date AND time when editing ──────────────────────────
    if (widget.lead.followupDate != null) {
      followupDate = widget.lead.followupDate;
      final d = widget.lead.followupDate!;
      // Only set time if it has a meaningful value (not midnight 00:00)
      if (d.hour != 0 || d.minute != 0) {
        followupTime = TimeOfDay(hour: d.hour, minute: d.minute);
      }
    }

    selectedOutcome = widget.lead.followupData.response ?? widget.lead.followupOutcome;
    selectedCustomerType = widget.lead.followupData.customerType;
    _responseOptions = _buildDynamicResponseOptions(selectedOutcome);
  }

  @override
  void dispose() {
    notesC.dispose();
    super.dispose();
  }

  // ── FIX: allow past dates so editing never gets blocked ──────────────────
  Future<void> _pickDate() async {
    final initial = followupDate ?? DateTime.now().add(const Duration(days: 1));
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      // Use far-past firstDate so editing an old date is never blocked
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => followupDate = d);
  }

  // ── NEW: time picker ──────────────────────────────────────────────────────
  Future<void> _pickTime() async {
    final initial = followupTime ?? TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.primary),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => followupTime = t);
  }

  // ── Merge date + time into one DateTime before saving ────────────────────
  DateTime? get _mergedDateTime {
    if (followupDate == null) return null;
    final t = followupTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      followupDate!.year,
      followupDate!.month,
      followupDate!.day,
      t.hour,
      t.minute,
    );
  }

  void _save() {
    setState(() => _saving = true);

    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final outcome = selectedOutcome;
    final notes = notesC.text.trim().isEmpty ? null : notesC.text.trim();
    final interestLevel = _mapCustomerTypeToInterestLevel(selectedCustomerType);

    if (widget.isEditing) {
      cubit.editFollowup(
        id,
        followupDate: _mergedDateTime,
        outcome: outcome,
        customerType: selectedCustomerType,
        notes: notes,
        interestLevel: interestLevel,
        followupType: 'call',
      );
    } else {
      cubit.saveFollowup(
        id,
        followupDate: _mergedDateTime,
        outcome: outcome,
        customerType: selectedCustomerType,
        notes: notes,
        interestLevel: interestLevel,
        followupType: 'call',
      );
    }
  }

  String? _mapCustomerTypeToInterestLevel(String? customerType) {
    switch (customerType) {
      case 'cold':
        return 'cold';
      case 'medium':
        return 'warm';
      case 'hot':
        return 'hot';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) {
          setState(() => _saving = false);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) Navigator.pop(context);
          });
        }
        if (state is SolarLeadError) {
          setState(() => _saving = false);
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: LeadTheme.bg,
        appBar: AppBar(
          backgroundColor: LeadTheme.surface,
          elevation: 0,
          title: Text(
            widget.isEditing ? 'Edit Follow-up' : 'Follow-up',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LeadTheme.textPrimary,
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
                        color: LeadTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _infoBanner(widget.lead),
            const SizedBox(height: 10),

            // ── Date + Time card ────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Follow-up Schedule'),
                  const SizedBox(height: 8),
                  // Date tile
                  GestureDetector(
                    onTap: _pickDate,
                    child: _dateTile(
                      AppSvgAssets.calendarDays,
                      'Follow-up Date',
                      followupDate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── NEW: Time tile ─────────────────────────────────────
                  GestureDetector(
                    onTap: _pickTime,
                    child: _timeTile(followupTime),
                  ),
                ],
              ),
            ),

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
                    value: selectedCustomerType,
                    options: _customerTypeOptions,
                    onChanged: (v) => setState(() => selectedCustomerType = v),
                  ),

                  const SizedBox(height: 14),

                  _buildFieldLabel('Customer Response'),
                  const SizedBox(height: 6),
                  _buildColoredDropdown(
                    hint: 'Select customer response (optional)',
                    value: selectedOutcome,
                    options: _responseOptions,
                    onChanged: (v) => setState(() => selectedOutcome = v),
                  ),
                ],
              ),
            ),

            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _field(
                    notesC,
                    'Enter follow-up notes...',
                    AppSvgAssets.fileText,
                    maxLines: 4,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _saveBtn(
              _saving,
              _save,
              widget.isEditing ? 'Update Follow-up' : 'Save Follow-up',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _infoBanner(SolarLeadsModel lead) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: LeadTheme.primary.withValues(alpha: 0.06),
      border: Border.all(color: LeadTheme.primary.withValues(alpha: 0.2)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const AppSvgIcon(AppSvgAssets.userRound, size: 16, color: LeadTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lead.customerName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LeadTheme.textPrimary,
                ),
              ),
              Text(
                '${lead.mobile}  ·  ${lead.address}',
                style: const TextStyle(
                  fontSize: 11,
                  color: LeadTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _dateTile(String svgAsset, String label, DateTime? date) {
  final c = date != null ? Colors.green : LeadTheme.textSecondary;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: date != null ? Colors.green.shade50 : LeadTheme.surface,
      border: Border.all(
        color: date != null ? Colors.green.shade300 : Colors.grey.shade300,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        AppSvgIcon(svgAsset, size: 16, color: c),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: LeadTheme.textSecondary,
              ),
            ),
            Text(
              date == null
                  ? 'Tap to select date'
                  : '${date.day}/${date.month}/${date.year}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: date == null ? LeadTheme.textMuted : c,
              ),
            ),
          ],
        ),
        const Spacer(),
        AppSvgIcon(
          date != null ? AppSvgAssets.circleCheckBig : AppSvgAssets.arrowRight,
          size: 14,
          color: date != null ? Colors.green : Colors.grey.shade400,
        ),
      ],
    ),
  );
}

// ── NEW: time tile ────────────────────────────────────────────────────────────
Widget _timeTile(TimeOfDay? time) {
  final hasTime = time != null;
  final c = hasTime ? Colors.green.shade600 : LeadTheme.textSecondary;

  String fmt(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: hasTime ? Colors.green.shade50 : LeadTheme.surface,
      border: Border.all(
        color: hasTime ? Colors.green.shade300 : Colors.grey.shade300,
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
              style: TextStyle(fontSize: 11, color: LeadTheme.textSecondary),
            ),
            Text(
              hasTime ? fmt(time) : 'Tap to select time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: hasTime ? c : LeadTheme.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        AppSvgIcon(
          hasTime ? AppSvgAssets.circleCheckBig : AppSvgAssets.arrowRight,
          size: 14,
          color: hasTime ? Colors.green.shade400 : Colors.grey.shade400,
        ),
      ],
    ),
  );
}

Widget _buildFieldLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: LeadTheme.textPrimary,
    ),
  );
}

Widget _buildColoredDropdown({
  required String hint,
  required String? value,
  required List<_DropOption> options,
  required ValueChanged<String?> onChanged,
}) {
  _DropOption? selected;
  if (value != null) {
    for (final opt in options) {
      if (opt.value == value) {
        selected = opt;
        break;
      }
    }
  }

  final selectedColor = selected?.color;

  return DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(
      filled: true,
      fillColor: selectedColor?.withValues(alpha: 0.08) ?? LeadTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: selectedColor?.withValues(alpha: 0.45) ?? Colors.grey.shade300,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    hint: Text(hint, style: const TextStyle(fontSize: 12)),
    items: options
        .map(
          (o) => DropdownMenuItem<String>(
            value: o.value,
            child: Row(
              children: [
                AppSvgIcon(o.icon, size: 14, color: o.color),
                const SizedBox(width: 8),
                Text(
                  o.label,
                  style: TextStyle(
                    color: o.color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}

class _DropOption {
  final String value;
  final String label;
  final Color color;
  final String icon;

  const _DropOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

Widget _field(
  TextEditingController c,
  String label,
  String svgAsset, {
  int maxLines = 1,
}) => LeadTextFormField(
  controller: c,
  label: label,
  svgIcon: svgAsset,
  accentColor: LeadTheme.orange,
  required: false,
  maxLines: maxLines,
  bottomSpacing: 0,
);

Widget _saveBtn(bool saving, VoidCallback onPressed, String label) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: saving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: LeadTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    ),
  );
}








