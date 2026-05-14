// lib/screens/Dashboards/Leads/Solar/Steps/edit_lead_basic_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/form_validation.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';

class EditLeadBasicInfoScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  const EditLeadBasicInfoScreen({super.key, required this.lead});

  @override
  State<EditLeadBasicInfoScreen> createState() =>
      _EditLeadBasicInfoScreenState();
}

class _EditLeadBasicInfoScreenState extends State<EditLeadBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameC;
  late final TextEditingController _phoneC;
  late final TextEditingController _addressC;
  late final TextEditingController _villageC;
  late final TextEditingController _landC;
  late final TextEditingController _kwC;
  late final TextEditingController _noteC;
  late final TextEditingController _referenceNameC;

  String? _electricity;
  String? _source;
  bool _saving = false;

  static const _sourceOpts = [
    'call',
    'reference',
    'marketing',
    'walk-in',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _nameC = TextEditingController(text: l.customerName);
    _phoneC = TextEditingController(text: l.mobile);
    _addressC = TextEditingController(text: l.address);
    _villageC = TextEditingController(text: l.village);
    _landC = TextEditingController(
      text: l.landSize != null ? l.landSize.toString() : '',
    );
    _kwC = TextEditingController(
      text: l.requiredKW != null ? l.requiredKW.toString() : '',
    );
    _noteC = TextEditingController(text: l.note ?? '');
    _referenceNameC = TextEditingController(text: l.referenceName ?? '');
    _electricity = l.electricityConnection;
    _source = l.source;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _villageC.dispose();
    _landC.dispose();
    _kwC.dispose();
    _noteC.dispose();
    _referenceNameC.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SolarLeadCubit>().updateBasicInfo(
      widget.lead.id,
      customerName: _nameC.text.trim(),
      mobile: _phoneC.text.trim(),
      address: _addressC.text.trim(),
      village: _villageC.text.trim(),
      landSize: double.tryParse(_landC.text),
      requiredKW: double.tryParse(_kwC.text),
      electricityConnection: _electricity?.isNotEmpty == true
          ? _electricity
          : null,
      source: _source,
      referenceName: _source == 'reference'
          ? _referenceNameC.text.trim().isEmpty
                ? null
                : _referenceNameC.text.trim()
          : null,
      note: _noteC.text.trim().isEmpty ? null : _noteC.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadLoading) {
          setState(() => _saving = true);
        }
        if (state is SolarLeadSaved) {
          setState(() => _saving = false);
          if (!mounted) return;
          Navigator.pop(context, state.lead);
          AppFeedback.showSuccess(
            context,
            'Lead updated successfully',
            svgAsset: AppSvgAssets.circleCheckBig,
          );
        }
        if (state is SolarLeadError) {
          setState(() => _saving = false);
          if (!mounted) return;
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: LeadTheme.primary,
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
            'Edit Lead Info',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // ── Header banner ─────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LeadTheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: LeadTheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    AppSvgIcon(
                      AppSvgAssets.pencil,
                      size: 15,
                      color: LeadTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing basic info for ${widget.lead.customerName}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: LeadTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Customer Information ──────────────────────────────────
              const LeadSectionLabel(
                text: 'Customer Information',
                accentColor: LeadTheme.primary,
              ),
              const SizedBox(height: 8),
              LeadTextFormField(
                controller: _nameC,
                label: 'Customer Name',
                svgIcon: AppSvgAssets.userRound,
                accentColor: LeadTheme.primary,
                validator: (value) => FormValidators.validateName(
                  value,
                  fieldName: 'Customer Name',
                ),
              ),
              LeadTextFormField(
                controller: _phoneC,
                label: 'Phone Number',
                svgIcon: AppSvgAssets.phone,
                accentColor: LeadTheme.primary,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
                validator: FormValidators.validatePhone,
              ),
              const SizedBox(height: 6),

              // ── Location ──────────────────────────────────────────────
              const LeadSectionLabel(
                text: 'Location',
                accentColor: LeadTheme.primary,
              ),
              const SizedBox(height: 8),
              LeadTextFormField(
                controller: _addressC,
                label: 'Address',
                svgIcon: AppSvgAssets.mapPin,
                accentColor: LeadTheme.primary,
                validator: FormValidators.validateAddress,
              ),
              const SizedBox(height: 6),

              // ── Technical Details ─────────────────────────────────────
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LeadTextFormField(
                      controller: _kwC,
                      label: 'Required KW',
                      svgIcon: AppSvgAssets.zap,
                      accentColor: LeadTheme.primary,
                      keyboardType: TextInputType.number,
                      required: false,
                      inputFormatters: [NumberFormatter(allowDecimal: true)],
                      validator: (value) => value != null && value.isNotEmpty
                          ? FormValidators.validateNumber(
                              value,
                              fieldName: 'Required KW',
                              min: 0.1,
                              max: 1000,
                            )
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ── Lead Source ───────────────────────────────────────────
              const LeadSectionLabel(
                text: 'Lead Source',
                accentColor: LeadTheme.primary,
              ),
              const SizedBox(height: 8),
              LeadDropdownField(
                label: 'Source',
                svgIcon: AppSvgAssets.megaphone,
                items: _sourceOpts,
                value: _source,
                onChanged: (value) => setState(() {
                  _source = value;
                  if (value != 'reference') _referenceNameC.clear();
                }),
                accentColor: LeadTheme.primary,
                required: false,
              ),
              if (_source == 'reference') ...[
                const SizedBox(height: 8),
                LeadTextFormField(
                  controller: _referenceNameC,
                  label: 'Reference Name',
                  svgIcon: AppSvgAssets.userRound,
                  accentColor: LeadTheme.primary,
                  validator: (value) => FormValidators.validateName(
                    value,
                    fieldName: 'Reference Name',
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // ── Additional Notes ──────────────────────────────────────
              const LeadSectionLabel(
                text: 'Additional Notes',
                accentColor: LeadTheme.primary,
              ),
              const SizedBox(height: 8),
              LeadTextFormField(
                controller: _noteC,
                label: 'Note (optional)',
                svgIcon: AppSvgAssets.fileText,
                accentColor: LeadTheme.primary,
                required: false,
                maxLines: 3,
                validator: (value) => value != null && value.isNotEmpty
                    ? FormValidators.validateNotes(value)
                    : null,
              ),
              const SizedBox(height: 24),
              LeadSubmitButton(
                label: 'Save Changes',
                color: LeadTheme.primary,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}




