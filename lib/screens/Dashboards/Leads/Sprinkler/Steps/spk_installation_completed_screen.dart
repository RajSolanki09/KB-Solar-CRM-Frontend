// lib/screens/Dashboards/Leads/Sprinkler/Steps/spk_installation_complete_screen.dart
// Used by the INSTALLATION TEAM to mark sprinkler installation as completed.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/Helper/spk_photo_picker.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/core/app_colors.dart';

class SpkInstallationCompleteScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SpkInstallationCompleteScreen({super.key, required this.lead});
  @override
  State<SpkInstallationCompleteScreen> createState() => _State();
}

class _State extends State<SpkInstallationCompleteScreen> {
  final _techC = TextEditingController();
  final _notesC = TextEditingController();
  final _pendingWorkNoteC = TextEditingController();
  final _customerReviewC = TextEditingController();
  DateTime? _installDate;
  DateTime? _followUpDate;
  bool? _pendingWork;
  bool? _testing;
  bool? _paymentReceived;
  List<PickedPhoto> _photos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.lead.installationData;
    _techC.text = d.technicianName ?? '';
    _notesC.text = d.notes ?? '';
    _installDate = d.installationDate;
    final isExistingCompletion = d.completedAt != null;
    _pendingWork = isExistingCompletion ? d.pendingWork : null;
    _pendingWorkNoteC.text = d.pendingWorkNote ?? '';
    _testing = isExistingCompletion ? d.systemTested : null;
    _paymentReceived = d.paymentReceived;
    _followUpDate = d.followUpDate;
    _customerReviewC.text = d.customerReview ?? '';
  }

  @override
  void dispose() {
    for (final c in [_techC, _notesC, _pendingWorkNoteC, _customerReviewC]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickInstallDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _installDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (d != null) setState(() => _installDate = d);
  }

  Future<void> _pickFollowUpDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _followUpDate = d);
  }

  void _save() {
    if (_testing == null) {
      AppFeedback.showError(context, 'Please select testing status');
      return;
    }
    if (_paymentReceived == null) {
      AppFeedback.showError(context, 'Please select payment received status');
      return;
    }
    if (_pendingWork == true && _pendingWorkNoteC.text.trim().isEmpty) {
      AppFeedback.showError(context, 'Please add note for pending work');
      return;
    }
    if (_paymentReceived == false && _followUpDate == null) {
      AppFeedback.showError(context, 'Please select follow-up date');
      return;
    }
    setState(() => _saving = true);
    context.read<SprinklerLeadCubit>().completeInstallation(
      widget.lead.id,
      technicianName: _techC.text.trim().isEmpty ? null : _techC.text.trim(),
      installationDate: _installDate ?? DateTime.now(),
      notes: _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
      pendingWork: _pendingWork,
      pendingWorkNote: _pendingWork == true
          ? _pendingWorkNoteC.text.trim()
          : null,
      systemTested: _testing,
      paymentReceived: _paymentReceived,
      followUpDate: _paymentReceived == false ? _followUpDate : null,
      customerReview: _customerReviewC.text.trim().isEmpty
          ? null
          : _customerReviewC.text.trim(),
      photos: _photos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (state is SprinklerLeadSaved) Navigator.pop(context, state.lead);
        if (state is SprinklerLeadError) {
          if (!mounted) return;
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
              color: AppColors.surface,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Complete Installation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LeadTheme.bg,
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
        body: _buildEditableBody(),
      ),
    );
  }

  Widget _buildEditableBody() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _CustomerBanner(lead: widget.lead),
        const SizedBox(height: 10),

        if (widget.lead.dealData.finalDealAmount != null)
          _InfoBanner(
            svgAsset: AppSvgAssets.handshake,
            color: AppColors.success,
            text:
                'Deal: ₹${widget.lead.dealData.finalDealAmount!.toStringAsFixed(0)}'
                '  |  Advance: ₹${widget.lead.dealData.advancePayment?.toStringAsFixed(0) ?? "0"}',
          ),

        CompactCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Installation Completed Form'),
              const SizedBox(height: 8),
              _YesNoSelector(
                title: 'Pending Work',
                value: _pendingWork,
                onChanged: (v) => setState(() {
                  _pendingWork = v;
                  if (!v) _pendingWorkNoteC.clear();
                }),
              ),
              if (_pendingWork == true) ...[
                const SizedBox(height: 8),
                _Field(
                  _pendingWorkNoteC,
                  'Pending work note',
                  AppSvgAssets.fileText,
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 10),
              _YesNoSelector(
                title: 'Testing',
                value: _testing,
                required: true,
                onChanged: (v) => setState(() => _testing = v),
              ),
              const SizedBox(height: 10),
              _YesNoSelector(
                title: 'Payment Received',
                value: _paymentReceived,
                required: true,
                onChanged: (v) => setState(() {
                  _paymentReceived = v;
                  if (v) _followUpDate = null;
                }),
              ),
              if (_paymentReceived == false) ...[
                const SizedBox(height: 8),
                _DateTile(
                  date: _followUpDate,
                  onTap: _pickFollowUpDate,
                  label: 'Follow-up Date',
                  emptyText: 'Tap to select follow-up date',
                ),
              ],
            ],
          ),
        ),

        CompactCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Installation Details'),
              const SizedBox(height: 10),
              _Field(_techC, 'Technician Name', AppSvgAssets.cog),
              const SizedBox(height: 8),
              _DateTile(
                date: _installDate,
                onTap: _pickInstallDate,
                label: 'Installation Date',
                emptyText: 'Tap to select date',
              ),
            ],
          ),
        ),

        CompactCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('After Photos'),
              const SizedBox(height: 8),
              SpkPhotoPicker(
                existingUrls: widget.lead.installPhotoPaths,
                onChanged: (p) => setState(() => _photos = p),
                maxPhotos: 10,
                label: 'After installation photos',
                required: false,
              ),
            ],
          ),
        ),

        CompactCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Customer Review & Notes'),
              const SizedBox(height: 8),
              _Field(
                _customerReviewC,
                'Customer Review',
                AppSvgAssets.fileText,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              _Field(
                _notesC,
                'Additional notes...',
                AppSvgAssets.fileText,
                maxLines: 2,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        _SaveBtn(
          saving: _saving,
          onTap: _save,
          label: '✓  Mark Installation Complete',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _CustomerBanner extends StatelessWidget {
  final SprinklerLeadModel lead;
  const _CustomerBanner({required this.lead});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LeadTheme.secondary.withOpacity(0.06),
        border: Border.all(color: LeadTheme.secondary.withOpacity(0.2)),
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
                  lead.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LeadTheme.textPrimary,
                  ),
                ),
                Text(
                  '${lead.phone}  ·  ${lead.address}',
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
}

class _InfoBanner extends StatelessWidget {
  final String svgAsset;
  final Color color;
  final String text;
  const _InfoBanner({
    required this.svgAsset,
    required this.color,
    required this.text,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppSvgIcon(svgAsset, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController c;
  final String label;
  final String svgAsset;
  final int maxLines;
  const _Field(this.c, this.label, this.svgAsset, {this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: LeadTheme.textSecondary,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  final String label;
  final String emptyText;
  const _DateTile({
    required this.date,
    required this.onTap,
    required this.label,
    required this.emptyText,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: date != null ? Colors.teal.shade50 : LeadTheme.surface,
          border: Border.all(
            color: date != null ? Colors.teal.shade300 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AppSvgIcon(
              AppSvgAssets.calendarDays,
              size: 16,
              color: date != null ? Colors.teal : LeadTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: LeadTheme.textSecondary,
                  ),
                ),
                Text(
                  date == null
                      ? emptyText
                      : '${date!.day}/${date!.month}/${date!.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: date != null ? Colors.teal : LeadTheme.textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppSvgIcon(
              date != null
                  ? AppSvgAssets.circleCheckBig
                  : AppSvgAssets.chevronRight,
              size: 14,
              color: date != null ? Colors.teal : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _YesNoSelector extends StatelessWidget {
  final String title;
  final bool? value;
  final bool required;
  final ValueChanged<bool> onChanged;

  const _YesNoSelector({
    required this.title,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$title *' : title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: LeadTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _YesNoChip(
                label: 'Yes',
                selected: value == true,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _YesNoChip(
                label: 'No',
                selected: value == false,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _YesNoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YesNoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? LeadTheme.secondary.withOpacity(0.12)
              : LeadTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? LeadTheme.secondary : Colors.grey.shade300,
            width: selected ? 1.3 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? LeadTheme.secondary : LeadTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  final String label;
  const _SaveBtn({
    required this.saving,
    required this.onTap,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: saving ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: LeadTheme.secondary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
