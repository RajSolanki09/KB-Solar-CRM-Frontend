// lib/screens/Dashboards/Leads/Sprinkler/Steps/spk_edit_basic_info_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/app_colors.dart';

class SpkEditBasicInfoScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SpkEditBasicInfoScreen({super.key, required this.lead});

  @override
  State<SpkEditBasicInfoScreen> createState() => _SpkEditBasicInfoScreenState();
}

class _SpkEditBasicInfoScreenState extends State<SpkEditBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _villageCtrl;
  late final TextEditingController _farmSizeCtrl;
  late final TextEditingController _cropCtrl;
  late final TextEditingController _referenceNameCtrl;
  late final TextEditingController _noteCtrl;

  String? _selectedWaterSource;
  String? _selectedSource;

  bool _saving = false;

  String? get _selectedSourceCode => _sourceMap[_selectedSource];

  // ── Dropdown options ──────────────────────────────────────────────────────
  static const _waterSourceMap = {
    'Borewell': 'borewell',
    'Canal':    'canal',
    'Tank':     'tank',
    'River':    'river',
    'Other':    'other',
  };
  static const _waterSourceReverseMap = {
    'borewell': 'Borewell',
    'canal':    'Canal',
    'tank':     'Tank',
    'river':    'River',
    'other':    'Other',
  };

  static const _sourceLabels = ['Call', 'Reference', 'Social Media', 'Epc-reference', 'Indiamart', 'Other'];
  static const _sourceMap = {
    'Call':      'call',
    'Reference': 'reference',
    'Social Media': 'social_media',
    'Epc-reference': 'epc_reference',
    'Indiamart': 'indiamart',
    'Walk-in':   'walk-in',
    'Other':     'other',
  };
  static const _sourceReverseMap = {
    'call':      'Call',
    'reference': 'Reference',
    'social_media': 'Social Media',
    'epc_reference': 'Epc-reference',
    'indiamart': 'Indiamart',
    'walk-in':   'Walk-in',
    'other':     'Other',
  };

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _nameCtrl     = TextEditingController(text: l.customerName);
    _phoneCtrl    = TextEditingController(text: l.phone);
    _addressCtrl  = TextEditingController(text: l.address);
    _villageCtrl  = TextEditingController(text: l.village);
    _farmSizeCtrl = TextEditingController(
      text: l.farmSize != null ? l.farmSize.toString() : '',
    );
    _cropCtrl = TextEditingController(text: l.cropType ?? '');
    _referenceNameCtrl = TextEditingController(text: l.referenceName ?? '');
    _noteCtrl = TextEditingController(text: l.note ?? '');

    _selectedWaterSource = l.waterSource != null
        ? _waterSourceReverseMap[l.waterSource]
        : null;
    _selectedSource = l.source != null
        ? _sourceReverseMap[l.source]
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _farmSizeCtrl.dispose();
    _cropCtrl.dispose();
    _referenceNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;
    setState(() => _saving = true);

    context.read<SprinklerLeadCubit>().updateBasicInfo(
      widget.lead.id,
      customerName:  _nameCtrl.text.trim(),
      phone:         _phoneCtrl.text.trim(),
      address:       _addressCtrl.text.trim(),
      village:       _villageCtrl.text.trim(),
      farmSize:      double.tryParse(_farmSizeCtrl.text.trim()),
      waterSource:   _selectedWaterSource != null
          ? _waterSourceMap[_selectedWaterSource]
          : null,
      cropType:      _cropCtrl.text.trim().isEmpty ? null : _cropCtrl.text.trim(),
      source:        _selectedSource != null
          ? _sourceMap[_selectedSource]
          : null,
        referenceName: _selectedSourceCode == 'reference'
          ? (_referenceNameCtrl.text.trim().isEmpty
            ? null
            : _referenceNameCtrl.text.trim())
          : null,
      note:          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (!mounted) return;
        if (state is SprinklerLeadSaved) {
          setState(() => _saving = false);
          AppFeedback.showSuccess(
            context,
            'Lead details updated successfully',
            svgAsset: AppSvgAssets.circleCheckBig,
          );
          Navigator.pop(context, state.lead);
        }
        if (state is SprinklerLeadError) {
          setState(() => _saving = false);
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgSecondary),
        appBar: AppBar(
          backgroundColor: LeadTheme.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.chevronLeft,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Lead Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Customer Information ──────────────────────────────────
              _buildCard(
                title: 'Customer Information',
                icon: AppSvgAssets.userRound,
                children: [
                  _buildLabel('Customer Name', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'Enter customer name',
                      prefixIcon: AppSvgIcon(
                        AppSvgAssets.userRound,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Mobile Number', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _inputDecoration(
                      hint: 'Enter 10-digit mobile number',
                      prefixText: '+91  ',
                      prefixIcon: AppSvgIcon(
                        AppSvgAssets.phone,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone is required';
                      if (v.length != 10) return 'Enter a valid 10-digit number';
                      final first = int.tryParse(v[0]) ?? 0;
                      if (first < 6) return 'Enter a valid Indian mobile number';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Location ──────────────────────────────────────────────
              _buildCard(
                title: 'Location',
                icon: AppSvgAssets.mapPin,
                children: [
                  _buildLabel('Address', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      hint: 'Enter address',
                      prefixIcon: AppSvgIcon(
                        AppSvgAssets.mapPin,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 14),

                ],
              ),
              const SizedBox(height: 14),

              // ── Lead Source ───────────────────────────────────────────
              _buildCard(
                title: 'Lead Source',
                icon: AppSvgAssets.megaphone,
                children: [
                  _buildLabel('Source', required: false),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    hint: 'Select lead source (optional)',
                    value: _selectedSource,
                    items: _sourceLabels,
                    icon: AppSvgAssets.megaphone,
                    onChanged: (v) => setState(() {
                      _selectedSource = v;
                      if (_sourceMap[v] != 'reference') {
                        _referenceNameCtrl.clear();
                      }
                    }),
                  ),
                  if (_selectedSourceCode == 'reference') ...[
                    const SizedBox(height: 14),
                    _buildLabel('Reference Name', required: false),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _referenceNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        hint: 'Enter reference name',
                        prefixIcon: AppSvgIcon(
                          AppSvgAssets.userRound,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // ── Notes ─────────────────────────────────────────────────
              _buildCard(
                title: 'Additional Notes',
                icon: AppSvgAssets.fileText,
                children: [
                  _buildLabel('Notes', required: false),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration(hint: 'Any additional remarks…'),
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

  // ── Save Bar ──────────────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
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
            disabledBackgroundColor: LeadTheme.secondary.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  'Save Changes',
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
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: LeadTheme.secondary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
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

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required String icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(
        hint: hint,
        prefixIcon: AppSvgIcon(icon, size: 16, color: AppColors.textSecondary),
      ),
      isExpanded: true,
      icon: AppSvgIcon(
        AppSvgAssets.chevronDown,
        size: 16,
        color: AppColors.textSecondary,
      ),
      items: [
        DropdownMenuItem<String>(
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
        ...items.map(
          (s) => DropdownMenuItem<String>(
            value: s,
            child: Text(
              s,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
    String? suffixText,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        filled: true,
        fillColor: Colors.white,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 13.5,
          color: AppColors.textPrimary),
          fontWeight: FontWeight.w500,
        ),
        suffixText: suffixText,
        suffixStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        prefixIcon: prefixIcon != null
            ? Padding(padding: const EdgeInsets.all(13), child: prefixIcon)
            : null,
        suffixIcon: suffixIcon != null
            ? Padding(padding: const EdgeInsets.all(13), child: suffixIcon)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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





