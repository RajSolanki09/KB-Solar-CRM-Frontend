// lib/screens/Solar/Steps/installation_screen.dart
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
import 'package:solar_project/core/app_colors.dart';

import '../../../../../Helper/picked_photo.dart';

// ── Installation Completed Screen ─────────────────────────────────────────────
class SolarInstallationScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarInstallationScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarInstallationScreen> createState() => _CompletedState();
}

class _CompletedState extends State<SolarInstallationScreen> {
  final notesC = TextEditingController();
  final structureVendorNameC = TextEditingController();
  final wiringVendorNameC = TextEditingController();

  bool _systemTested = false;
  bool _customerSigned = false;
  bool _structureDone = false;
  bool _wiringDone = false;
  bool _panelDone = false;
  bool _inverterAcDone = false;
  bool _fullyComplete = false;
  bool _saving = false;
  List<PickedPhoto> _afterPhotos = [];
  DateTime? _completedDate;
  DateTime? _structureCompletedDate;
  DateTime? _wiringCompletedDate;

  @override
  void initState() {
    super.initState();
    final d = widget.lead.installationData;
    notesC.text = widget.lead.installationData.notes ?? '';
    _systemTested = widget.lead.systemTested;
    _customerSigned = widget.lead.customerSigned;
    _structureDone = d.structureDone;
    _wiringDone = d.wiringDone;
    _panelDone = d.plumeDone;
    _inverterAcDone = d.inverterAcDone;
    _fullyComplete = d.fullyComplete;
    structureVendorNameC.text = d.structureVendorName ?? '';
    wiringVendorNameC.text = d.wiringVendorName ?? '';
    _completedDate = d.completedDate;
    _structureCompletedDate = DateTime.tryParse(d.structureVendorCo ?? '');
    _wiringCompletedDate = DateTime.tryParse(d.wiringVendorCo ?? '');
  }

