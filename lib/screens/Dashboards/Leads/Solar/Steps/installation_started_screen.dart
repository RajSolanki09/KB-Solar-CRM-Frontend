import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/Helper/spk_photo_picker.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';

import '../../../../../Helper/picked_photo.dart';
import 'package:solar_project/core/app_colors.dart';

class SolarInstallationStartedScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarInstallationStartedScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });

  @override
  State<SolarInstallationStartedScreen> createState() => _StartedState();
}

class _StartedState extends State<SolarInstallationStartedScreen> {
  final teamC = TextEditingController();
  final notesC = TextEditingController();
  bool _saving = false;
  List<PickedPhoto> _beforePhotos = [];
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    teamC.text = widget.lead.installationTeam ?? '';
    notesC.text = widget.lead.installationData.notes ?? '';
    _startDate = widget.lead.installationData.startDate;
  }

  @override
  void dispose() {
    teamC.dispose();
    notesC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: LeadTheme.primary)),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _startDate = d);
  }

  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final team = teamC.text.trim().isEmpty ? null : teamC.text.trim();
    final notes = notesC.text.trim().isEmpty ? null : notesC.text.trim();

    if (widget.isEditing) {
      cubit.editInstallation(
        id,
        teamAssigned: team,
        notes: notes,
        beforePhotos: _beforePhotos,
      );
    } else {
      cubit.saveInstallationStarted(
        id,
        teamAssigned: team,
        startDate: _startDate,
        notes: notes,
        beforePhotos: _beforePhotos,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) Navigator.pop(context, state.lead);
        if (state is SolarLeadError) {
          if (!mounted) return;
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
                ? 'Edit Installation Start'
                : 'Installation Started',
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
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _infoBanner(widget.lead),
            const SizedBox(height: 10),
            if (widget.lead.installationTeamMemberNames.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.lead.installationTeamMemberNames
                    .map((name) => _assignedTeamChip(name))
                    .toList(),
              )
            else if ((widget.lead.installationTeam ?? '').isNotEmpty)
              _assignedTeamChip(widget.lead.installationTeam!),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Team / Technician'),
                  const SizedBox(height: 8),
                  _field(teamC, 'Technician / Team Name', AppSvgAssets.cog),
                ],
              ),
            ),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Start Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: _dateTile(
                      AppSvgAssets.play,
                      'Installation Started On',
                      _startDate,
                      color: AppColors.solar,
                    ),
                  ),
                ],
              ),
            ),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _photoSectionHeader(
                    color: AppColors.solar,
                    title: 'Before Installation Photos',
                    subtitle:
                        'Capture before starting — roof, panels unboxed, existing wiring',
                  ),
                  const SizedBox(height: 10),
                  SpkPhotoPicker(
                    existingUrls: widget.lead.beforePhotoPaths,
                    label: 'Before Photos',
                    maxPhotos: 10,
                    onChanged: (pics) => _beforePhotos = pics,
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
                    'Notes about installation start...',
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
                  ? 'Update Installation Start'
                  : 'Mark Installation Started',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Widget _assignedTeamChip(String name) => Container(
  margin: const EdgeInsets.only(bottom: 10),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: LeadTheme.primary.withValues(alpha: 0.07),
    border: Border.all(color: LeadTheme.primary.withValues(alpha: 0.25)),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    children: [
      const AppSvgIcon(AppSvgAssets.users, size: 16, color: LeadTheme.primary),
      const SizedBox(width: 8),
      Text(
        'Assigned: $name',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: LeadTheme.primary,
        ),
      ),
    ],
  ),
);

Widget _photoSectionHeader({
  required Color color,
  required String title,
  required String subtitle,
}) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      margin: const EdgeInsets.only(top: 3, right: 8),
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: LeadTheme.textMuted),
          ),
        ],
      ),
    ),
  ],
);

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

Widget _dateTile(
  String svgAsset,
  String label,
  DateTime? date, {
  Color color = AppColors.success,
}) {
  final c = date != null ? color : LeadTheme.textSecondary;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: date != null ? color.withValues(alpha: 0.08) : LeadTheme.surface,
      border: Border.all(
        color: date != null
            ? color.withValues(alpha: 0.4)
            : Colors.grey.shade300,
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
          color: date != null ? color : AppColors.textLight,
        ),
      ],
    ),
  );
}

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
  child: ElevatedButton(
    onPressed: saving ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: LeadTheme.primary,
      foregroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      minimumSize: const Size.fromHeight(52),
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
