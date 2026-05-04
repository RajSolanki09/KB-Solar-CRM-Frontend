// lib/screens/Dashboards/Leads/Sprinkler/Steps/visit_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/app_colors.dart';

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
    id: j['_id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class SprinklerVisitScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SprinklerVisitScreen({super.key, required this.lead});

  @override
  State<SprinklerVisitScreen> createState() => _SprinklerVisitScreenState();
}

class _SprinklerVisitScreenState extends State<SprinklerVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _visitDateCtrl = TextEditingController();
  final _visitTimeCtrl = TextEditingController();
  final _fieldNotesCtrl = TextEditingController();
  final _waterNotesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Photos
  final List<PickedPhoto> _photos = [];

  // Sales person dropdown
  List<_SalesPerson> _salesPersons = [];
  bool _salesLoading = false;
  _SalesPerson? _selectedSalesPerson;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillExisting();
    _fetchSalesPersons();
  }

  @override
  void dispose() {
    _visitDateCtrl.dispose();
    _visitTimeCtrl.dispose();
    _fieldNotesCtrl.dispose();
    _waterNotesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Pre-fill from existing data ──────────────────────────────────────────
  void _prefillExisting() {
    final v = widget.lead.siteVisitData;
    if (v.visitDate != null) {
      _selectedDate = v.visitDate;
      _visitDateCtrl.text = DateFormat('dd/MM/yyyy').format(v.visitDate!);
    }
    if (v.visitTime != null && v.visitTime!.isNotEmpty) {
      _visitTimeCtrl.text = v.visitTime!;
    }
    if (v.fieldConditionNotes != null)
      _fieldNotesCtrl.text = v.fieldConditionNotes!;
    if (v.waterAvailabilityNotes != null)
      _waterNotesCtrl.text = v.waterAvailabilityNotes!;
    if (v.notes != null) _notesCtrl.text = v.notes!;
    // salesPerson name is pre-selected after list loads — handled in _fetchSalesPersons
  }

  // ── Fetch sales persons from backend ─────────────────────────────────────
  Future<void> _fetchSalesPersons() async {
    setState(() => _salesLoading = true);
    try {
      final res = await DioClient().dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminStaff,
        queryParameters: {'role': 'sales', 'limit': 100},
      );
      final body = res.data ?? {};
      List<dynamic> raw = [];
      for (final key in ['staff', 'data', 'users', 'members', 'results']) {
        if (body[key] is List) {
          raw = body[key] as List;
          break;
        }
      }
      final list = raw
          .map((e) => _SalesPerson.fromJson(e as Map<String, dynamic>))
          .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _salesPersons = list;
          // Pre-select if the lead already has a sales person name
          final existingName = widget.lead.siteVisitData.salesPerson;
          if (existingName != null && existingName.isNotEmpty) {
            try {
              _selectedSalesPerson = list.firstWhere(
                (s) => s.name.toLowerCase() == existingName.toLowerCase(),
              );
            } catch (_) {
              // No exact match — leave unselected
            }
          }
        });
      }
    } on DioException catch (e) {
      debugPrint('FetchSalesPersons DioError: ${e.message}');
    } catch (e) {
      debugPrint('FetchSalesPersons error: $e');
    } finally {
      if (mounted) setState(() => _salesLoading = false);
    }
  }

  // ── Date picker ──────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _visitDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // ── Time picker ──────────────────────────────────────────────────────────
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
        final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final m = picked.minute.toString().padLeft(2, '0');
        final ampm = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _visitTimeCtrl.text = '$h:$m $ampm';
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // Build 24-hour visitTime string for backend
      String? visitTimeFor24h;
      if (_selectedTime != null) {
        final h = _selectedTime!.hour.toString().padLeft(2, '0');
        final m = _selectedTime!.minute.toString().padLeft(2, '0');
        visitTimeFor24h = '$h:$m';
      } else if (_visitTimeCtrl.text.isNotEmpty) {
        visitTimeFor24h = _visitTimeCtrl.text;
      }

      await context.read<SprinklerLeadCubit>().saveSiteVisit(
        widget.lead.id,
        visitDate: _selectedDate,
        visitTime: visitTimeFor24h,
        // Send the selected person's name (backend stores it as string)
        salesPerson: _selectedSalesPerson?.name,
        fieldConditionNotes: _fieldNotesCtrl.text.trim().isEmpty
            ? null
            : _fieldNotesCtrl.text.trim(),
        waterAvailabilityNotes: _waterNotesCtrl.text.trim().isEmpty
            ? null
            : _waterNotesCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        photos: _photos,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: LeadTheme.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Schedule Site Visit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.chevronLeft,
            color: Colors.white,
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
            _buildCard(
              title: 'Visit Details',
              icon: AppSvgAssets.mapPin,
              children: [
                // Visit Date
                _buildLabel('Visit Date', required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _visitDateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: _inputDecoration(
                    suffixIcon: const AppSvgIcon(
                      AppSvgAssets.calendarDays,
                      size: 18,
                      color: AppColors.textSecondary),
                    ),
                    hint: 'Select visit date',
                  ),
                ),
                const SizedBox(height: 14),

                // Visit Time
                _buildLabel('Visit Time', required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _visitTimeCtrl,
                  readOnly: true,
                  onTap: _pickTime,
                  decoration: _inputDecoration(
                    suffixIcon: const AppSvgIcon(
                      AppSvgAssets.clock,
                      size: 18,
                      color: AppColors.textSecondary),
                    ),
                    hint: 'Select visit time',
                  ),
                ),
                const SizedBox(height: 14),

                // ── Sales Person Dropdown ─────────────────────────────────
                _buildLabel('Sales Person Assigned', required: false),
                const SizedBox(height: 6),
                _buildSalesPersonDropdown(),
              ],
            ),
            const SizedBox(height: 14),

            _buildLabel('Additional Notes', required: false),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _inputDecoration(hint: 'Any other remarks…'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  // ── Sales Person Dropdown ─────────────────────────────────────────────────
  Widget _buildSalesPersonDropdown() {
    if (_salesLoading) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LeadTheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading sales persons…',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_salesPersons.isEmpty) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            AppSvgIcon(
              AppSvgAssets.userRound,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'No sales persons found',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<_SalesPerson>(
      value: _selectedSalesPerson,
      decoration: _inputDecoration(
        hint: 'Select sales person (optional)',
        prefixIcon: AppSvgIcon(
          AppSvgAssets.userRound,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
      isExpanded: true,
      icon: AppSvgIcon(
        AppSvgAssets.chevronDown,
        size: 16,
        color: AppColors.textSecondary,
      ),
      items: [
        // "None" option to clear the selection
        DropdownMenuItem<_SalesPerson>(
          value: null,
          child: Text(
            'None',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ..._salesPersons.map(
          (s) => DropdownMenuItem<_SalesPerson>(
            value: s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                  ),
                ),
                if (s.phone.isNotEmpty)
                  Text(
                    s.phone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      selectedItemBuilder: (_) => [
        // Selected display for null (None)
        Text(
          'None',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        ..._salesPersons.map(
          (s) => Text(
            s.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: (val) => setState(() => _selectedSalesPerson = val),
    );
  }

  // ── Save Bar ──────────────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: LeadTheme.secondary,
            foregroundColor: Colors.white,
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
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Save Visit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildCard({
    required String title,
    required String icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: LeadTheme.secondary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: LeadTheme.secondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                AppSvgIcon(icon, size: 14, color: LeadTheme.secondary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LeadTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildLabel(String text, {bool required = false}) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary),
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

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
    filled: true,
    fillColor: Colors.white,
    prefixIcon: prefixIcon != null
        ? Padding(padding: const EdgeInsets.all(13), child: prefixIcon)
        : null,
    suffixIcon: suffixIcon != null
        ? Padding(padding: const EdgeInsets.all(13), child: suffixIcon)
        : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderLight)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderLight)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: LeadTheme.secondary, width: 1.5),
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
}






