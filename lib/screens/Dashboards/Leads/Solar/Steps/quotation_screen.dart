// lib/screens/Dashboards/Leads/Solar/Steps/solar_quotation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';

class SolarQuotationScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarQuotationScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarQuotationScreen> createState() => _State();
}

class _State extends State<SolarQuotationScreen> {
  // â”€â”€ Cost fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final rooftopSystemCostC = TextEditingController();
  final elevatedStructureCostC = TextEditingController();
  final netMeterCostC = TextEditingController();
  final premiumOtherCostC = TextEditingController();
  final totalC = TextEditingController();
  final subsidyC = TextEditingController();
  final systemAfterSubsidyC = TextEditingController();
  // â”€â”€ Payment terms â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final advancePercentC = TextEditingController(text: '60');
  final balancePercentC = TextEditingController(text: '40');
  final warrantyNoteC = TextEditingController(
    text: '5 year panel warranty, 1 year service warranty',
  );
  // â”€â”€ Notes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final notesC = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;

    final q = l.quotationData;
    final hasSplitCosts =
        q.rooftopSystemCost > 0 ||
        q.elevatedStructureCost > 0 ||
        q.netMeterCost > 0 ||
        q.premiumOtherCost > 0;

    rooftopSystemCostC.text = q.rooftopSystemCost > 0
        ? q.rooftopSystemCost.toStringAsFixed(0)
        : (hasSplitCosts
              ? '0'
              : (l.totalAmount > 0 ? l.totalAmount.toStringAsFixed(0) : ''));
    elevatedStructureCostC.text = q.elevatedStructureCost > 0
        ? q.elevatedStructureCost.toStringAsFixed(0)
        : '';
    netMeterCostC.text = q.netMeterCost > 0
        ? q.netMeterCost.toStringAsFixed(0)
        : '';
    premiumOtherCostC.text = q.premiumOtherCost > 0
        ? q.premiumOtherCost.toStringAsFixed(0)
        : '';

