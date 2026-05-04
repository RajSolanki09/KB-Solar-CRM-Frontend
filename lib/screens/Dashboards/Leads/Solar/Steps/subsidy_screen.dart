// lib/screens/.../Steps/subsidy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/Helper/app_colors.dart';

class SolarSubsidyScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarSubsidyScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarSubsidyScreen> createState() => _State();
}

class _State extends State<SolarSubsidyScreen> {
  final _notesC = TextEditingController();
  bool? _subsidyClaim;
  bool? _receivedAmount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesC.text = widget.lead.subsidyData.notes ?? '';
    _subsidyClaim = widget.lead.subsidyClaim;
    _receivedAmount = widget.lead.subsidyReceivedAmount;
  }

  @override
  void dispose() {
    _notesC.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final notes = _notesC.text.trim().isEmpty ? null : _notesC.text.trim();

    if (widget.isEditing) {
      cubit.editSubsidy(
        id,
        subsidyClaim: _subsidyClaim,
        receivedAmount: _receivedAmount,
        notes: notes,
      );
    } else {
      cubit.saveSubsidy(
        id,
        subsidyClaim: _subsidyClaim,
        receivedAmount: _receivedAmount,
        notes: notes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) safePop(context);
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
            widget.isEditing ? 'Edit Subsidy' : 'Subsidy Completed',
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

            // ── Subsidy Claim & Received Amount cards ──────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Subsidy Claim / Final Payment'),
                  const SizedBox(height: 12),
                  _YesNoRow(
                    label: 'Subsidy Claim',
                    value: _subsidyClaim,
                    onChanged: (v) => setState(() => _subsidyClaim = v),
                  ),
                  const SizedBox(height: 10),
                  _YesNoRow(
                    label: 'Received Amount',
                    value: _receivedAmount,
                    onChanged: (v) => setState(() => _receivedAmount = v),
                  ),
                ],
              ),
            ),

            // ── Notes ─────────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _subsidyField(
                    _notesC,
                    'Notes...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _saveBtn(
              _saving,
              _save,
              widget.isEditing ? 'Update Subsidy' : 'Save Subsidy',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _YesNoRow extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  const _YesNoRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: LeadTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Yes',
          selected: value == true,
          color: AppColors.success,
          onTap: () => onChanged(value == true ? null : true),
        ),
        const SizedBox(width: 6),
        _Chip(
          label: 'No',
          selected: value == false,
          color: AppColors.error,
          onTap: () => onChanged(value == false ? null : false),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : LeadTheme.surface,
          border: Border.all(
            color: selected ? color : AppColors.borderPrimary,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? color : LeadTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

Widget _infoBanner(SolarLeadsModel lead) => Container(
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

Widget _subsidyField(
  TextEditingController c,
  String label, {
  int maxLines = 1,
}) => TextField(
  controller: c,
  maxLines: maxLines,
  style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
  decoration: InputDecoration(
    hintText: label,
    hintStyle: const TextStyle(fontSize: 12, color: LeadTheme.textSecondary),
    filled: true,
    fillColor: LeadTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  ),
);

Widget _saveBtn(bool saving, VoidCallback onPressed, String label) => SizedBox(
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




