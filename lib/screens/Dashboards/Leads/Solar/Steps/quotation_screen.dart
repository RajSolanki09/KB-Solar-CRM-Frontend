// lib/screens/Dashboards/Leads/Solar/Steps/solar_quotation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
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
  // ── Cost fields ────────────────────────────────────────────────────────────
  final rooftopSystemCostC = TextEditingController();
  final elevatedStructureCostC = TextEditingController();
  final netMeterCostC = TextEditingController();
  final premiumOtherCostC = TextEditingController();
  final totalC = TextEditingController();
  final subsidyC = TextEditingController();
  final systemAfterSubsidyC = TextEditingController();
  // ── Payment terms ──────────────────────────────────────────────────────────
  final advancePercentC = TextEditingController(text: '60');
  final balancePercentC = TextEditingController(text: '40');
  final warrantyNoteC = TextEditingController(
    text: '5 year panel warranty, 1 year service warranty',
  );
  // ── Notes ──────────────────────────────────────────────────────────────────
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
    String? t(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

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

  // ── BUILD UI ───────────────────────────────────────────────────────────────
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
                  buildLabel(
                    'Solar Rooftop System Total Cost (સોલર રૂફટોપ સિસ્ટમ નો ટોટલ ખર્ચ',
                    required: true,
                  ),
                  
                  _numField(rooftopSystemCostC, onChange: (_) => _autoCalc()),
                  const SizedBox(height: 12),
                  buildLabel(
                    'Heighted/Elevated Structure Cost (એલિવેટેડ ફ્રેબિકેશન નો ખર્ચ)',
                    required: true,
                  ),
                  _numField(
                    elevatedStructureCostC,
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  buildLabel(
                    'GEB/Torrent Net Meter Cost (મીટર ખર્ચ)',
                    required: true,
                  ),
                  _numField(netMeterCostC, onChange: (_) => _autoCalc()),
                  const SizedBox(height: 12),
                  buildLabel(
                    'Solar Panel Premium Charge / Other Cost (સોલર પેનલ પ્રીમિયમ ચાર્જ/અન્ય ખર્ચ)',
                    required: true,
                  ),
                  _numField(
                    premiumOtherCostC,
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  buildLabel('Total Net Payable (ટોટલ ભરવા પાત્ર રકમ)',required: true),
                  _numField(
                    totalC,
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  buildLabel('Subsidy (સબસિડી – મીટર લાગ્યા પછી ૩૦ દિવસમાં ગ્રાહકના બેંક ખાતામાં જમા થશે)',required: true),
                  _numField(
                    subsidyC,
                    onChange: (_) => _autoCalc(),
                  ),
                  const SizedBox(height: 12),
                  buildLabel('System Cost After Subsidy (સિસ્ટમ નો સબસિડી બાદ કર્યા પછી નો ખર્ચ)',required: true),
                  _numField(
                    systemAfterSubsidyC,
                    readOnly: true,
                  ),
                  // const SizedBox(height: 4),
                  // const Text(
                  //   'Quotation: Total Cost = Solar Rooftop System Total Cost + Elevated Structure Cost + GEB/Torrent Net Meter Cost + Solar Panel Premium/Other Cost',
                  //   style: TextStyle(fontSize: 11, color: LeadTheme.textMuted),
                  // ),
                  // const SizedBox(height: 3),
                  // const Text(
                  //   'System Cost After Subsidy = Total Cost − Subsidy',
                  //   style: TextStyle(fontSize: 11, color: LeadTheme.textMuted),
                  // ),
                ],
              ),
            ),
            // ── Gujarati Terms & Conditions (replaces English version) ────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('નિયમો અને શરતો'),
                  const SizedBox(height: 12),
                  _gujaratiPaymentRow(
                    'પેમેન્ટ ૦૧',
                    '10% એડવાન્સ રજીસ્ટ્રેશન, મીટર ચાર્જ માટે – Non Refundable.',
                  ),
                  const SizedBox(height: 6),
                  _gujaratiPaymentRow(
                    'પેમેન્ટ ૦૨',
                    '80% સ્ટ્રક્ચર બની જાય પછી અને પેનલ પહોંચ એ પહેલા.',
                  ),
                  const SizedBox(height: 6),
                  _gujaratiPaymentRow(
                    'પેમેન્ટ ૦૩',
                    '10% સિસ્ટમ ઇન્સ્ટોલ થઈ જાય પછી.',
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'કોટેશન પ્રમાણે વસ્તુ, સર્વિસ કે અન્ય કામમાં પાછળ થી કરેલો ફેરફાર એ વધારાના ખર્ચ સાથે રહેશે.',
                    style: TextStyle(
                      fontSize: 12,
                      color: LeadTheme.textPrimary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'જીઈબી અથવા ટોરન્ટ ઘરની સુરક્ષા માટે ઇઝબ/ફ્યૂઝ લગાડવા નું કહે અથવા લોડ વધારાનું કહે તો એ ગ્રાહકની જવાબદારી માં રહેશે. જીઈબી માં નવા મીટર માટે ૧.૫ ફૂટ ટ ૧.૫ ફૂટ નું લાકડા/ફાઇબર નું પાટિયું લગાડવાનું રહેશે.',
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

// ── Gujarati payment row helper ────────────────────────────────────────────────
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

// ── Shared helpers ─────────────────────────────────────────────────────────────
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

Widget _field(
  TextEditingController c,
  String label,
  String svgAsset, {
  int maxLines = 1,
}) => LeadTextFormField(
  controller: c,
  label: label,
  svgIcon: svgAsset,
  accentColor: LeadTheme.orange,
  required: false,
  maxLines: maxLines,
  bottomSpacing: 0,
);

Widget _numField(
  TextEditingController c, {
  void Function(String)? onChange,
  bool readOnly = false,
}) => LeadTextFormField(
  controller: c,
  svgIcon: AppSvgAssets.indianRupee,
  accentColor: LeadTheme.orange,
  required: false,
  keyboardType: TextInputType.number,
  readOnly: readOnly,
  onChanged: onChange,
  bottomSpacing: 0,
);