  @override
  void dispose() {
    notesC.dispose();
    structureVendorNameC.dispose();
    wiringVendorNameC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _completedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: LeadTheme.primary)),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _completedDate = d);
  }

  Future<void> _pickVendorCompletedDate({required bool isStructure}) async {
    final current = isStructure
        ? _structureCompletedDate
        : _wiringCompletedDate;
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: LeadTheme.primary)),
        child: child!,
      ),
    );
    if (d == null || !mounted) return;
    setState(() {
      if (isStructure) {
        _structureCompletedDate = d;
      } else {
        _wiringCompletedDate = d;
      }
    });
  }

  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final notes = notesC.text.trim().isEmpty ? null : notesC.text.trim();
    final structureVendorName = structureVendorNameC.text.trim().isEmpty
        ? null
        : structureVendorNameC.text.trim();
    final structureVendorCo = _structureCompletedDate?.toIso8601String();
    final wiringVendorName = wiringVendorNameC.text.trim().isEmpty
        ? null
        : wiringVendorNameC.text.trim();
    final wiringVendorCo = _wiringCompletedDate?.toIso8601String();

    if (widget.isEditing) {
      cubit.editInstallation(
        id,
        systemTested: _systemTested,
        customerSigned: _customerSigned,
        structureDone: _structureDone,
        wiringDone: _wiringDone,
        plumeDone: _panelDone,
        inverterAcDone: _inverterAcDone,
        fullyComplete: _fullyComplete,
        completedDate: _completedDate,
        structureVendorName: structureVendorName,
        structureVendorCo: structureVendorCo,
        wiringVendorName: wiringVendorName,
        wiringVendorCo: wiringVendorCo,
        notes: notes,
        afterPhotos: _afterPhotos,
      );
    } else {
      cubit.saveInstallation(
        id,
        systemTested: _systemTested,
        customerSigned: _customerSigned,
        structureDone: _structureDone,
        wiringDone: _wiringDone,
        plumeDone: _panelDone,
        inverterAcDone: _inverterAcDone,
        fullyComplete: _fullyComplete,
        completedDate: _completedDate,
        structureVendorName: structureVendorName,
        structureVendorCo: structureVendorCo,
        wiringVendorName: wiringVendorName,
        wiringVendorCo: wiringVendorCo,
        notes: notes,
        afterPhotos: _afterPhotos,
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
            widget.isEditing ? 'Edit Installation' : 'Installation Completed',
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

            // ── Completion Checklist ──────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Completion Checklist'),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Structure Done',
                    _structureDone,
                    AppSvgAssets.hammer,
                    onChanged: (v) => setState(() => _structureDone = v),
                  ),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Wiring Done',
                    _wiringDone,
                    AppSvgAssets.zap,
                    onChanged: (v) => setState(() => _wiringDone = v),
                  ),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Panel Done',
                    _panelDone,
                    AppSvgAssets.sunMedium,
                    onChanged: (v) => setState(() => _panelDone = v),
                  ),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Inverter / AC / DC Done',
                    _inverterAcDone,
                    AppSvgAssets.gauge,
                    onChanged: (v) => setState(() => _inverterAcDone = v),
                  ),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Fully Project Complete',
                    _fullyComplete,
                    AppSvgAssets.trophy,
                    onChanged: (v) => setState(() => _fullyComplete = v),
                  ),
                  const SizedBox(height: 12),
                  _checkTile(
                    'System Tested & Working',
                    _systemTested,
                    AppSvgAssets.zap,
                    onChanged: (v) => setState(() => _systemTested = v),
                  ),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Customer Signature Received',
                    _customerSigned,
                    AppSvgAssets.pencil,
                    onChanged: (v) => setState(() => _customerSigned = v),
                  ),
                ],
              ),
            ),

            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Vendor Details'),
                  const SizedBox(height: 8),
                  _field(
                    structureVendorNameC,
                    'Structure Vendor Name',
                    AppSvgAssets.building2,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickVendorCompletedDate(isStructure: true),
                    child: _dateTile(
                      AppSvgAssets.calendarCheck,
                      'Structure Completed Date',
                      _structureCompletedDate,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field(
                    wiringVendorNameC,
                    'Wiring Vendor Name',
                    AppSvgAssets.building2,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickVendorCompletedDate(isStructure: false),
                    child: _dateTile(
                      AppSvgAssets.calendarCheck,
                      'Wiring Completed Date',
                      _wiringCompletedDate,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // ── After Photos (shown after vendor details) ──────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _photoSectionHeader(
                    color: AppColors.success,
                    title: 'After Installation Photos',
                    subtitle:
                        'Capture after completion — panels on roof, inverter, wiring done',
                  ),
                  const SizedBox(height: 10),
                  SpkPhotoPicker(
                    existingUrls: widget.lead.afterPhotoPaths,
                    label: 'After Photos',
                    maxPhotos: 10,
                    onChanged: (pics) => _afterPhotos = pics,
                  ),
                ],
              ),
            ),

            // ── Completion Date (shown after vendor details) ───────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Completion Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: _dateTile(
                      AppSvgAssets.circleCheckBig,
                      'Installation Completed On',
                      _completedDate,
                      color: AppColors.success,
                    ),
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
                  _field(
                    notesC,
                    'Installation notes, issues, remarks...',
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
              widget.isEditing
                  ? 'Update Installation'
                  : 'Mark Installation Complete',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

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

Widget _checkTile(
  String label,
  bool value,
  String svgAsset, {
  required ValueChanged<bool> onChanged,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  decoration: BoxDecoration(
    color: LeadTheme.surface,
    border: Border.all(color: value ? AppColors.success : AppColors.divider),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          AppSvgIcon(
            svgAsset,
            size: 18,
            color: value ? AppColors.success : LeadTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value ? AppColors.success : LeadTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _yesNoButton(
              label: 'Yes',
              selected: value,
              onTap: () => onChanged(true),
              activeColor: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _yesNoButton(
              label: 'No',
              selected: !value,
              onTap: () => onChanged(false),
              activeColor: AppColors.error,
            ),
          ),
        ],
      ),
    ],
  ),
);

Widget _yesNoButton({
  required String label,
  required bool selected,
  required VoidCallback onTap,
  required Color activeColor,
}) => GestureDetector(
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: selected ? activeColor.withValues(alpha: 0.12) : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: selected
            ? activeColor.withValues(alpha: 0.65)
            : Colors.grey.shade300,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? activeColor : LeadTheme.textSecondary,
      ),
    ),
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
