import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/Helper/app_colors.dart';

class SolarAgreementUploadScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;

  const SolarAgreementUploadScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });

  @override
  State<SolarAgreementUploadScreen> createState() => _SolarAgreementUploadState();
}

class _SolarAgreementUploadState extends State<SolarAgreementUploadScreen> {
  bool _agreementUploaded = false;
  bool _installationDetailsProvided = false;
  String _status = 'underReview';
  bool _saving = false;

  static const Map<String, String> _statusOptions = {
    'underReview': 'Under Review',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    final data = widget.lead.agreementUploadData;
    _agreementUploaded = data.agreementUploaded;
    _installationDetailsProvided = data.installationDetailsProvided;
    _status = _statusOptions.containsKey(data.status)
        ? data.status!
        : 'underReview';
  }

  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SolarLeadCubit>();

    if (widget.isEditing) {
      cubit.editAgreementUpload(
        widget.lead.id,
        agreementUploaded: _agreementUploaded,
        installationDetailsProvided: _installationDetailsProvided,
        status: _status,
      );
      return;
    }

    cubit.saveAgreementUpload(
      widget.lead.id,
      agreementUploaded: _agreementUploaded,
      installationDetailsProvided: _installationDetailsProvided,
      status: _status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) {
          Navigator.pop(context, state.lead);
        }
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
            widget.isEditing ? 'Edit Agreement Upload' : 'Agreement Upload',
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
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Agreement Details'),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Agreement Upload',
                    _agreementUploaded,
                    AppSvgAssets.fileText,
                    onChanged: (v) => setState(() => _agreementUploaded = v),
                  ),
                  const SizedBox(height: 8),
                  _checkTile(
                    'Installation Details',
                    _installationDetailsProvided,
                    AppSvgAssets.clipboardList,
                    onChanged: (v) =>
                        setState(() => _installationDetailsProvided = v),
                  ),
                ],
              ),
            ),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Status'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: LeadTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: _statusOptions.entries
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: LeadTheme.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _status = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _saveBtn(
              _saving,
              _save,
              widget.isEditing ? 'Update Agreement Upload' : 'Save Agreement Upload',
            ),
          ],
        ),
      ),
    );
  }
}

Widget _infoBanner(SolarLeadsModel lead) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: LeadTheme.primary.withValues(alpha: 0.06),
    border: Border.all(color: LeadTheme.primary.withValues(alpha: 0.2)),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    children: [
      const AppSvgIcon(AppSvgAssets.userRound, size: 16, color: LeadTheme.primary),
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

Widget _checkTile(
  String label,
  bool value,
  String svgAsset, {
  required ValueChanged<bool> onChanged,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  decoration: BoxDecoration(
    color: LeadTheme.surface,
    border: Border.all(
      color: value ? Colors.green.shade300 : AppColors.borderLight,
    ),
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
            color: value ? Colors.green : LeadTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value ? Colors.green.shade700 : LeadTheme.textPrimary,
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
      color: selected ? activeColor.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: selected ? activeColor.withValues(alpha: 0.65) : AppColors.borderPrimary,
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

Widget _saveBtn(bool saving, VoidCallback onPressed, String label) => SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: saving ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: LeadTheme.primary,
      foregroundColor: Colors.white,
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
              color: Colors.white,
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
  ),
);




