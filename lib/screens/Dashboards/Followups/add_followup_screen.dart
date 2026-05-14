// lib/screens/Followup/add_followup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/services/api_service.dart';

/// Universal add-followup screen — works for both Solar and Sprinkler leads.
/// Pass [module] = "solar" or "sprinkler" and [leadId].
class AddFollowupScreen extends StatefulWidget {
  final String leadId;
  final String module; // "solar" | "sprinkler" | "material"
  final String customerName;
  final DateTime? currentNextDate;
  final String? materialAssignedToId;

  const AddFollowupScreen({
    super.key,
    required this.leadId,
    required this.module,
    required this.customerName,
    this.currentNextDate,
    this.materialAssignedToId,
  });

  @override
  State<AddFollowupScreen> createState() => _AddFollowupScreenState();
}

class _AddFollowupScreenState extends State<AddFollowupScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _remarkCtl = TextEditingController();
  final _durationCtl = TextEditingController();

  String _followupType = 'call';
  DateTime _nextFollowupDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nextFollowupDate =
        widget.currentNextDate ?? DateTime.now().add(const Duration(days: 7));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextFollowupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextFollowupDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final remark = _remarkCtl.text.trim();
    final callDuration = int.tryParse(_durationCtl.text.trim());

    try {
      if (widget.module == 'solar') {
        await context.read<SolarLeadCubit>().addFollowupEntry(
          widget.leadId,
          remark: remark,
          followupType: _followupType,
          nextFollowupDate: _nextFollowupDate,
          callDuration: callDuration,
        );
      } else if (widget.module == 'sprinkler') {
        await context.read<SprinklerLeadCubit>().addFollowupEntry(
          widget.leadId,
          remark: remark,
          followupType: _followupType,
          nextFollowupDate: _nextFollowupDate,
          callDuration: callDuration,
        );
      } else {
        final assignedToId = widget.materialAssignedToId?.trim() ?? '';
        if (assignedToId.isEmpty) {
          setState(() => _saving = false);
          _showError(
            'Sales person is not assigned. Please assign first in Material pipeline.',
          );
          return;
        }
        await _apiService.updateMaterialCustomerPipeline(
          widget.leadId,
          step: 'followUp',
          payload: {
            'assignedTo': assignedToId,
            'followUpAt': _nextFollowupDate.toIso8601String(),
          },
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.toString());
    }
  }

  @override
  void dispose() {
    _remarkCtl.dispose();
    _durationCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSolar = widget.module == 'solar';
    final isSprinkler = widget.module == 'sprinkler';
    final isMaterial = widget.module == 'material';

    Widget body;
    if (isMaterial) {
      body = _buildForm();
    } else {
      body = BlocListener<SolarLeadCubit, SolarLeadState>(
        listener: (ctx, state) {
          if (!isSolar) return;
          if (state is SolarLeadSaved) {
            Navigator.pop(context, true); // true = refreshed
          } else if (state is SolarLeadError) {
            setState(() => _saving = false);
            _showError(state.message);
          }
        },
        child: BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
          listener: (ctx, state) {
            if (!isSprinkler) return;
            if (state is SprinklerLeadSaved) {
              Navigator.pop(context, true);
            } else if (state is SprinklerLeadError) {
              setState(() => _saving = false);
              _showError(state.message);
            }
          },
          child: _buildForm(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:   AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.chevronLeft,
            size: 20,
            color: AppColors.slate800,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Follow-up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
            Text(
              widget.customerName,
              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
          ],
        ),
      ),
      body: body,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Followup Type ───────────────────────────────────────────────
          _Section(
            title: 'Follow-up Type',
            required: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypeChip(
                  label: '📞 Call',
                  value: 'call',
                  selected: _followupType == 'call',
                  onTap: () => setState(() => _followupType = 'call'),
                ),
                _TypeChip(
                  label: '🏠 Visit',
                  value: 'visit',
                  selected: _followupType == 'visit',
                  onTap: () => setState(() => _followupType = 'visit'),
                ),
                _TypeChip(
                  label: '💬 WhatsApp',
                  value: 'whatsapp',
                  selected: _followupType == 'whatsapp',
                  onTap: () => setState(() => _followupType = 'whatsapp'),
                ),
                _TypeChip(
                  label: '🤝 Meeting',
                  value: 'meeting',
                  selected: _followupType == 'meeting',
                  onTap: () => setState(() => _followupType = 'meeting'),
                ),
                _TypeChip(
                  label: '💰 Payment',
                  value: 'paymentReminder',
                  selected: _followupType == 'paymentReminder',
                  onTap: () =>
                      setState(() => _followupType = 'paymentReminder'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Remark ──────────────────────────────────────────────────────
          _Section(
            title: 'Remark',
            required: true,
            child: TextFormField(
              controller: _remarkCtl,
              maxLines: 4,
              decoration: _inputDec('What happened in this follow-up?'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Remark is required' : null,
            ),
          ),

          const SizedBox(height: 16),

          // ── Next Follow-up Date ─────────────────────────────────────────
          _Section(
            title: 'Next Follow-up Date',
            required: true,
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color:   AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon(
                      AppSvgAssets.calendarDays,
                      size: 18,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_nextFollowupDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slate800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Call Duration (optional) ────────────────────────────────────
          if (_followupType == 'call') ...[
            _Section(
              title: 'Call Duration (minutes)',
              required: false,
              child: TextFormField(
                controller: _durationCtl,
                keyboardType: TextInputType.number,
                decoration: _inputDec('e.g. 5'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Save Button ─────────────────────────────────────────────────
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor:   AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Follow-up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.slate300, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.slate200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.slate200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
    ),
  );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final bool required;
  final Widget child;
  const _Section({
    required this.title,
    required this.required,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ?   AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ?   AppColors.blue :   AppColors.slate200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white :   AppColors.slate500,
          ),
        ),
      ),
    );
  }
}


