// lib/screens/Dashboards/Leads/Sprinkler/Steps/spk_quotation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';

class SprinklerQuotationScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  final bool isEditing;
  const SprinklerQuotationScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SprinklerQuotationScreen> createState() => _SpkQuotationState();
}

class _SpkQuotationState extends State<SprinklerQuotationScreen> {
  final totalAmountC = TextEditingController();
  final discountC = TextEditingController();
  final finalAmountC = TextEditingController();
  final advancePercentC = TextEditingController(text: '60');
  final balancePercentC = TextEditingController(text: '40');
  final warrantyNoteC = TextEditingController(
    text: 'Above quotation fully auto cleaning system with 1 year service warranty',
  );
  final notesC = TextEditingController();
  final List<_QuotationLineItemDraft> _lineItems = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.lead.quotationData;
    totalAmountC.text = q.totalAmount > 0 ? q.totalAmount.toStringAsFixed(0) : '';
    discountC.text = q.discount > 0 ? q.discount.toStringAsFixed(0) : '';
    finalAmountC.text = q.finalAmount > 0 ? q.finalAmount.toStringAsFixed(0) : '';
    advancePercentC.text = q.advancePercent?.toStringAsFixed(0) ?? '60';
    balancePercentC.text = q.balancePercent?.toStringAsFixed(0) ?? '40';
    if (q.warrantyNote?.isNotEmpty == true) warrantyNoteC.text = q.warrantyNote!;
    notesC.text = q.notes ?? '';
    _seedLineItems(q);
    _calcFinal();
  }

  @override
  void dispose() {
    for (final item in _lineItems) {
      item.dispose();
    }
    for (final c in [
      totalAmountC, discountC, finalAmountC,
      advancePercentC, balancePercentC, warrantyNoteC, notesC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedLineItems(SprinklerQuotationData q) {
    if (q.lineItems.isNotEmpty) {
      for (final item in q.lineItems) {
        _lineItems.add(
          _QuotationLineItemDraft(
            description: item.description,
            quantity: item.quantity,
            unitPrice: item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(0) : '',
            total: item.total > 0 ? item.total.toStringAsFixed(0) : '',
          ),
        );
      }
    }
    if (_lineItems.isEmpty) {
      _lineItems.add(_QuotationLineItemDraft());
    }
  }

  double? _quantityValue(String raw) {
    final direct = double.tryParse(raw.trim());
    if (direct != null) return direct;
    final match = RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)').firstMatch(raw);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  void _recomputeLineTotal(_QuotationLineItemDraft item) {
    final qty = _quantityValue(item.quantityC.text);
    final unit = double.tryParse(item.unitPriceC.text.trim());
    if (qty == null || unit == null) return;
    item.totalC.text = (qty * unit).toStringAsFixed(0);
  }

  void _addLineItem() {
    setState(() => _lineItems.add(_QuotationLineItemDraft()));
  }

  void _removeLineItem(int index) {
    if (_lineItems.length <= 1) return;
    setState(() {
      final item = _lineItems.removeAt(index);
      item.dispose();
      _calcFinal();
    });
  }

  void _calcFinal() {
    final total = _lineItems.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.totalC.text.trim()) ?? 0),
    );
    final disc = double.tryParse(discountC.text) ?? 0;
    setState(() {
      totalAmountC.text = total.toStringAsFixed(0);
      finalAmountC.text = (total - disc).clamp(0, double.infinity).toStringAsFixed(0);
    });
    _calcPayment();
  }

  void _calcPayment() {
    final advP = double.tryParse(advancePercentC.text) ?? 60;
    setState(() => balancePercentC.text = (100 - advP).clamp(0, 100).toStringAsFixed(0));
  }

  void _save() {
    setState(() => _saving = true);
    final cubit = context.read<SprinklerLeadCubit>();
    final id = widget.lead.id;
    String? t(String v) => v.trim().isEmpty ? null : v.trim();

    cubit.saveQuotation(
      id,
      lineItems: _lineItems
          .map((item) => item.toPayload())
          .where((item) => (item['description'] as String).isNotEmpty)
          .toList(),
      totalAmount: double.tryParse(totalAmountC.text),
      discount: double.tryParse(discountC.text),
      advancePercent: double.tryParse(advancePercentC.text),
      balancePercent: double.tryParse(balancePercentC.text),
      warrantyNote: t(warrantyNoteC.text),
      notes: t(notesC.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (state is SprinklerLeadSaved) {
          setState(() => _saving = false);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) Navigator.pop(context);
          });
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
          title: Text(
            widget.isEditing ? 'Edit Quotation' : 'Quotation',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        bottomNavigationBar: _buildSaveBar(),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _infoBanner(widget.lead),
            const SizedBox(height: 10),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Quotation Items'),
                  const SizedBox(height: 10),
                  ...List.generate(_lineItems.length, (index) {
                    final item = _lineItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LeadTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LeadTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Item ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: LeadTheme.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeLineItem(index),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                color: AppColors.error,
                                tooltip: 'Remove Item',
                              ),
                            ],
                          ),
                          _spkTextField(item.descriptionC, 'Description', AppSvgAssets.fileText),
                          const SizedBox(height: 8),
                          _spkTextField(item.quantityC, 'Quantity (e.g. 10 sets)', AppSvgAssets.activity, onChange: (_) {
                            _recomputeLineTotal(item);
                            _calcFinal();
                          }),
                          const SizedBox(height: 8),
                          _spkNumField(item.unitPriceC, 'Unit Price (Rs.)', decimal: true, onChange: (_) {
                            _recomputeLineTotal(item);
                            _calcFinal();
                          }),
                          const SizedBox(height: 8),
                          _spkNumField(item.totalC, 'Line Total (Rs.)', decimal: true, onChange: (_) => _calcFinal()),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Item'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Cost'),
                  const SizedBox(height: 10),
                  _spkNumField(totalAmountC, 'Total Amount (Rs.)', decimal: true, readOnly: true),
                  const SizedBox(height: 8),
                  _spkNumField(discountC, 'Discount (Rs.)', decimal: true, onChange: (_) => _calcFinal()),
                  const SizedBox(height: 8),
                  _spkNumField(finalAmountC, 'Final Amount (Rs.)', readOnly: true),
                ],
              ),
            ),
            const SizedBox(height: 10),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Payment Terms'),
                  const SizedBox(height: 10),
                  _spkNumField(advancePercentC, 'Advance %', decimal: true, onChange: (_) => _calcPayment()),
                  const SizedBox(height: 8),
                  _spkNumField(balancePercentC, 'Balance %', readOnly: true),
                  const SizedBox(height: 8),
                  _spkTextField(warrantyNoteC, 'Warranty Note', AppSvgAssets.fileText, maxLines: 2),
                  const SizedBox(height: 8),
                  _spkTextField(notesC, 'Notes', AppSvgAssets.fileText, maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: LeadTheme.secondary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: LeadTheme.secondary.withOpacity(0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  'Save Quotation',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

Widget _infoBanner(SprinklerLeadModel lead) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: LeadTheme.surface,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: LeadTheme.border),
  ),
  child: Row(
    children: [
      Text(
        lead.customerName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LeadTheme.textPrimary),
      ),
      const SizedBox(width: 8),
      Text(lead.village, style: const TextStyle(fontSize: 12, color: LeadTheme.textSecondary)),
    ],
  ),
);

