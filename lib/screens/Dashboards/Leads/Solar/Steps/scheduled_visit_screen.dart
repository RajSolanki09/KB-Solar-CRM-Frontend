import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/core/app_colors.dart';

// ── Sales person fetched from backend ────────────────────────────────────────
class _SalesPerson {
  final String id;
  final String name;
  final String phone;
  const _SalesPerson({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory _SalesPerson.fromJson(Map<String, dynamic> j) => _SalesPerson(
    id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? j['fullName']?.toString() ?? '',
    phone: j['phone']?.toString() ?? j['mobile']?.toString() ?? '',
  );
}
// ─────────────────────────────────────────────────────────────────────────────

class SolarVisitScheduledScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarVisitScheduledScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarVisitScheduledScreen> createState() => _State();
}

class _State extends State<SolarVisitScheduledScreen> {
  final _formKey = GlobalKey<FormState>();
  final notesC = TextEditingController();
  final _visitDateCtrl = TextEditingController();
  final _visitTimeCtrl = TextEditingController();

  DateTime? visitDate;
  TimeOfDay? visitTime;

  // Sales person dropdown
  List<_SalesPerson> _salesPersons = [];
  _SalesPerson? _selectedSalesPerson; // null = "None"
  bool _loadingSalesPersons = true;

  bool _saving = false;

  // ── Format helpers ────────────────────────────────────────────────────────
  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  void initState() {
    super.initState();

    // ── Pre-fill notes ────────────────────────────────────────────────────
    // visitNotes getter → visitScheduleData.notes
    notesC.text = widget.lead.visitNotes ?? '';

    // ── Pre-fill date & time ──────────────────────────────────────────────
    // visitDate getter → visitScheduleData.visitDate (already .toLocal() via _parseDate)
    final existing = widget.lead.visitDate;
    if (existing != null) {
      visitDate = existing;
      _visitDateCtrl.text = _formatDate(existing);

      // Time is stored inside visitDate — extract if non-zero
      // Use local time (already converted by _parseDate → .toLocal())
      if (existing.hour != 0 || existing.minute != 0) {
        visitTime = TimeOfDay(hour: existing.hour, minute: existing.minute);
        _visitTimeCtrl.text = _formatTime(visitTime!);
      }
    }

    _fetchSalesPersons();
  }

