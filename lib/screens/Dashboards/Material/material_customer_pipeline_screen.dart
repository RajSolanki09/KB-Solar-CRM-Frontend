import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/services/api_service.dart';

class MaterialCustomerPipelineScreen extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic>? initialCustomer;
  final Color? appBarColor;

  const MaterialCustomerPipelineScreen({
    super.key,
    required this.customerId,
    this.initialCustomer,
    this.appBarColor,
  });

  @override
  State<MaterialCustomerPipelineScreen> createState() =>
      _MaterialCustomerPipelineScreenState();
}

class _MaterialCustomerPipelineScreenState
    extends State<MaterialCustomerPipelineScreen> {
  final ApiService _apiService = ApiService();
  final _sourceFormKey = GlobalKey<FormState>();
  final _followUpFormKey = GlobalKey<FormState>();
  final _dealFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _dispatchFormKey = GlobalKey<FormState>();

  final TextEditingController _materialAmountCtrl = TextEditingController();
  final TextEditingController _finalAmountCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  int _activeStep = 0;

  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _materials = const [];
  List<Map<String, dynamic>> _salesPeople = const [];

  String? _selectedMaterialId;
  String? _selectedAssignedToId;
  DateTime? _followUpDate;
  TimeOfDay? _followUpTime;
  bool? _paymentComplete;
  DateTime? _dispatchDate;

  @override
  void initState() {
    super.initState();
    _customer = widget.initialCustomer;
    _loadAll();
  }

  @override
  void dispose() {
    _materialAmountCtrl.dispose();
    _finalAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _apiService.getMaterialCustomerById(widget.customerId),
        _apiService.getMaterials(),
        _apiService.getMaterialSalesPeople(),
      ]);

      if (!mounted) return;

      _customer = Map<String, dynamic>.from(results[0] as Map<String, dynamic>);
      
      // getMaterials() returns a Map with 'materials' key
      final materialsResponse = results[1] as Map<String, dynamic>;
      _materials = List<Map<String, dynamic>>.from(
        (materialsResponse['materials'] as List?) ?? [],
      );
      
      _salesPeople = List<Map<String, dynamic>>.from(results[2] as List);

      _hydrateFormFromCustomer();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to load pipeline: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> get _pipeline {
    final raw = _customer?['pipeline'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  int get _currentStep {
    final step = _pipeline['currentStep'];
    if (step is num) return step.toInt().clamp(-1, 5);
    return -1;
  }

  bool get _isCompleted => _pipeline['isCompleted'] == true;

  bool get _projectCompletedAuto => _isCompleted || _dispatchDate != null;

  int get _nextPendingStep {
    if (_projectCompletedAuto) return 5;
    return (_currentStep + 1).clamp(0, 4);
  }

  void _hydrateFormFromCustomer() {
    final source = _toMap(_pipeline['source']);
    final followUp = _toMap(_pipeline['followUp']);
    final dealDone = _toMap(_pipeline['dealDone']);
    final payment = _toMap(_pipeline['payment']);
    final dispatch = _toMap(_pipeline['dispatch']);

    _selectedMaterialId = _extractId(source['materialId']);

    final materialAmount = source['materialAmount'];
    if (materialAmount != null) {
      _materialAmountCtrl.text = materialAmount.toString();
    }

    _selectedAssignedToId = _extractId(followUp['assignedTo']);

    final followUpAtRaw = followUp['followUpAt']?.toString() ?? '';
    final followUpAt = DateTime.tryParse(followUpAtRaw)?.toLocal();
    if (followUpAt != null) {
      _followUpDate = DateTime(
        followUpAt.year,
        followUpAt.month,
        followUpAt.day,
      );
      _followUpTime = TimeOfDay(
        hour: followUpAt.hour,
        minute: followUpAt.minute,
      );
    }

    final finalAmount = dealDone['finalAmount'];
    if (finalAmount != null) {
      _finalAmountCtrl.text = finalAmount.toString();
    }

    _paymentComplete = payment['paymentComplete'] is bool
        ? payment['paymentComplete'] as bool
        : null;

    final dispatchRaw = dispatch['dispatchDate']?.toString() ?? '';
    _dispatchDate = DateTime.tryParse(dispatchRaw)?.toLocal();

    _activeStep = _nextPendingStep;
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String? _extractId(dynamic value) {
    if (value is Map) {
      final id = value['_id']?.toString() ?? value['id']?.toString() ?? '';
      return id.trim().isEmpty ? null : id;
    }
    final id = value?.toString().trim() ?? '';
    return id.isEmpty ? null : id;
  }

  String _dateText(DateTime? value) {
    if (value == null) return 'Select date';
    return DateFormat('dd MMM yyyy').format(value);
  }

  String _timeText(TimeOfDay? value) {
    if (value == null) return 'Select time';
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _saveStep({
    required String step,
    required Map<String, dynamic> payload,
    required String successMessage,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = await _apiService.updateMaterialCustomerPipeline(
        widget.customerId,
        step: step,
        payload: payload,
      );

      if (!mounted) return;
      setState(() {
        _customer = updated;
        _hydrateFormFromCustomer();
      });
      AppFeedback.showSuccess(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to update step: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitSource() async {
    if (!(_sourceFormKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_materialAmountCtrl.text.trim());
    if (amount == null) {
      if (mounted) AppFeedback.showError(context, 'Invalid material amount');
      return;
    }
    await _saveStep(
      step: 'source',
      payload: {
        'materialId': _selectedMaterialId,
        'materialAmount': amount,
      },
      successMessage: 'Source step updated',
    );
  }

  Future<void> _submitFollowUp() async {
    if (!(_followUpFormKey.currentState?.validate() ?? false)) return;
    if (_followUpDate == null || _followUpTime == null) {
      AppFeedback.showError(context, 'Follow-up date and time are required');
      return;
    }

    final dateTime = DateTime(
      _followUpDate!.year,
      _followUpDate!.month,
      _followUpDate!.day,
      _followUpTime!.hour,
      _followUpTime!.minute,
    );

    await _saveStep(
      step: 'followUp',
      payload: {
        'assignedTo': _selectedAssignedToId,
        'followUpAt': dateTime.toIso8601String(),
      },
      successMessage: 'Follow-up step updated',
    );
  }

  Future<void> _submitDealDone() async {
    if (!(_dealFormKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_finalAmountCtrl.text.trim());
    if (amount == null) {
      if (mounted) AppFeedback.showError(context, 'Invalid final amount');
      return;
    }
    await _saveStep(
      step: 'dealDone',
      payload: {'finalAmount': amount},
      successMessage: 'Deal Done step updated',
    );
  }

  Future<void> _submitPayment() async {
    if (!(_paymentFormKey.currentState?.validate() ?? false)) return;
    await _saveStep(
      step: 'payment',
      payload: {'paymentComplete': _paymentComplete},
      successMessage: 'Payment step updated',
    );
  }

  Future<void> _submitDispatch() async {
    if (!(_dispatchFormKey.currentState?.validate() ?? false)) return;
    if (_dispatchDate == null) {
      AppFeedback.showError(context, 'Dispatch date is required');
      return;
    }

    await _saveStep(
      step: 'dispatch',
      payload: {'dispatchDate': _dispatchDate!.toIso8601String()},
      successMessage: 'Dispatch updated. Customer auto completed.',
    );
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDate: _followUpDate ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _followUpDate = picked);
    }
  }

  Future<void> _pickFollowUpTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _followUpTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _followUpTime = picked);
    }
  }

  Future<void> _pickDispatchDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDate: _dispatchDate ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _dispatchDate = picked);
    }
  }

  bool _enabledFor(int index) {
    if (index == 5) return _projectCompletedAuto;
    return index <= _nextPendingStep || _isCompleted;
  }

  bool _doneFor(int index) {
    if (index == 5) return _projectCompletedAuto;
    return _isCompleted || index <= _currentStep;
  }

  String _stepName(int index) {
    switch (index) {
      case 0:
        return 'Source';
      case 1:
        return 'Follow Up';
      case 2:
        return 'Deal Done';
      case 3:
        return 'Payment Completed';
      case 4:
        return 'Dispatch';
      case 5:
        return 'Project Completed';
      default:
        return 'Step ${index + 1}';
    }
  }

  Color _dotColor(int index) {
    if (_doneFor(index)) return   AppColors.greenSuccess;
    if (_activeStep == index) return LeadTheme.primary;
    return   AppColors.slate300;
  }

  String _materialNameById(String? id) {
    if (id == null || id.isEmpty) return '-';
    for (final m in _materials) {
      if ((m['_id'] ?? '').toString() == id) {
        return (m['materialName'] ?? '-').toString();
      }
    }
    return '-';
  }

  String _salesNameById(String? id) {
    if (id == null || id.isEmpty) return '-';
    for (final s in _salesPeople) {
      if ((s['_id'] ?? '').toString() == id) {
        return (s['name'] ?? '-').toString();
      }
    }
    return '-';
  }

  List<MapEntry<String, String>> _stepSummary(int index) {
    final source = _toMap(_pipeline['source']);
    final followUp = _toMap(_pipeline['followUp']);
    final dealDone = _toMap(_pipeline['dealDone']);
    final payment = _toMap(_pipeline['payment']);
    final dispatch = _toMap(_pipeline['dispatch']);

    switch (index) {
      case 0:
        final amount = source['materialAmount'];
        return [
          MapEntry(
            'Material',
            _materialNameById(_extractId(source['materialId'])),
          ),
          if (amount != null) MapEntry('Amount', '₹ ${amount.toString()}'),
        ];
      case 1:
        final followRaw = followUp['followUpAt']?.toString() ?? '';
        final followDate = DateTime.tryParse(followRaw)?.toLocal();
        return [
          MapEntry(
            'Assigned To',
            _salesNameById(_extractId(followUp['assignedTo'])),
          ),
          if (followDate != null)
            MapEntry(
              'Follow-up',
              DateFormat('dd MMM yyyy, hh:mm a').format(followDate),
            ),
        ];
      case 2:
        final amount = dealDone['finalAmount'];
        return [
          if (amount != null)
            MapEntry('Final Amount', '₹ ${amount.toString()}'),
        ];
      case 3:
        final paid = payment['paymentComplete'];
        return [
          if (paid != null)
            MapEntry('Payment Completed', paid == true ? 'Yes' : 'No'),
        ];
      case 4:
        final dateRaw = dispatch['dispatchDate']?.toString() ?? '';
        final d = DateTime.tryParse(dateRaw)?.toLocal();
        return [
          if (d != null)
            MapEntry('Dispatch Date', DateFormat('dd MMM yyyy').format(d)),
        ];
      case 5:
        final dateRaw = dispatch['dispatchDate']?.toString() ?? '';
        final d = DateTime.tryParse(dateRaw)?.toLocal();
        return [
          MapEntry(
            'Project Completed',
            _projectCompletedAuto ? 'Yes' : 'Pending',
          ),
          if (d != null)
            MapEntry('Completed On', DateFormat('dd MMM yyyy').format(d)),
        ];
      default:
        return const [];
    }
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedStepHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:   AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color:   AppColors.slate200),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.slate500),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Is step ko unlock karne ke liye previous step complete karein.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.slate600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required int index, required Widget content}) {
    final enabled = _enabledFor(index);
    final done = _doneFor(index);
    final isActive = _activeStep == index;
    final summary = _stepSummary(index);
    final showSummary = done && !isActive && summary.isNotEmpty;

    final titleColor = done
        ?   AppColors.green800
        : isActive
        ? LeadTheme.primary
        :   AppColors.slate300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dotColor(index),
                    boxShadow: (done || isActive)
                        ? [
                            BoxShadow(
                              color: _dotColor(index).withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  :   AppColors.slate700,
                            ),
                          ),
                  ),
                ),
                if (index != 5)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: done
                            ?  AppColors.greenLight1
                            :   AppColors.slate200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${index + 1}. ${_stepName(index)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : done
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (enabled || done)
                        GestureDetector(
                          onTap: () => setState(() => _activeStep = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: LeadTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: LeadTheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Text(
                              isActive ? 'Editing' : 'Open',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: LeadTheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showSummary) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:   AppColors.slate50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color:   AppColors.slate200),
                      ),
                      child: Column(
                        children: summary
                            .map((e) => _summaryRow(e.key, e.value))
                            .toList(),
                      ),
                    ),
                  ],
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color:   AppColors.slate200),
                      ),
                      child: content,
                    ),
                  ] else if (!(enabled || done)) ...[
                    const SizedBox(height: 8),
                    _buildLockedStepHint(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.appBarColor ?? LeadTheme.primary;
    final customerName = (_customer?['customerName'] ?? 'Customer').toString();
    final mobile = (_customer?['mobile'] ?? '-').toString();
    final status = (_pipeline['status'] ?? 'New').toString();
    const totalSteps = 6;
    final doneCount = List<int>.generate(
      totalSteps,
      (i) => i,
    ).where(_doneFor).length;
    final progress = doneCount / totalSteps;

    return Scaffold(
      backgroundColor:   AppColors.slate50,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Material Pipeline'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.96),
                          color.withValues(alpha: 0.82),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Material Customer',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    customerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mobile,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$doneCount / $totalSteps steps completed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Progress Timeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      children: [
                        _buildStepCard(
                          index: 0,
                          content: Form(
                            key: _sourceFormKey,
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedMaterialId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Material *',
                                  ),
                                  items: _materials.map((m) {
                                    final id = (m['_id'] ?? '').toString();
                                    final name = (m['materialName'] ?? '-')
                                        .toString();
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text(name),
                                    );
                                  }).toList(),
                                  onChanged: _enabledFor(0)
                                      ? (v) => setState(
                                          () => _selectedMaterialId = v,
                                        )
                                      : null,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Select material'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _materialAmountCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  enabled: _enabledFor(0),
                                  decoration: const InputDecoration(
                                    labelText: 'Material Amount *',
                                    prefixText: '₹ ',
                                  ),
                                  validator: (v) {
                                    final val = double.tryParse(
                                      (v ?? '').trim(),
                                    );
                                    if (val == null || val < 0) {
                                      return 'Enter valid amount';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _saveButton(_enabledFor(0), _submitSource),
                              ],
                            ),
                          ),
                        ),
                        _buildStepCard(
                          index: 1,
                          content: Form(
                            key: _followUpFormKey,
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedAssignedToId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Assign To (Sales) *',
                                  ),
                                  items: _salesPeople.map((s) {
                                    final id = (s['_id'] ?? '').toString();
                                    final name = (s['name'] ?? '-').toString();
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text(name),
                                    );
                                  }).toList(),
                                  onChanged: _enabledFor(1)
                                      ? (v) => setState(
                                          () => _selectedAssignedToId = v,
                                        )
                                      : null,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Select sales person'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _enabledFor(1)
                                            ? _pickFollowUpDate
                                            : null,
                                        child: Text(_dateText(_followUpDate)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _enabledFor(1)
                                            ? _pickFollowUpTime
                                            : null,
                                        child: Text(_timeText(_followUpTime)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _saveButton(_enabledFor(1), _submitFollowUp),
                              ],
                            ),
                          ),
                        ),
                        _buildStepCard(
                          index: 2,
                          content: Form(
                            key: _dealFormKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _finalAmountCtrl,
                                  enabled: _enabledFor(2),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Final Amount *',
                                    prefixText: '₹ ',
                                  ),
                                  validator: (v) {
                                    final val = double.tryParse(
                                      (v ?? '').trim(),
                                    );
                                    if (val == null || val < 0) {
                                      return 'Enter valid final amount';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _saveButton(_enabledFor(2), _submitDealDone),
                              ],
                            ),
                          ),
                        ),
                        _buildStepCard(
                          index: 3,
                          content: Form(
                            key: _paymentFormKey,
                            child: Column(
                              children: [
                                DropdownButtonFormField<bool>(
                                  initialValue: _paymentComplete,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Complete *',
                                  ),
                                  items: const [
                                    DropdownMenuItem<bool>(
                                      value: true,
                                      child: Text('Yes'),
                                    ),
                                    DropdownMenuItem<bool>(
                                      value: false,
                                      child: Text('No'),
                                    ),
                                  ],
                                  onChanged: _enabledFor(3)
                                      ? (v) =>
                                            setState(() => _paymentComplete = v)
                                      : null,
                                  validator: (v) => v == null
                                      ? 'Select payment status'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                _saveButton(_enabledFor(3), _submitPayment),
                              ],
                            ),
                          ),
                        ),
                        _buildStepCard(
                          index: 4,
                          content: Form(
                            key: _dispatchFormKey,
                            child: Column(
                              children: [
                                OutlinedButton(
                                  onPressed: _enabledFor(4)
                                      ? _pickDispatchDate
                                      : null,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(_dateText(_dispatchDate)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _saveButton(_enabledFor(4), _submitDispatch),
                              ],
                            ),
                          ),
                        ),
                        _buildStepCard(
                          index: 5,
                          content: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:   AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:   AppColors.slate200,
                              ),
                            ),
                            child: Text(
                              _projectCompletedAuto
                                  ? 'Project completed.'
                                  : 'Project completion pending.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _saveButton(bool enabled, Future<void> Function() onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:   AppColors.indigo600,
          foregroundColor: Colors.white,
          disabledBackgroundColor:   AppColors.slate200,
          disabledForegroundColor:   AppColors.slate300,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: (!enabled || _saving) ? null : onPressed,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Save Step'),
      ),
    );
  }
}