    totalC.text = l.totalAmount > 0 ? l.totalAmount.toStringAsFixed(0) : '';
    subsidyC.text = l.subsidyAmount != null && l.subsidyAmount! > 0
        ? l.subsidyAmount!.toStringAsFixed(0)
        : '';
    systemAfterSubsidyC.text = l.customerPayable > 0
        ? l.customerPayable.toStringAsFixed(0)
        : '';
    notesC.text = q.notes ?? '';
    _autoCalc();
  }

  @override
  void dispose() {
    for (final c in [
      rooftopSystemCostC,
      elevatedStructureCostC,
      netMeterCostC,
      premiumOtherCostC,
      totalC,
      subsidyC,
      systemAfterSubsidyC,
      advancePercentC,
      balancePercentC,
      warrantyNoteC,
      notesC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoCalc() {
    final rooftop = double.tryParse(rooftopSystemCostC.text) ?? 0;
    final elevated = double.tryParse(elevatedStructureCostC.text) ?? 0;
    final meter = double.tryParse(netMeterCostC.text) ?? 0;
    final premium = double.tryParse(premiumOtherCostC.text) ?? 0;
    final t = rooftop + elevated + meter + premium;
    final s = double.tryParse(subsidyC.text) ?? 0;
    setState(() {
      totalC.text = t.toStringAsFixed(0);
      systemAfterSubsidyC.text = (t - s).toStringAsFixed(0);
    });
    _autoCalcPayment();
  }

  void _autoCalcPayment() {
    final advP = double.tryParse(advancePercentC.text) ?? 60;
    setState(
      () =>
          balancePercentC.text = (100 - advP).clamp(0, 100).toStringAsFixed(0),
    );
  }

  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final t = (String? v) => v == null || v.trim().isEmpty ? null : v.trim();

    if (widget.isEditing) {
      cubit.editQuotation(
        id,
        rooftopSystemCost: double.tryParse(rooftopSystemCostC.text),
        elevatedStructureCost: double.tryParse(elevatedStructureCostC.text),
        netMeterCost: double.tryParse(netMeterCostC.text),
        premiumOtherCost: double.tryParse(premiumOtherCostC.text),
        totalAmount: double.tryParse(totalC.text),
        subsidyAmount: double.tryParse(subsidyC.text),
        advancePercent: double.tryParse(advancePercentC.text),
        balancePercent: double.tryParse(balancePercentC.text),
        warrantyNote: t(warrantyNoteC.text),
        notes: t(notesC.text),
      );
    } else {
      cubit.saveQuotation(
        id,
        rooftopSystemCost: double.tryParse(rooftopSystemCostC.text),
        elevatedStructureCost: double.tryParse(elevatedStructureCostC.text),
        netMeterCost: double.tryParse(netMeterCostC.text),
        premiumOtherCost: double.tryParse(premiumOtherCostC.text),
        totalAmount: double.tryParse(totalC.text),
        subsidyAmount: double.tryParse(subsidyC.text),
        advancePercent: double.tryParse(advancePercentC.text),
        balancePercent: double.tryParse(balancePercentC.text),
        warrantyNote: t(warrantyNoteC.text),
        notes: t(notesC.text),
      );
    }
  }

  // â”€â”€ BUILD UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) {
          setState(() => _saving = false);
            Future.delayed(const Duration(milliseconds: 100), () {
             if (mounted) safePop(context);
           });
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
            widget.isEditing ? 'Edit Quotation' : 'Quotation',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LeadTheme.textPrimary,
            ),
          ),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
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
                  const SectionTitle('Cost Breakdown'),
                  const SizedBox(height: 14),
                  _numField(
                    rooftopSystemCostC,
                    'Project Rooftop System Total Cost (àª¸à«‹àª²àª° àª°à«‚àª«àªŸà«‹àªª àª¸àª¿àª¸à«àªŸàª® àª¨à«‹ àªŸà«‹àªŸàª² àª–àª°à«àªš)',
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  _numField(
                    elevatedStructureCostC,
                    'Heighted/Elevated Structure Cost (àªàª²àª¿àªµà«‡àªŸà«‡àª¡ àª«à«àª°à«‡àª¬àª¿àª•à«‡àª¶àª¨ àª¨à«‹ àª–àª°à«àªš)',
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  _numField(
                    netMeterCostC,
                    'GEB/Torrent Net Meter Cost (àª®à«€àªŸàª° àª–àª°à«àªš)',
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  _numField(
                    premiumOtherCostC,
                    'Project Panel Premium Charge / Other Cost (àª¸à«‹àª²àª° àªªà«‡àª¨àª² àªªà«àª°à«€àª®àª¿àª¯àª® àªšàª¾àª°à«àªœ/àª…àª¨à«àª¯ àª–àª°à«àªš)',
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  _numField(
                    totalC,
                    'Total Net Payable (àªŸà«‹àªŸàª² àª­àª°àªµàª¾ àªªàª¾àª¤à«àª° àª°àª•àª®)',
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  _numField(
                    subsidyC,
                    'Subsidy (àª¸àª¬àª¸àª¿àª¡à«€ â€“ àª®à«€àªŸàª° àª²àª¾àª—à«àª¯àª¾ àªªàª›à«€ à«©à«¦ àª¦àª¿àªµàª¸àª®àª¾àª‚ àª—à«àª°àª¾àª¹àª•àª¨àª¾ àª¬à«‡àª‚àª• àª–àª¾àª¤àª¾àª®àª¾àª‚ àªœàª®àª¾ àª¥àª¶à«‡)',
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  _numField(
                    systemAfterSubsidyC,
                    'System Cost After Subsidy (àª¸àª¿àª¸à«àªŸàª® àª¨à«‹ àª¸àª¬àª¸àª¿àª¡à«€ àª¬àª¾àª¦ àª•àª°à«àª¯àª¾ àªªàª›à«€ àª¨à«‹ àª–àª°à«àªš)',
                    readOnly: true,
                  ),
                  // const SizedBox(height: 4),
                  // const Text(
                  //   'Quotation: Total Cost = Solar Rooftop System Total Cost + Elevated Structure Cost + GEB/Torrent Net Meter Cost + Solar Panel Premium/Other Cost',
                  //   style: TextStyle(fontSize: 11, color: LeadTheme.textMuted),
                  // ),
                  // const SizedBox(height: 3),
                  // const Text(
                  //   'System Cost After Subsidy = Total Cost âˆ’ Subsidy',
                  //   style: TextStyle(fontSize: 11, color: LeadTheme.textMuted),
                  // ),
                ],
              ),
            ),
            // â”€â”€ Gujarati Terms & Conditions (replaces English version) â”€â”€â”€â”€â”€â”€â”€â”€
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('àª¨àª¿àª¯àª®à«‹ àª…àª¨à«‡ àª¶àª°àª¤à«‹'),
                  const SizedBox(height: 12),
                  _gujaratiPaymentRow(
                    'àªªà«‡àª®à«‡àª¨à«àªŸ à«¦à«§',
                    '10% àªàª¡àªµàª¾àª¨à«àª¸ àª°àªœà«€àª¸à«àªŸà«àª°à«‡àª¶àª¨, àª®à«€àªŸàª° àªšàª¾àª°à«àªœ àª®àª¾àªŸà«‡ â€“ Non Refundable.',
                  ),
                  const SizedBox(height: 6),
                  _gujaratiPaymentRow(
                    'àªªà«‡àª®à«‡àª¨à«àªŸ à«¦à«¨',
                    '80% àª¸à«àªŸà«àª°àª•à«àªšàª° àª¬àª¨à«€ àªœàª¾àª¯ àªªàª›à«€ àª…àª¨à«‡ àªªà«‡àª¨àª² àªªàª¹à«‹àª‚àªš àª àªªàª¹à«‡àª²àª¾.',
                  ),
                  const SizedBox(height: 6),
                  _gujaratiPaymentRow(
                    'àªªà«‡àª®à«‡àª¨à«àªŸ à«¦à«©',
                    '10% àª¸àª¿àª¸à«àªŸàª® àª‡àª¨à«àª¸à«àªŸà«‹àª² àª¥àªˆ àªœàª¾àª¯ àªªàª›à«€.',
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'àª•à«‹àªŸà«‡àª¶àª¨ àªªà«àª°àª®àª¾àª£à«‡ àªµàª¸à«àª¤à«, àª¸àª°à«àªµàª¿àª¸ àª•à«‡ àª…àª¨à«àª¯ àª•àª¾àª®àª®àª¾àª‚ àªªàª¾àª›àª³ àª¥à«€ àª•àª°à«‡àª²à«‹ àª«à«‡àª°àª«àª¾àª° àª àªµàª§àª¾àª°àª¾àª¨àª¾ àª–àª°à«àªš àª¸àª¾àª¥à«‡ àª°àª¹à«‡àª¶à«‡.',
                    style: TextStyle(
                      fontSize: 12,
                      color: LeadTheme.textPrimary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'àªœà«€àªˆàª¬à«€ àª…àª¥àªµàª¾ àªŸà«‹àª°àª¨à«àªŸ àª˜àª°àª¨à«€ àª¸à«àª°àª•à«àª·àª¾ àª®àª¾àªŸà«‡ àª‡àªàª¬/àª«à«àª¯à«‚àª àª²àª—àª¾àª¡àªµàª¾ àª¨à«àª‚ àª•àª¹à«‡ àª…àª¥àªµàª¾ àª²à«‹àª¡ àªµàª§àª¾àª°àª¾àª¨à«àª‚ àª•àª¹à«‡ àª¤à«‹ àª àª—à«àª°àª¾àª¹àª•àª¨à«€ àªœàªµàª¾àª¬àª¦àª¾àª°à«€ àª®àª¾àª‚ àª°àª¹à«‡àª¶à«‡. àªœà«€àªˆàª¬à«€ àª®àª¾àª‚ àª¨àªµàª¾ àª®à«€àªŸàª° àª®àª¾àªŸà«‡ à«§.à«« àª«à«‚àªŸ àªŸ à«§.à«« àª«à«‚àªŸ àª¨à«àª‚ àª²àª¾àª•àª¡àª¾/àª«àª¾àª‡àª¬àª° àª¨à«àª‚ àªªàª¾àªŸàª¿àª¯à«àª‚ àª²àª—àª¾àª¡àªµàª¾àª¨à«àª‚ àª°àª¹à«‡àª¶à«‡.',
                    style: TextStyle(
                      fontSize: 12,
                      color: LeadTheme.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Warranty & Notes'),
                  const SizedBox(height: 10),
                  if (!widget.isEditing) ...[
                    _field(
                      warrantyNoteC,
                      'Warranty Note',
                      AppSvgAssets.circleCheckBig,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _field(
                    notesC,
                    'Additional Notes',
                    AppSvgAssets.fileText,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LeadTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing
                            ? 'Update Quotation'
                            : 'Send Quotation',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Gujarati payment row helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Widget _gujaratiPaymentRow(String label, String description) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LeadTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LeadTheme.primary,
        ),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 12,
          color: LeadTheme.textPrimary,
          height: 1.5,
        ),
      ),
    ),
  ],
);

// â”€â”€ Shared helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Widget _infoBanner(SolarLeadsModel lead) => Container(
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
              '${lead.mobile}  Â·  ${lead.address}',
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

Widget _field(
  TextEditingController c,
  String label,
  String svgAsset, {
  int maxLines = 1,
}) => TextField(
  controller: c,
  maxLines: maxLines,
  style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
  decoration: InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12, color: LeadTheme.textSecondary),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
  ),
);

Widget _numField(
  TextEditingController c,
  String label, {
  void Function(String)? onChange,
  bool readOnly = false,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    TextField(
      controller: c,
      keyboardType: TextInputType.number,
      readOnly: readOnly,
      onChanged: onChange,
      style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: LeadTheme.textSecondary,
        ),
        filled: true,
        fillColor: LeadTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 16,
        ),
      ),
    ),
  ],
);

