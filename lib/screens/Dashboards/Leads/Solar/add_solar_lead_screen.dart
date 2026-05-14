// lib/screens/AddSolarLeadScreen.dart
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

class AddSolarLeadScreen extends StatefulWidget {
  const AddSolarLeadScreen({super.key});

  @override
  State<AddSolarLeadScreen> createState() => _AddSolarLeadScreenState();
}

class _AddSolarLeadScreenState extends State<AddSolarLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _villageC = TextEditingController();
  final _landC = TextEditingController();
  final _kwC = TextEditingController();
  final _noteC = TextEditingController();
  final _referenceNameC = TextEditingController();

  String? _electricity;
  String? _source;
  bool _saving = false;

  // static const _electricityOpts = ['Single Phase', 'Three Phase'];
  static const _sourceOpts = [
    'call',
    'reference',
    'social media',
    'indiamart',
    'other',
  ];

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

    final lead = SolarLeadsModel(
      id: '',
      customerName: _nameC.text.trim(),
      mobile: _phoneC.text.trim(),
      address: _addressC.text.trim(),
      village: _villageC.text.trim(),
      landSize: double.tryParse(_landC.text),
      requiredKW: double.tryParse(_kwC.text),
      electricityConnection: _electricity,
      source: _source,
      referenceName: _source == 'reference'
          ? _referenceNameC.text.trim().isEmpty
              ? null
              : _referenceNameC.text.trim()
          : null,
      note: _noteC.text.trim().isEmpty ? null : _noteC.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<SolarLeadCubit>().createLead(lead);
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

          Navigator.pop(context, true);
          AppFeedback.showSuccess(
            context,
            'Lead created successfully',
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
            'New Solar Lead',
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
              const LeadSectionLabel(
                text: 'Technical Details',
                accentColor: LeadTheme.primary,
              ),
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
                  // Clear reference name when switching away from 'reference'
                  if (value != 'reference') _referenceNameC.clear();
                }),
                accentColor: LeadTheme.primary,
                required: true,
              ),
              // Show reference name field only when source is 'reference'
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
              const SizedBox(height: 20),
              LeadSubmitButton(
                label: 'Save Lead',
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



