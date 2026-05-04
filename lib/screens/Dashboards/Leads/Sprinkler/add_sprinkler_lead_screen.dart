import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/app_colors.dart';

class AddSprinklerLeadScreen extends StatefulWidget {
  const AddSprinklerLeadScreen({super.key});
  @override
  State<AddSprinklerLeadScreen> createState() => _State();
}

class _State extends State<AddSprinklerLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final addressC = TextEditingController();
  final villageC = TextEditingController();
  final farmSizeC = TextEditingController();
  final cropC = TextEditingController();
  final noteC = TextEditingController();
  final referenceNameC = TextEditingController();
  String? selectedWaterSource;
  String? selectedSource;
  bool _saving = false;

  final waterSources = ['Borewell', 'Canal', 'Tank', 'River', 'Other'];
  final waterSourceMap = const {
    'Borewell': 'borewell',
    'Canal': 'canal',
    'Tank': 'tank',
    'River': 'river',
    'Other': 'other',
  };
  final sources = [
    'Call',
    'Reference',
    'Social Media',
    'Epc-reference',
    'Indiamart',
    'Other',
  ];
  final sourceMap = const {
    'Call': 'call',
    'Reference': 'reference',
    'Social Media': 'social_media',
    'Epc-reference': 'epc_reference',
    'Indiamart': 'indiamart',
    'Other': 'other',
  };

  @override
  void dispose() {
    for (final c in [
      nameC,
      phoneC,
      addressC,
      villageC,
      farmSizeC,
      cropC,
      noteC,
      referenceNameC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final lead = SprinklerLeadModel(
      id: '',
      customerName: nameC.text.trim(),
      phone: phoneC.text.trim(),
      address: addressC.text.trim(),
      village: villageC.text.trim(),
      farmSize: double.tryParse(farmSizeC.text),
      waterSource: selectedWaterSource == null
          ? null
          : waterSourceMap[selectedWaterSource],
      cropType: cropC.text.trim().isEmpty ? null : cropC.text.trim(),
      source: selectedSource == null ? null : sourceMap[selectedSource],
        referenceName: sourceMap[selectedSource] == 'reference'
          ? (referenceNameC.text.trim().isEmpty ? null : referenceNameC.text.trim())
          : null,
        note: noteC.text.trim().isEmpty ? null : noteC.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    context.read<SprinklerLeadCubit>().createLead(lead);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (state is SprinklerLeadSaved) {
          setState(() => _saving = false);
          Navigator.pop(context, state.lead);
          AppFeedback.showSuccess(
            context,
            'Sprinkler lead created successfully',
            svgAsset: AppSvgAssets.circleCheckBig,
          );
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
            'New Sprinkler Lead',
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
              // ── Customer Information ────────────────────────────────
              const LeadSectionLabel(
                text: 'Customer Information',
                accentColor: LeadTheme.secondary,
              ),
              const SizedBox(height: 8),
              LeadTextFormField(
                controller: nameC,
                label: 'Customer Name *',
                svgIcon: AppSvgAssets.userRound,
                accentColor: LeadTheme.secondary,
                required: true,
              ),
              LeadTextFormField(
                controller: phoneC,
                label: 'Mobile Number *',
                svgIcon: AppSvgAssets.phone,
                accentColor: LeadTheme.secondary,
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                prefixText: '+91  ',
                prefixStyle: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary),
                  fontWeight: FontWeight.w500,
                ),
                counterText: '',
                focusedErrorBorder: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (value.length != 10) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  final first = int.tryParse(value[0]) ?? 0;
                  if (first < 6) {
                    return 'Enter a valid Indian mobile number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 6),

              // ── Location ────────────────────────────────────────────
              const LeadSectionLabel(
                text: 'Location',
                accentColor: LeadTheme.secondary,
              ),
              const SizedBox(height: 8),
              LeadTextFormField(
                controller: addressC,
                label: 'Village / Address *',
                svgIcon: AppSvgAssets.mapPin,
                accentColor: LeadTheme.secondary,
                required: true,
              ),

              const SizedBox(height: 6),

              // ── Lead Source ─────────────────────────────────────────
              const LeadSectionLabel(
                text: 'Lead Source',
                accentColor: LeadTheme.secondary,
              ),
              const SizedBox(height: 8),
              LeadDropdownField(
                label: 'Source',
                svgIcon: AppSvgAssets.megaphone,
                items: sources,
                value: selectedSource,
                onChanged: (value) => setState(() {
                  selectedSource = value;
                  if (value != 'Reference') referenceNameC.clear();
                }),
                accentColor: LeadTheme.secondary,
              ),
              if (selectedSource == 'Reference') ...[
                const SizedBox(height: 8),
                LeadTextFormField(
                  controller: referenceNameC,
                  label: 'Reference Name',
                  svgIcon: AppSvgAssets.userRound,
                  accentColor: LeadTheme.secondary,
                ),
              ],

              const SizedBox(height: 6),

              // ── Notes ───────────────────────────────────────────────
              const LeadSectionLabel(
                text: 'Additional Notes',
                accentColor: LeadTheme.secondary,
              ),
              const SizedBox(height: 8),
              LeadTextFormField(
                controller: noteC,
                label: 'Notes (optional)',
                svgIcon: AppSvgAssets.fileText,
                accentColor: LeadTheme.secondary,
                required: false,
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // ── Save button ─────────────────────────────────────────
              LeadSubmitButton(
                label: 'Save Sprinkler Lead',
                color: LeadTheme.secondary,
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




