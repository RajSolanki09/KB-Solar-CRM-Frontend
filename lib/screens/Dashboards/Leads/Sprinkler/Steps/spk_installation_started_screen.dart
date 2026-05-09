import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/Helper/spk_photo_picker.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import '../../../../../Helper/picked_photo.dart';
import 'package:solar_project/core/app_colors.dart';

class SpkInstallationStartedScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  final bool isEditing;
  const SpkInstallationStartedScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });

  @override
  State<SpkInstallationStartedScreen> createState() =>
      _SpkInstallationStartedScreenState();
}

class _SpkInstallationStartedScreenState
    extends State<SpkInstallationStartedScreen> {
  final _notesC = TextEditingController();
  bool _saving = false;
  DateTime? _startDate;
  TimeOfDay? _arrivalTime;
  List<PickedPhoto> _beforePhotos = [];

  @override
  void initState() {
    super.initState();
    _notesC.text = widget.lead.installationData.notes ?? '';
    _startDate = widget.lead.installationData.startedAt;
    _arrivalTime = widget.lead.installationData.startedAt != null
        ? TimeOfDay.fromDateTime(widget.lead.installationData.startedAt!)
        : null;
  }

  @override
  void dispose() {
    _notesC.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: LeadTheme.primary)),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _startDate = d);
  }

  Future<void> _pickArrivalTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _arrivalTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: LeadTheme.primary)),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => _arrivalTime = t);
  }

  void _save() {
    setState(() => _saving = true);
    final notes = _notesC.text.trim().isEmpty ? null : _notesC.text.trim();
    final date = _startDate ?? DateTime.now();
    final time = _arrivalTime ?? TimeOfDay.now();
    final startedAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    context.read<SprinklerLeadCubit>().saveInstallationStarted(
      widget.lead.id,
      startedAt: startedAt,
      notes: notes,
      beforePhotos: _beforePhotos,
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
          title: Text(
            widget.isEditing
                ? 'Edit Installation Started'
                : 'Installation Started',
            style: const TextStyle(
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
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _customerBanner(widget.lead),
            const SizedBox(height: 16),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Arrival Details'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickStartDate,
                    child: _dateTile(
                      AppSvgAssets.calendarDays,
                      'Start Date',
                      _startDate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickArrivalTime,
                    child: _timeTile(_arrivalTime),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Before Installation Photos'),
                  const SizedBox(height: 10),
                  SpkPhotoPicker(
                    existingUrls: widget.lead.installationData.beforePhotos,
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
                    _notesC,
                    'Notes about installation start...',
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

Widget _customerBanner(SprinklerLeadModel lead) => CompactCard(
  child: Row(
    children: [
      AppSvgIcon(AppSvgAssets.userRound, size: 20, color: LeadTheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lead.customerName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              lead.phone,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    ],
  ),
);

Widget _field(
  TextEditingController controller,
  String hint,
  String icon, {
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: AppSvgIcon(icon, size: 18, color: LeadTheme.secondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    ),
  );
}

Widget _saveBtn(bool loading, VoidCallback onPressed, String label) => SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: LeadTheme.secondary,
      foregroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    onPressed: loading ? null : onPressed,
    child: loading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              color: AppColors.surface,
              strokeWidth: 2,
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
  ),
);

Widget _dateTile(
  String icon,
  String title,
  DateTime? date, {
  Color color = AppColors.primary,
}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300),
  ),
  child: Row(
    children: [
      AppSvgIcon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Tap to select date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: date != null ? Colors.black : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);

Widget _timeTile(TimeOfDay? time) {
  final formatted = time != null
      ? '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}'
      : 'Tap to select time';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      children: [
        AppSvgIcon(AppSvgAssets.clock, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arrival Time',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                formatted,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: time != null ? Colors.black : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
