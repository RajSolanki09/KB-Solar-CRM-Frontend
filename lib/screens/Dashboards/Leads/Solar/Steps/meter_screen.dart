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

class SolarMeterScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarMeterScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarMeterScreen> createState() => _State();
}

class _State extends State<SolarMeterScreen> {
  DateTime? applicationDate, inspectionDate, installedDate;
  bool? gebFileHandover;
  String? meterInstallationStatus;
  String? systemRunStatus;
  final notesC = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    applicationDate = widget.lead.meterApplicationDate;
    inspectionDate = widget.lead.meterInspectionDate;
    installedDate = widget.lead.meterInstalledDate;
    gebFileHandover = widget.lead.meterGebFileHandover;
    meterInstallationStatus = widget.lead.meterInstallationStatus;
    systemRunStatus = widget.lead.meterSystemRunStatus;
    notesC.text = widget.lead.meterData.notes ?? '';
  }

  @override
  void dispose() {
    notesC.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime? init) => showDatePicker(
    context: context,
    initialDate: init ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );

  void _save() {
    setState(() => _saving = true);

    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final notes = notesC.text.trim().isEmpty ? null : notesC.text.trim();

    if (widget.isEditing) {
      cubit.editMeter(
        id,
        applicationDate: applicationDate,
        inspectionDate: inspectionDate,
        installedDate: installedDate,
        gebFileHandover: gebFileHandover,
        meterInstallationStatus: meterInstallationStatus,
        systemRunStatus: systemRunStatus,
        notes: notes,
      );
    } else {
      cubit.saveMeter(
        id,
        applicationDate: applicationDate,
        inspectionDate: inspectionDate,
        installedDate: installedDate,
        gebFileHandover: gebFileHandover,
        meterInstallationStatus: meterInstallationStatus,
        systemRunStatus: systemRunStatus,
        notes: notes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDone =
        inspectionDate != null &&
        installedDate != null &&
        meterInstallationStatus == 'done' &&
        systemRunStatus == 'done';

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
            widget.isEditing ? 'Edit Net Meter Process' : 'Net Meter Process',
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

            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Meter Process'),
                  const SizedBox(height: 10),
                  _meterDateTile(
                    'Inspection Date',
                    inspectionDate,
                    AppSvgAssets.search,
                    onTap: () async {
                      final d = await _pick(inspectionDate);
                      if (d != null) setState(() => inspectionDate = d);
                    },
                  ),
                  const SizedBox(height: 8),
                  _yesNoTile(
                    title: 'GEB File Handover / Upload',
                    value: gebFileHandover,
                    onChanged: (v) => setState(() => gebFileHandover = v),
                  ),
                  const SizedBox(height: 8),
                  _statusDropdownTile(
                    title: 'Meter Installation',
                    value: meterInstallationStatus,
                    onChanged: (v) {
                      setState(() => meterInstallationStatus = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _statusDropdownTile(
                    title: 'System Run',
                    value: systemRunStatus,
                    onChanged: (v) {
                      setState(() => systemRunStatus = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _meterDateTile(
                    'Meter Installation Date',
                    installedDate,
                    AppSvgAssets.gauge,
                    onTap: () async {
                      final d = await _pick(installedDate);
                      if (d != null) setState(() => installedDate = d);
                    },
                  ),
                ],
              ),
            ),

            if (allDone)
              _infoCard(
                AppSvgAssets.circleCheckBig,
                AppColors.success,
                'All meter process stages completed!',
              ),

            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _field(
                    notesC,
                    'Meter process notes...',
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
              widget.isEditing ? 'Update Meter Process' : 'Save Meter Process',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _meterDateTile(
  String label,
  DateTime? date,
  String svgAsset, {
  required VoidCallback onTap,
}) {
  final done = date != null;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: done ? Colors.green.shade50 : LeadTheme.surface,
        border: Border.all(
          color: done ? Colors.green.shade300 : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            svgAsset,
            size: 18,
            color: done ? Colors.green : LeadTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: done
                        ? Colors.green.shade700
                        : LeadTheme.textSecondary,
                  ),
                ),
                Text(
                  date == null
                      ? 'Tap to set date'
                      : '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: done ? Colors.green.shade800 : LeadTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          AppSvgIcon(
            done ? AppSvgAssets.circleCheckBig : AppSvgAssets.plus,
            size: 20,
            color: done ? Colors.green : AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

Widget _yesNoTile({
  required String title,
  required bool? value,
  required ValueChanged<bool> onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: LeadTheme.surface,
      border: Border.all(color: AppColors.borderLight),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: LeadTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChoiceChip(
              label: const Text('Yes'),
              selected: value == true,
              onSelected: (_) => onChanged(true),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('No'),
              selected: value == false,
              onSelected: (_) => onChanged(false),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _statusDropdownTile({
  required String title,
  required String? value,
  required ValueChanged<String?> onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: LeadTheme.surface,
      border: Border.all(color: AppColors.borderLight),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: LeadTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: const [
            DropdownMenuItem(value: 'done', child: Text('Done')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Select status',
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
          ),
        ),
      ],
    ),
  );
}

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

Widget _field(
  TextEditingController c,
  String label,
  String svgAsset, {
  int maxLines = 1,
}) {
  return TextField(
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
}

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

Widget _infoCard(String svgAsset, Color color, String message) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        AppSvgIcon(svgAsset, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9)),
          ),
        ),
      ],
    ),
  );
}




