// lib/screens/.../Steps/portal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/core/app_colors.dart';

class SolarPortalScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarPortalScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarPortalScreen> createState() => _State();
}

class _State extends State<SolarPortalScreen> {
  final _appIdC = TextEditingController();
  final _notesC = TextEditingController();
  String? _status;
  bool _saving = false;

  static const _statuses = ['pending', 'underReview', 'approved', 'rejected'];
  static const _statusLabels = {
    'pending': 'Pending',
    'underReview': 'Under Review',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };
  static const _statusColors = {
    'pending': AppColors.solar,
    'underReview': AppColors.primary,
    'approved': AppColors.success,
    'rejected': AppColors.error,
  };

  @override
  void initState() {
    super.initState();
    _appIdC.text = widget.lead.applicationId ?? '';
    _notesC.text = widget.lead.portalData.notes ?? '';
    _status = widget.lead.portalStatus;
  }

  @override
  void dispose() {
    _appIdC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _saving = true);

    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final args = (
      applicationId: _appIdC.text.trim().isEmpty ? null : _appIdC.text.trim(),
      status: _status,
      notes: _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
    );

    if (widget.isEditing) {
      cubit.editPortal(
        id,
        applicationId: args.applicationId,
        status: args.status,
        notes: args.notes,
      );
    } else {
      cubit.savePortal(
        id,
        applicationId: args.applicationId,
        status: args.status,
        notes: args.notes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) Navigator.pop(context);
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
            widget.isEditing
                ? 'Edit Portal Registration'
                : 'Portal Registration',
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

            // ── Application ID
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Application Details'),
                  const SizedBox(height: 8),
                  _field(
                    _appIdC,
                    'Government Application ID',
                    AppSvgAssets.idCard,
                  ),
                ],
              ),
            ),

            // ── Portal Status chips
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Portal Status'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((s) {
                      final selected = _status == s;
                      final color = _statusColors[s] ?? Colors.grey;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _status = selected ? null : s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.12)
                                : LeadTheme.surface,
                            border: Border.all(
                              color: selected ? color : Colors.grey.shade300,
                              width: selected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabels[s] ?? s,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: selected ? color : LeadTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── Notes
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _field(
                    _notesC,
                    'Portal registration notes...',
                    AppSvgAssets.fileText,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _saveBtn(
              _saving,
              _save,
              widget.isEditing
                  ? 'Update Portal Registration'
                  : 'Submit Portal Registration',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _infoBanner(SolarLeadsModel lead) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: LeadTheme.primary.withValues(alpha: 0.06),
    border: Border.all(color: LeadTheme.primary.withValues(alpha: 0.2)),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    children: [
      const AppSvgIcon(
        AppSvgAssets.userRound,
        size: 16,
        color: LeadTheme.primary,
      ),
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

Widget _field(
  TextEditingController c,
  String label,
  String svgAsset, {
  int maxLines = 1,
}) => TextField(
  controller: c,
  maxLines: maxLines,
  style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
  decoration: InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12, color: LeadTheme.textSecondary),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 10, right: 6),
      child: AppSvgIcon(svgAsset, size: 16, color: LeadTheme.textSecondary),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 36),
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
      foregroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: saving
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.surface,
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
  ),
);
