import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/core/app_colors.dart';

class SprinklerPaymentScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SprinklerPaymentScreen({super.key, required this.lead});
  @override
  State<SprinklerPaymentScreen> createState() => _State();
}

class _State extends State<SprinklerPaymentScreen> {
  late SprinklerLeadModel lead;
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

  double get totalAmount => lead.dealData.finalDealAmount ?? lead.totalAmount;
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
    context.read<SprinklerLeadCubit>().addPayment(
      widget.lead.id,
      amount: amount,
      mode: modeMap[selectedMode] ?? selectedMode!.toLowerCase(),
      type: 'partial',
      transactionId: txnIdC.text.trim().isEmpty ? null : txnIdC.text.trim(),
      notes: notesC.text.trim().isEmpty ? null : notesC.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (state is SprinklerLeadSaved) {
          setState(() {
            lead = state.lead;
            _saving = false;
            amountC.clear();
            txnIdC.clear();
            notesC.clear();
          });
          if (state.lead.isFullyPaid ||
              state.lead.currentStep == SprinklerStep.fullPayment) {
            AppFeedback.showSuccess(context, '🎉 Payment completed!');
          }
          Navigator.pop(context);
        }
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
              color: AppColors.surface,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Payment',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LeadTheme.bg,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Done',
                style: TextStyle(color: LeadTheme.secondary),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _spkBanner(lead),
            const SizedBox(height: 10),

            // ── Payment summary ──────────────────────────────────────────────
            CompactCard(
              child: Column(
                children: [
                  _pRow(
                    'Total Amount',
                    '₹${totalAmount.toStringAsFixed(0)}',
                    Colors.grey.shade600,
                  ),
                  _pRow(
                    'Paid So Far',
                    '₹${alreadyPaid.toStringAsFixed(0)}',
                    AppColors.success,
                  ),
                  const Divider(height: 16),
                  _pRow(
                    'Remaining',
                    '₹${remaining.toStringAsFixed(0)}',
                    remaining > 0 ? AppColors.solar : AppColors.success,
                    large: true,
                  ),
                ],
              ),
            ),

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
                      color: AppColors.background,
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

            if (remaining > 0) ...[
              CompactCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Add Payment'),
                    const SizedBox(height: 10),
                    _spkNumField(
                      amountC,
                      'Amount (₹)',
                      icon: AppSvgAssets.indianRupee,
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
                                  size: 13,
                                  color: selected
                                      ? LeadTheme.secondary
                                      : LeadTheme.textSecondary,
                                ),
                                const SizedBox(width: 5),
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
                    const SizedBox(height: 10),
                    _spkField(
                      txnIdC,
                      'Transaction ID (for digital payments)',
                      AppSvgAssets.fileText,
                    ),
                    const SizedBox(height: 8),
                    _spkField(
                      notesC,
                      'Payment notes (optional)',
                      AppSvgAssets.fileText,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              _spkSaveBtn(_saving, _addPayment, 'Record Payment'),
            ],

            // ── Payment history ──────────────────────────────────────────────
            if (lead.paymentHistory.isNotEmpty) ...[
              const SizedBox(height: 10),
              CompactCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Payment History'),
                    const SizedBox(height: 8),
                    ...lead.paymentHistory.asMap().entries.map((e) {
                      final i = e.key;
                      final p = e.value;
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
                                    '${(p['type'] ?? '').toString().toUpperCase()} · ${p['mode'] ?? ''}',
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

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _spkBanner(SprinklerLeadModel lead) {
    return Container(
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
  }

  Widget _spkField(
    TextEditingController c,
    String label,
    String svgAsset, {
    int maxLines = 1,
    TextInputType? type,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: type,
      style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: LeadTheme.textSecondary,
        ),
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
      ),
    );
  }

  Widget _spkNumField(
    TextEditingController c,
    String label, {
    String? icon,
    void Function(String)? onChange,
  }) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      onChanged: onChange,
      style: const TextStyle(fontSize: 13, color: LeadTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: LeadTheme.textSecondary,
        ),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: AppSvgIcon(
                  icon,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _spkSaveBtn(bool saving, VoidCallback onPressed, String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LeadTheme.secondary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _pRow(String label, String value, Color color, {bool large = false}) {
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
}
