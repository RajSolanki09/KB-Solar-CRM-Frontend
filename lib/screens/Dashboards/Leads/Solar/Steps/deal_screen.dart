import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';

class SolarDealScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarDealScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarDealScreen> createState() => _State();
}

class _State extends State<SolarDealScreen> {
  final finalAmountC = TextEditingController();
  final advanceC = TextEditingController();
  final notesC = TextEditingController();

  String? selectedPaymentMode;
  bool _saving = false;

  final paymentModes = ['Cash', 'Bank Transfer', 'Cheque', 'UPI', 'Loan'];
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
    final l = widget.lead;
    finalAmountC.text =
        l.finalAmount?.toStringAsFixed(0) ??
        l.customerPayable.toStringAsFixed(0);
    advanceC.text = l.advancePayment?.toStringAsFixed(0) ?? '';
    notesC.text = l.dealData.notes ?? '';

    final raw = l.paymentMode;
    selectedPaymentMode = raw == null
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
    finalAmountC.dispose();
    advanceC.dispose();
    notesC.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;

    if (widget.isEditing) {
      cubit.editDeal(
        id,
        finalAmount: double.tryParse(finalAmountC.text),
        advancePayment: double.tryParse(advanceC.text),
        paymentMode: selectedPaymentMode == null
            ? null
            : modeMap[selectedPaymentMode],
        notes: notesC.text.trim().isEmpty ? null : notesC.text.trim(),
      );
    } else {
      cubit.saveDeal(
        id,
        finalAmount: double.tryParse(finalAmountC.text),
        advancePayment: double.tryParse(advanceC.text),
        paymentMode: selectedPaymentMode == null
            ? null
            : modeMap[selectedPaymentMode],
        notes: notesC.text.trim().isEmpty ? null : notesC.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = double.tryParse(finalAmountC.text) ?? 0;
    final a = double.tryParse(advanceC.text) ?? 0;

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
            widget.isEditing ? 'Edit Deal' : 'Deal Closed',
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

            // ── Payment details ────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Payment Details'),
                  const SizedBox(height: 10),
                  _numField(
                    finalAmountC,
                    'Final Amount (₹)',
                    svgAsset: AppSvgAssets.indianRupee,
                    onChange: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  _numField(
                    advanceC,
                    'Advance Received (₹)',
                    svgAsset: AppSvgAssets.indianRupee,
                    onChange: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            // ── Payment mode chips ─────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Payment Mode'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: paymentModes.map((m) {
                      final selected = selectedPaymentMode == m;
                      return GestureDetector(
                        onTap: () => setState(
                          () => selectedPaymentMode = selected ? null : m,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? LeadTheme.primary.withValues(alpha: 0.12)
                                : LeadTheme.surface,
                            border: Border.all(
                              color: selected
                                  ? LeadTheme.primary
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
                                    ? LeadTheme.primary
                                    : LeadTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                m,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? LeadTheme.primary
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

            // ── Summary ───────────────────────────────────────────────
            if (f > 0)
              CompactCard(
                child: Column(
                  children: [
                    CompactRow(
                      label: 'Final Amount',
                      value: '₹${f.toStringAsFixed(0)}',
                    ),
                    CompactRow(
                      label: 'Advance Paid',
                      value: '₹${a.toStringAsFixed(0)}',
                    ),
                    const Divider(height: 12),
                    CompactRow(
                      label: 'Remaining',
                      value:
                          '₹${(f - a).clamp(0, double.infinity).toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

            // ── Notes ─────────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _field(
                    notesC,
                    'Add notes about this deal...',
                    AppSvgAssets.fileText,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _saveBtn(
              _saving,
              _save,
              widget.isEditing ? 'Update Deal' : 'Confirm Deal Closed',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  ),
);

Widget _numField(
  TextEditingController c,
  String label, {
  String? svgAsset,
  void Function(String)? onChange,
}) => TextField(
  controller: c,
  keyboardType: TextInputType.number,
  onChanged: onChange,
  style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
  decoration: InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12, color: LeadTheme.textSecondary),
    prefixIcon: svgAsset != null
        ? Padding(
            padding: const EdgeInsets.only(left: 10, right: 6),
            child: AppSvgIcon(
              svgAsset,
              size: 16,
              color: LeadTheme.textSecondary,
            ),
          )
        : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 36),
    filled: true,
    fillColor: LeadTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  ),
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
