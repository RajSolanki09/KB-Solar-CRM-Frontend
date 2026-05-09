// lib/screens/Solar/Steps/technical_visit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/spk_photo_picker.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';

import '../../../../../Helper/picked_photo.dart';

class SolarTechnicalVisitScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarTechnicalVisitScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarTechnicalVisitScreen> createState() => _State();
}

class _State extends State<SolarTechnicalVisitScreen> {
  late TextEditingController _systemKWC;
  late TextEditingController _inverterBoardC;
  late TextEditingController _panelBoardC;
  late TextEditingController _panelCapacityC;
  late TextEditingController _cableTypeC;
  late TextEditingController _acDBTypeC;
  late TextEditingController _structureHeightC;
  late TextEditingController _beamLineC;
  late TextEditingController _totalArrayC;
  late TextEditingController _scaffoldingC;
  late TextEditingController _panelLayoutC;
  late TextEditingController _lugTypeC;
  String? _meterPhase;

  List<PickedPhoto> _photos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tech = widget.lead.technicalVisitData;
    _systemKWC = TextEditingController(text: tech.systemKW ?? '');
    _inverterBoardC = TextEditingController(text: tech.inverterBoardType ?? '');
    _panelBoardC = TextEditingController(text: tech.panelBoardType ?? '');
    _panelCapacityC = TextEditingController(text: tech.panelCapacity ?? '');
    _cableTypeC = TextEditingController(text: tech.cableType ?? '');
    _acDBTypeC = TextEditingController(text: tech.acDBType ?? '');
    _structureHeightC = TextEditingController(text: tech.structureHeight ?? '');
    _beamLineC = TextEditingController(text: tech.beamLineDetails ?? '');
    _totalArrayC = TextEditingController(text: tech.totalArray ?? '');
    _scaffoldingC = TextEditingController(text: tech.scaffoldingDetails ?? '');
    _panelLayoutC = TextEditingController(text: tech.panelLayout ?? '');
    _lugTypeC = TextEditingController(text: tech.lugType ?? '');
    _meterPhase = tech.meterPhase;
  }

  @override
  void dispose() {
    _systemKWC.dispose();
    _inverterBoardC.dispose();
    _panelBoardC.dispose();
    _panelCapacityC.dispose();
    _cableTypeC.dispose();
    _acDBTypeC.dispose();
    _structureHeightC.dispose();
    _beamLineC.dispose();
    _totalArrayC.dispose();
    _scaffoldingC.dispose();
    _panelLayoutC.dispose();
    _lugTypeC.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _saving = true);

    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;

    String? _getNullIfEmpty(TextEditingController c) {
      final text = c.text.trim();
      return text.isEmpty ? null : text;
    }

    if (widget.isEditing) {
      cubit.editTechnicalVisit(
        id,
        systemKW: _getNullIfEmpty(_systemKWC),
        inverterBoardType: _getNullIfEmpty(_inverterBoardC),
        panelBoardType: _getNullIfEmpty(_panelBoardC),
        panelCapacity: _getNullIfEmpty(_panelCapacityC),
        cableType: _getNullIfEmpty(_cableTypeC),
        acDBType: _getNullIfEmpty(_acDBTypeC),
        structureHeight: _getNullIfEmpty(_structureHeightC),
        beamLineDetails: _getNullIfEmpty(_beamLineC),
        totalArray: _getNullIfEmpty(_totalArrayC),
        scaffoldingDetails: _getNullIfEmpty(_scaffoldingC),
        panelLayout: _getNullIfEmpty(_panelLayoutC),
        lugType: _getNullIfEmpty(_lugTypeC),
        meterPhase: _meterPhase,
        photos: _photos,
      );
    } else {
      cubit.markTechnicalVisit(
        id,
        systemKW: _getNullIfEmpty(_systemKWC),
        inverterBoardType: _getNullIfEmpty(_inverterBoardC),
        panelBoardType: _getNullIfEmpty(_panelBoardC),
        panelCapacity: _getNullIfEmpty(_panelCapacityC),
        cableType: _getNullIfEmpty(_cableTypeC),
        acDBType: _getNullIfEmpty(_acDBTypeC),
        structureHeight: _getNullIfEmpty(_structureHeightC),
        beamLineDetails: _getNullIfEmpty(_beamLineC),
        totalArray: _getNullIfEmpty(_totalArrayC),
        scaffoldingDetails: _getNullIfEmpty(_scaffoldingC),
        panelLayout: _getNullIfEmpty(_panelLayoutC),
        lugType: _getNullIfEmpty(_lugTypeC),
        meterPhase: _meterPhase,
        photos: _photos,
      );
    }
  }

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
          // Card header with colored background
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) Navigator.pop(context);
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
            widget.isEditing ? 'Edit Technical Visit' : 'Technical Visit Data',
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
            // Customer info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: LeadTheme.primary.withValues(alpha: 0.06),
                border: Border.all(
                  color: LeadTheme.primary.withValues(alpha: 0.2),
                ),
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
                          widget.lead.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: LeadTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.lead.mobile}  ·  ${widget.lead.address}',
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
            ),
            const SizedBox(height: 10),

            // System Details
            _buildCard(
              title: 'System Specifications',
              icon: AppSvgAssets.zap,
              children: [
                _field(_systemKWC, 'System KW', AppSvgAssets.zap),
                const SizedBox(height: 8),
                _field(_totalArrayC, 'No of Panels', AppSvgAssets.maximize),
                const SizedBox(height: 8),
                _field(
                  _inverterBoardC,
                  'Inverter Brand',
                  AppSvgAssets.circleCheckBig,
                ),
                const SizedBox(height: 8),
                _field(
                  _panelBoardC,
                  'Panel Brand',
                  AppSvgAssets.circleCheckBig,
                ),
                const SizedBox(height: 8),
                _field(_panelCapacityC, 'Panel Capacity', AppSvgAssets.zap),
                const SizedBox(height: 8),
                _field(_cableTypeC, 'Cable Brand', AppSvgAssets.circleCheckBig),
              ],
            ),

            const SizedBox(height: 8),

            // Structure & Height
            _buildCard(
              title: 'Structure & Height',
              icon: AppSvgAssets.maximize,
              children: [
                _field(
                  _structureHeightC,
                  'Terrace Size',
                  AppSvgAssets.maximize,
                ),
                const SizedBox(height: 8),
                _field(
                  _beamLineC,
                  'Front Leg Height',
                  AppSvgAssets.circleCheckBig,
                ),
                const SizedBox(height: 8),
                _field(
                  _scaffoldingC,
                  'Back Leg Height',
                  AppSvgAssets.circleCheckBig,
                ),
                const SizedBox(height: 8),
                _field(
                  _acDBTypeC,
                  'Total Leg Height',
                  AppSvgAssets.circleCheckBig,
                ),
                const SizedBox(height: 8),
                _field(_lugTypeC, 'Support Pipe', AppSvgAssets.circleCheckBig),
                const SizedBox(height: 8),
                _field(
                  _panelLayoutC,
                  'Panel Layout',
                  AppSvgAssets.circleCheckBig,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Meter Detail
            _buildCard(
              title: 'Meter Detail',
              icon: AppSvgAssets.zap,
              children: [
                const Text(
                  'Meter Phase',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LeadTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _meterPhase,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: LeadTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  hint: const Text('Select meter phase'),
                  items: const [
                    DropdownMenuItem(
                      value: 'single_phase',
                      child: Text('Single Phase'),
                    ),
                    DropdownMenuItem(
                      value: 'three_phase',
                      child: Text('Three Phase'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _meterPhase = value),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Technical Photos
            _buildCard(
              title: 'Technical Photos',
              icon: AppSvgAssets.fileText,
              children: [
                const Text(
                  'Photos of technical setup, boards, wiring, structure etc.',
                  style: TextStyle(fontSize: 11, color: LeadTheme.textMuted),
                ),
                const SizedBox(height: 10),
                SpkPhotoPicker(
                  existingUrls: widget.lead.technicalPhotoPaths,
                  label: 'Technical Visit Photos',
                  maxPhotos: 15,
                  onChanged: (pics) => _photos = pics,
                ),
              ],
            ),

            const SizedBox(height: 14),
            _saveBtn(
              _saving,
              _save,
              widget.isEditing
                  ? 'Update Technical Visit'
                  : 'Mark Technical Visit Done',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _field(
  TextEditingController c,
  String label,
  String svgAsset, {
  int maxLines = 1,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: LeadTheme.textPrimary,
      ),
    ),
    const SizedBox(height: 6),
    TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
      decoration: InputDecoration(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        hintText: 'Enter $label',
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.divider),
      ),
    ),
  ],
);

Widget _saveBtn(bool saving, VoidCallback onPressed, String label) => SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    onPressed: saving ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: LeadTheme.primary,
      foregroundColor: AppColors.surface,
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
