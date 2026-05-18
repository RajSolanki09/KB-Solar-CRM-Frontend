// lib/screens/Dashboards/Leads/Sprinkler/Steps/spk_visit_data_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/Helper/spk_photo_picker.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';

class SpkVisitDataScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SpkVisitDataScreen({super.key, required this.lead});

  @override
  State<SpkVisitDataScreen> createState() => _SpkVisitDataScreenState();
}

class _SpkVisitDataScreenState extends State<SpkVisitDataScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  List<PickedPhoto> _photos = [];

  // ── Controllers ───────────────────────────────────────────────────────────
  final _noOfPanelsCtrl = TextEditingController();
  final _pumpCapacityCtrl = TextEditingController();
  final _deliveryPipeLenCtrl = TextEditingController();
  final _noOfSprinklersCtrl = TextEditingController();
  final _cableLengthCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _typeOfPump;
  String? _typeOfSite;

  // ── Dropdown options ──────────────────────────────────────────────────────
  static const _pumpTypes = ['Monoblock', 'Openwell', 'Solenoid Valve'];

  static const _siteTypes = ['Auto', 'Manually', 'MCB', 'Solenoid'];

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final d = widget.lead.visitData;
    if (d.noOfPanels != null) _noOfPanelsCtrl.text = d.noOfPanels.toString();
    if (d.pumpCapacity != null) _pumpCapacityCtrl.text = d.pumpCapacity!;
    if (d.deliveryPipeLength != null) {
      _deliveryPipeLenCtrl.text = d.deliveryPipeLength.toString();
    }
    if (d.noOfSprinklers != null) {
      _noOfSprinklersCtrl.text = d.noOfSprinklers.toString();
    }
    if (d.cableLength != null) _cableLengthCtrl.text = d.cableLength.toString();
    if (d.notes != null) _notesCtrl.text = d.notes!;
    _typeOfPump = d.typeOfPump;
    _typeOfSite = d.typeOfSite;
  }

  @override
  void dispose() {
    _noOfPanelsCtrl.dispose();
    _pumpCapacityCtrl.dispose();
    _deliveryPipeLenCtrl.dispose();
    _noOfSprinklersCtrl.dispose();
    _cableLengthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;
    setState(() => _saving = true);

    context.read<SprinklerLeadCubit>().saveVisitData(
      widget.lead.id,
      noOfPanels: int.tryParse(_noOfPanelsCtrl.text.trim()),
      pumpCapacity: _pumpCapacityCtrl.text.trim().isEmpty
          ? null
          : _pumpCapacityCtrl.text.trim(),
      typeOfPump: _typeOfPump,
      deliveryPipeLength: double.tryParse(_deliveryPipeLenCtrl.text.trim()),
      noOfSprinklers: int.tryParse(_noOfSprinklersCtrl.text.trim()),
      cableLength: double.tryParse(_cableLengthCtrl.text.trim()),
      typeOfSite: _typeOfSite,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      photos: _photos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (!mounted) return;
        if (state is SprinklerLeadSaved) {
          setState(() => _saving = false);
          Navigator.pop(context);
        }
        if (state is SprinklerLeadError) {
          setState(() => _saving = false);
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor:   AppColors.lightBg,
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
            'Visit Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Panel & Pump ─────────────────────────────────────────
              _buildCard(
                title: 'Panel & Pump Details',
                icon: AppSvgAssets.cog,
                children: [
                  _buildLabel('No of Panels', required: false),
                  const SizedBox(height: 6),
                  LeadTextFormField(
                    controller: _noOfPanelsCtrl,
                    label: 'No of Panels',
                    svgIcon: AppSvgAssets.maximize,
                    accentColor: LeadTheme.secondary,
                    required: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    hintText: 'Enter number of panels',
                    bottomSpacing: 0,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Pump Capacity', required: false),
                  const SizedBox(height: 6),
                  LeadTextFormField(
                    controller: _pumpCapacityCtrl,
                    label: 'Pump Capacity',
                    svgIcon: AppSvgAssets.droplet,
                    accentColor: LeadTheme.secondary,
                    required: false,
                    hintText: 'e.g. 5 HP, 2.2 kW',
                    bottomSpacing: 0,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Type of Pump', required: false),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    hint: 'Select pump type (optional)',
                    value: _typeOfPump,
                    items: _pumpTypes,
                    icon: AppSvgAssets.cog,
                    onChanged: (v) => setState(() => _typeOfPump = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Sprinkler & Pipe ─────────────────────────────────────
              _buildCard(
                title: 'Sprinkler & Pipe Details',
                icon: AppSvgAssets.droplet,
                children: [
                  _buildLabel('Delivery Pipe Length (feet)', required: false),
                  const SizedBox(height: 6),
                  LeadTextFormField(
                    controller: _deliveryPipeLenCtrl,
                    label: 'Delivery Pipe Length (feet)',
                    svgIcon: AppSvgAssets.maximize,
                    accentColor: LeadTheme.secondary,
                    required: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    suffixText: 'm',
                    hintText: 'Enter pipe length in metres',
                    bottomSpacing: 0,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('No of Sprinklers', required: false),
                  const SizedBox(height: 6),
                  LeadTextFormField(
                    controller: _noOfSprinklersCtrl,
                    label: 'No of Sprinklers',
                    svgIcon: AppSvgAssets.droplet,
                    accentColor: LeadTheme.secondary,
                    required: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    hintText: 'Enter number of sprinklers',
                    bottomSpacing: 0,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Cable Length (m)', required: false),
                  const SizedBox(height: 6),
                  LeadTextFormField(
                    controller: _cableLengthCtrl,
                    label: 'Cable Length (m)',
                    svgIcon: AppSvgAssets.maximize,
                    accentColor: LeadTheme.secondary,
                    required: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    suffixText: 'm',
                    hintText: 'Enter cable length in metres',
                    bottomSpacing: 0,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Site ─────────────────────────────────────────────────
              _buildCard(
                title: 'Site Information',
                icon: AppSvgAssets.mapPin,
                children: [
                  _buildLabel('Type of Site', required: false),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    hint: 'Select site type (optional)',
                    value: _typeOfSite,
                    items: _siteTypes,
                    icon: AppSvgAssets.mapPin,
                    onChanged: (v) => setState(() => _typeOfSite = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Technical Photos ← YEH NAYA ADD KARO ────────────────
              
              _buildCard(
                title: 'Site Photos',
                icon: AppSvgAssets.camera,
                children: [
                  const Text(
                    'Photos of pump, sprinklers, pipes, site setup etc.',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 10),
                  SpkPhotoPicker(
                    existingUrls: widget.lead.visitData.visitPhotos,
                    label: 'Visit Photos',
                    maxPhotos: 15,
                    onChanged: (pics) => setState(() => _photos = pics),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Notes ────────────────────────────────────────────────
              _buildCard(
                title: 'Additional Notes',
                icon: AppSvgAssets.fileText,
                children: [
                  _buildLabel('Notes', required: false),
                  const SizedBox(height: 6),
                  LeadTextFormField(
                    controller: _notesCtrl,
                    label: 'Notes',
                    svgIcon: AppSvgAssets.fileText,
                    accentColor: LeadTheme.secondary,
                    required: false,
                    maxLines: 3,
                    hintText: 'Any additional observations…',
                    bottomSpacing: 0,
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

  Widget _buildSaveBar() => Container(
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
          disabledBackgroundColor: LeadTheme.secondary.withValues(alpha: 0.6),
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
                'Save Visit Data',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildCard({
    required String title,
    required String icon,
    required List<Widget> children,
  }) => Container(
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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

  Widget _buildLabel(String text, {bool required = false}) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.gray400,
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
  }) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: _inputDeco(
      hint: hint,
      prefixIcon: AppSvgIcon(icon, size: 16, color: Colors.grey.shade500),
    ),
    isExpanded: true,
    icon: AppSvgIcon(
      AppSvgAssets.chevronDown,
      size: 16,
      color: Colors.grey.shade500,
    ),
    items: [
      DropdownMenuItem<String>(
        value: null,
        child: Text(
          'None',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
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
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    ],
    onChanged: onChanged,
  );

  InputDecoration _inputDeco({
    required String hint,
    Widget? prefixIcon,
    String? suffixText,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
    filled: true,
    fillColor: Colors.white,
    suffixText: suffixText,
    suffixStyle: const TextStyle(fontSize: 12, color: AppColors.textGray),
    prefixIcon: prefixIcon != null
        ? Padding(padding: const EdgeInsets.all(13), child: prefixIcon)
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