  @override
  void dispose() {
    notesC.dispose();
    _visitDateCtrl.dispose();
    _visitTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesPersons() async {
    try {
      final res = await DioClient().dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminStaff,
        queryParameters: {'role': 'sales', 'limit': 100},
      );
      final body = res.data ?? {};
      List<dynamic> raw = [];
      for (final key in ['staff', 'users', 'data', 'members', 'results']) {
        if (body[key] is List) {
          raw = body[key] as List;
          break;
        }
      }
      final list = raw
          .map((e) => _SalesPerson.fromJson(e as Map<String, dynamic>))
          .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _salesPersons = list;
          _loadingSalesPersons = false;

          // Pre-select if editing and lead already has a sales person name
          if (widget.lead.salesAssigned != null &&
              widget.lead.salesAssigned!.isNotEmpty) {
            try {
              _selectedSalesPerson = list.firstWhere(
                (p) =>
                    p.name.toLowerCase() ==
                    widget.lead.salesAssigned!.toLowerCase(),
              );
            } catch (_) {
              // No exact match — leave as "None"
              _selectedSalesPerson = null;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('FetchSalesPersons error: $e');
      if (mounted) setState(() => _loadingSalesPersons = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: visitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        visitDate = d;
        _visitDateCtrl.text = _formatDate(d);
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: visitTime ?? TimeOfDay.now(),
    );
    if (t != null) {
      setState(() {
        visitTime = t;
        _visitTimeCtrl.text = _formatTime(t);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (visitDate == null) {
      AppFeedback.showError(context, 'Please select a visit date');
      return;
    }

    setState(() => _saving = true);

    // Combine date + time into one local DateTime, repo converts to UTC before sending
    final DateTime combinedDateTime;
    if (visitTime != null) {
      combinedDateTime = DateTime(
        visitDate!.year,
        visitDate!.month,
        visitDate!.day,
        visitTime!.hour,
        visitTime!.minute,
      );
    } else {
      // No time picked — use date only (midnight local)
      combinedDateTime = DateTime(
        visitDate!.year,
        visitDate!.month,
        visitDate!.day,
      );
    }

    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final salesAssignedId = _selectedSalesPerson?.id; // null = "None"
    // Always send notes — empty string becomes null on backend so clearing works
    final notes = notesC.text.trim().isEmpty ? null : notesC.text.trim();

    if (widget.isEditing) {
      cubit.editVisitSchedule(
        id,
        visitDate: combinedDateTime,
        salesAssignedId: salesAssignedId,
        notes: notes,
      );
    } else {
      cubit.scheduleVisit(
        id,
        visitDate: combinedDateTime,
        salesAssignedId: salesAssignedId,
        notes: notes,
      );
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
        backgroundColor:  AppColors.background,
        appBar: AppBar(
          backgroundColor: LeadTheme.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            widget.isEditing ? 'Edit Visit Schedule' : 'Schedule Site Visit',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.chevronLeft,
              color: AppColors.surface,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Customer info banner ─────────────────────────────────────
              _infoBanner(widget.lead),
              const SizedBox(height: 14),

              // ── Visit Details card ───────────────────────────────────────
              _buildCard(
                title: 'Visit Details',
                icon: AppSvgAssets.calendarDays,
                children: [
                  // Visit Date
                  _buildLabel('Visit Date', required: false),
                  const SizedBox(height: 6),
                  TextFormField(
                    readOnly: true,
                    onTap: _pickDate,
                    controller: _visitDateCtrl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Select visit date',
                      suffixIcon: AppSvgIcon(
                        AppSvgAssets.calendarDays,
                        size: 18,
                        color: visitDate != null
                            ? AppColors.success
                            :  AppColors.textGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Visit Time
                  _buildLabel('Visit Time', required: false),
                  const SizedBox(height: 6),
                  TextFormField(
                    readOnly: true,
                    onTap: _pickTime,
                    controller: _visitTimeCtrl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Select visit time (optional)',
                      suffixIcon: Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: visitTime != null
                            ? LeadTheme.primary
                            :  AppColors.textGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sales Person
                  _buildLabel('Sales Person Assigned', required: false),
                  const SizedBox(height: 6),
                  _salesPersonDropdown(),
                ],
              ),
              const SizedBox(height: 14),

              // ── Notes card ───────────────────────────────────────────────
              _buildCard(
                title: 'Additional Notes',
                icon: AppSvgAssets.fileText,
                children: [
                  _buildLabel('Notes', required: false),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: notesC,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (value.trim().length < 3)
                          return 'Notes must be at least 3 characters';
                        if (value.trim().length > 500)
                          return 'Notes cannot exceed 500 characters';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint: 'Any remarks about this visit…',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildSaveBar(),
      ),
    );
  }

  // ── Bottom save bar ───────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: LeadTheme.primary,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.surface,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.isEditing
                      ? 'Update Visit Schedule'
                      : 'Confirm Visit Scheduled',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Card builder ──────────────────────────────────────────────────────────
  Widget _buildCard({
    required String title,
    required String icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: LeadTheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: LeadTheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                AppSvgIcon(icon, size: 14, color: LeadTheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LeadTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ── Label builder ─────────────────────────────────────────────────────────
  Widget _buildLabel(String text, {bool required = false}) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      children: required
          ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error),
              ),
            ]
          : [],
    ),
  );

  // ── Input decoration ──────────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
    filled: true,
    fillColor: AppColors.surface,
    prefixIcon: prefixIcon != null
        ? Padding(padding: const EdgeInsets.all(13), child: prefixIcon)
        : null,
    suffixIcon: suffixIcon != null
        ? Padding(padding: const EdgeInsets.all(13), child: suffixIcon)
        : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: LeadTheme.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );

  // ── Sales person dropdown widget ──────────────────────────────────────────
  Widget _salesPersonDropdown() {
    // Loading state
    if (_loadingSalesPersons) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color:  AppColors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LeadTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading sales persons…',
              style: TextStyle(fontSize: 13, color: AppColors.background),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_salesPersons.isEmpty) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color:  AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            AppSvgIcon(
              AppSvgAssets.userRound,
              size: 16,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 8),
            Text(
              'No sales persons found',
              style: TextStyle(fontSize: 13, color: AppColors.background),
            ),
          ],
        ),
      );
    }

    // Dropdown
    return DropdownButtonFormField<_SalesPerson?>(
      value: _selectedSalesPerson,
      decoration: _inputDecoration(
        hint: 'Select sales person (optional)',
        prefixIcon: AppSvgIcon(
          AppSvgAssets.userRound,
          size: 16,
          color: AppColors.background,
        ),
      ),
      isExpanded: true,
      icon: AppSvgIcon(
        AppSvgAssets.arrowRight, // swap to chevronDown if you have it
        size: 16,
        color: AppColors.background,
      ),
      items: [
        // "None" option
        DropdownMenuItem<_SalesPerson?>(
          value: null,
          child: Text(
            'None',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.background,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        // Sales persons from backend
        ..._salesPersons.map(
          (person) => DropdownMenuItem<_SalesPerson?>(
            value: person,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (person.phone.isNotEmpty)
                  Text(
                    person.phone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGray,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      // selectedItemBuilder — compact single-line display when closed
      selectedItemBuilder: (_) => [
        Text(
          'None',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.background,
            fontStyle: FontStyle.italic,
          ),
        ),
        ..._salesPersons.map(
          (person) => Text(
            person.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: (val) => setState(() => _selectedSalesPerson = val),
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
}
