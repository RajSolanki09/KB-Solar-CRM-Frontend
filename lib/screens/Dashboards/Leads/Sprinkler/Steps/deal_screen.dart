import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';

class SprinklerDealScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SprinklerDealScreen({super.key, required this.lead});
  @override
  State<SprinklerDealScreen> createState() => _State();
}

class _State extends State<SprinklerDealScreen> {
  final finalAmtC = TextEditingController();
  final discountC = TextEditingController();
  final advanceC = TextEditingController();
  final notesC = TextEditingController();
  String? selectedMode;
  bool _saving = false;

  final modes = ['Cash', 'Bank Transfer', 'Cheque', 'UPI', 'Loan'];
  final modeMap = const {
    'Cash': 'cash',
    'Bank Transfer': 'bankTransfer',
    'Cheque': 'cheque',
    'UPI': 'upi',
    'Loan': 'loan',
  };
  final modeIcons = const {
    'Cash': AppSvgAssets.indianRupee,
    'Bank Transfer': AppSvgAssets.building2,
    'Cheque': AppSvgAssets.fileText,
    'UPI': AppSvgAssets.phone,
    'Loan': AppSvgAssets.idCard,
  };

  @override
  void initState() {
    super.initState();
    final d = widget.lead.dealData;

    // quotationFinalAmount is a double (non-nullable) so direct call is safe,
    // but guard against zero so the field stays empty rather than showing "0".
    final quotationAmt = widget.lead.quotationFinalAmount ?? 0.0;
    finalAmtC.text =
        d.finalDealAmount?.toStringAsFixed(0) ??
        (quotationAmt > 0 ? quotationAmt.toStringAsFixed(0) : '');

    discountC.text = d.discountGiven > 0
        ? d.discountGiven.toStringAsFixed(0)
        : '';
    advanceC.text = d.advancePayment?.toStringAsFixed(0) ?? '';
    notesC.text = d.notes ?? '';

    final raw = d.paymentMode;
    selectedMode = raw == null
        ? null
        : modeMap.entries
              .firstWhere(
                (e) => e.value == raw,
                orElse: () => MapEntry(raw, raw),
              )
              .key;
  }

  @override
  void dispose() {
    for (final c in [finalAmtC, discountC, advanceC, notesC]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    setState(() => _saving = true);
    context.read<SprinklerLeadCubit>().saveDeal(
      widget.lead.id,
      finalDealAmount: double.tryParse(finalAmtC.text),
      discountGiven: double.tryParse(discountC.text),
      advancePayment: double.tryParse(advanceC.text),
      paymentMode: selectedMode == null ? null : modeMap[selectedMode],
      notes: notesC.text.trim().isEmpty ? null : notesC.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = double.tryParse(finalAmtC.text) ?? 0;
    final a = double.tryParse(advanceC.text) ?? 0;

    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (state is SprinklerLeadSaved) Navigator.pop(context);
        if (state is SprinklerLeadError) {
          setState(() => _saving = false);
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: LeadTheme.bg,
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
            'Deal Closed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white
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
                        color: LeadTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _spkBanner(widget.lead),
            const SizedBox(height: 10),

            // ── Deal Amount ────────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Deal Amount'),
                  const SizedBox(height: 10),
                  _spkNumField(
                    finalAmtC,
                    'Final Deal Amount (₹)',
                    icon: AppSvgAssets.indianRupee,
                    onChange: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  _spkNumField(
                    discountC,
                    'Discount Given (₹)',
                    icon: AppSvgAssets.trendingUp,
                  ),
                  const SizedBox(height: 8),
                  _spkNumField(
                    advanceC,
                    'Advance Received (₹)',
                    icon: AppSvgAssets.indianRupee,
                    onChange: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            // ── Summary ────────────────────────────────────────────────────
            if (f > 0)
              CompactCard(
                child: Column(
                  children: [
                    CompactRow(
                      label: 'Deal Amount',
                      value: '₹${f.toStringAsFixed(0)}',
                    ),
                    CompactRow(
                      label: 'Advance Paid',
                      value: '₹${a.toStringAsFixed(0)}',
                    ),
                    const Divider(height: 12),
                    CompactRow(
                      label: 'Remaining Balance',
                      value:
                          '₹${(f - a).clamp(0, double.infinity).toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

            // ── Payment Mode ───────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Payment Mode'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: modes.map((m) {
                      final selected = selectedMode == m;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedMode = selected ? null : m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? LeadTheme.secondary.withValues(alpha: 0.12)
                                : LeadTheme.surface,
                            border: Border.all(
                              color: selected
                                  ? LeadTheme.secondary
                                  : Colors.grey.shade300,
                              width: selected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppSvgIcon(
                                modeIcons[m]!,
                                size: 14,
                                color: selected
                                    ? LeadTheme.secondary
                                    : LeadTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                m,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? LeadTheme.secondary
                                      : LeadTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── Notes ──────────────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _spkField(
                    notesC,
                    'Deal notes...',
                    AppSvgAssets.fileText,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _spkSaveBtn(_saving, _save, 'Confirm Deal Closed'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _spkBanner(SprinklerLeadModel lead) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: LeadTheme.secondary.withValues(alpha: 0.06),
      border: Border.all(color: LeadTheme.secondary.withValues(alpha: 0.2)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const AppSvgIcon(
          AppSvgAssets.droplet,
          size: 16,
          color: LeadTheme.secondary,
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
                '${lead.phone}  ·  ${lead.address}',
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

  Widget _spkField(
    TextEditingController c,
    String label,
    String svgAsset, {
    int maxLines = 1,
    TextInputType? type,
  }) => LeadTextFormField(
    controller: c,
    label: label,
    svgIcon: svgAsset,
    accentColor: LeadTheme.secondary,
    required: false,
    maxLines: maxLines,
    keyboardType: type ?? TextInputType.text,
    bottomSpacing: 0,
  );

  Widget _spkNumField(
    TextEditingController c,
    String label, {
    String? icon,
    void Function(String)? onChange,
  }) => LeadTextFormField(
    controller: c,
    label: label,
    svgIcon: icon ?? AppSvgAssets.fileText,
    accentColor: LeadTheme.secondary,
    required: false,
    keyboardType: TextInputType.number,
    onChanged: onChange,
    bottomSpacing: 0,
  );

  Widget _spkSaveBtn(
    bool saving,
    VoidCallback onPressed,
    String label,
  ) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: saving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: LeadTheme.secondary,
        foregroundColor: Colors.white,
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
}
