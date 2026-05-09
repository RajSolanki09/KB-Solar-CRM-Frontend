import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/core/app_colors.dart';

class SolarPaymentScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarPaymentScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarPaymentScreen> createState() => _State();
}

class _State extends State<SolarPaymentScreen> {
  late SolarLeadsModel lead;
  final amountC = TextEditingController();
  final txnIdC = TextEditingController();
  final notesC = TextEditingController();
  String? selectedMode;
  bool _saving = false;

  final modes = ['Cash', 'Bank Transfer', 'Cheque', 'UPI'];
  final modeMap = const {
    'Cash': 'cash',
    'Bank Transfer': 'bankTransfer',
    'Cheque': 'cheque',
    'UPI': 'upi',
  };
  final modeIcons = const {
    'Cash': AppSvgAssets.indianRupee,
    'Bank Transfer': AppSvgAssets.building2,
    'Cheque': AppSvgAssets.fileText,
    'UPI': AppSvgAssets.phone,
  };

  double get totalAmount => lead.finalAmount ?? lead.totalAmount;
  double get alreadyPaid => lead.paidAmount;
  double get remaining => (totalAmount - alreadyPaid).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    lead = widget.lead;
    amountC.text = remaining > 0 ? remaining.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    amountC.dispose();
    txnIdC.dispose();
    notesC.dispose();
    super.dispose();
  }

  void _addPayment() {
    final amount = double.tryParse(amountC.text);
    if (amount == null || amount <= 0 || selectedMode == null) {
      AppFeedback.showInfo(context, 'Enter amount and select payment mode');
      return;
    }

    setState(() => _saving = true);

    context.read<SolarLeadCubit>().addPayment(
      widget.lead.id,
      amount: amount,
      mode: modeMap[selectedMode] ?? selectedMode!.toLowerCase(),
      type: 'partial',
      notes: notesC.text.trim().isEmpty ? null : notesC.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) {
          setState(() {
            lead = state.lead;
            _saving = false;
            amountC.clear();
            txnIdC.clear();
            notesC.clear();
            selectedMode = null;
          });
          if (state.lead.isCompleted) {
            AppFeedback.showSuccess(
              context,
              '🎉 Payment fully completed! Project Completed!',
            );
            Navigator.pop(context, state.lead);
          } else {
            // Stay on screen — user can add more payments and see the history
            final rem =
                (state.lead.finalAmount ?? state.lead.totalAmount) -
                state.lead.paidAmount;
            amountC.text = rem > 0
                ? rem.clamp(0, double.infinity).toStringAsFixed(0)
                : '';
            AppFeedback.showSuccess(context, 'Payment recorded ✓');
          }
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
            widget.isEditing ? 'Edit Payment' : 'Final Payment',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LeadTheme.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, lead),
              child: const Text(
                'Done',
                style: TextStyle(color: LeadTheme.primary),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _infoBanner(lead),
            const SizedBox(height: 10),

            // ── Summary card ───────────────────────────────────────────
            CompactCard(
              child: Column(
                children: [
                  _summaryRow(
                    'Total Amount',
                    '₹${totalAmount.toStringAsFixed(0)}',
                    Colors.grey,
                  ),
                  _summaryRow(
                    'Paid So Far',
                    '₹${alreadyPaid.toStringAsFixed(0)}',
                    AppColors.success,
                  ),
                  const Divider(height: 16),
                  _summaryRow(
                    'Remaining',
                    '₹${remaining.toStringAsFixed(0)}',
                    remaining > 0 ? AppColors.solar : AppColors.success,
                    large: true,
                  ),
                ],
              ),
            ),

            // ── Fully paid banner ──────────────────────────────────────
            if (remaining <= 0)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  border: Border.all(color: AppColors.success),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    AppSvgIcon(
                      AppSvgAssets.circleCheckBig,
                      color: AppColors.success,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Payment Fully Completed! 🎉',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Add / Edit payment form ────────────────────────────────
            if (remaining > 0) ...[
              CompactCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      widget.isEditing ? 'Edit Payment' : 'Add Payment',
                    ),
                    const SizedBox(height: 10),
                    _numField(
                      amountC,
                      'Amount (₹)',
                      svgAsset: AppSvgAssets.indianRupee,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Payment Mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: LeadTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: modes.map((m) {
                        final selected = selectedMode == m;
                        return GestureDetector(
                          onTap: () => setState(
                            () => selectedMode = selected ? null : m,
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
                                  size: 13,
                                  color: selected
                                      ? LeadTheme.primary
                                      : LeadTheme.textSecondary,
                                ),
                                const SizedBox(width: 5),
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
                    const SizedBox(height: 10),
                    _field(
                      txnIdC,
                      'Transaction ID (for digital payments)',
                      AppSvgAssets.fileText,
                    ),
                    const SizedBox(height: 8),
                    _field(
                      notesC,
                      'Payment notes (optional)',
                      AppSvgAssets.fileText,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              _saveBtn(_saving, _addPayment, 'Record Payment'),
            ],

            // ── Payment history ────────────────────────────────────────
            if (lead.paymentHistory.isNotEmpty) ...[
              const SizedBox(height: 10),
              CompactCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Payment History'),
                    const SizedBox(height: 8),
                    ...lead.paymentHistory.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final date = DateTime.tryParse(
                        p['date']?.toString() ?? '',
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: LeadTheme.bg,
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p['type']?.toString().toUpperCase() ?? ''}  ·  ${p['mode'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: LeadTheme.textSecondary,
                                    ),
                                  ),
                                  if (p['transactionId'] != null)
                                    Text(
                                      'Txn: ${p['transactionId']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: LeadTheme.textMuted,
                                      ),
                                    ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: LeadTheme.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${(p['amount'] as num?)?.toStringAsFixed(0) ?? '-'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _summaryRow(
  String label,
  String value,
  Color color, {
  bool large = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: large ? 13 : 12,
            fontWeight: large ? FontWeight.w600 : FontWeight.normal,
            color: LeadTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
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