Widget _spkTextField(
  TextEditingController c,
  String label,
  String svgAsset, {
  int maxLines = 1,
  void Function(String)? onChange,
}) => LeadTextFormField(
  controller: c,
  label: label,
  svgIcon: svgAsset,
  accentColor: LeadTheme.secondary,
  required: false,
  maxLines: maxLines,
  onChanged: onChange,
  bottomSpacing: 0,
);

class _QuotationLineItemDraft {
  final TextEditingController descriptionC;
  final TextEditingController quantityC;
  final TextEditingController unitPriceC;
  final TextEditingController totalC;

  _QuotationLineItemDraft({
    String description = '',
    String quantity = '',
    String unitPrice = '',
    String total = '',
  }) : descriptionC = TextEditingController(text: description),
       quantityC = TextEditingController(text: quantity),
       unitPriceC = TextEditingController(text: unitPrice),
       totalC = TextEditingController(text: total);

  Map<String, dynamic> toPayload() => {
    'description': descriptionC.text.trim(),
    'quantity': quantityC.text.trim(),
    'unitPrice': double.tryParse(unitPriceC.text.trim()) ?? 0,
    'total': double.tryParse(totalC.text.trim()) ?? 0,
  };

  void dispose() {
    descriptionC.dispose();
    quantityC.dispose();
    unitPriceC.dispose();
    totalC.dispose();
  }
}

Widget _spkNumField(
  TextEditingController c,
  String label, {
  void Function(String)? onChange,
  bool readOnly = false,
  bool decimal = false,
}) => LeadTextFormField(
  controller: c,
  label: label,
  svgIcon: AppSvgAssets.indianRupee,
  accentColor: LeadTheme.secondary,
  required: false,
  readOnly: readOnly,
  keyboardType: decimal
      ? const TextInputType.numberWithOptions(decimal: true)
      : TextInputType.number,
  onChanged: onChange,
  fillColor: readOnly ? AppColors.purple100 : LeadTheme.surface,
  bottomSpacing: 0,
);




