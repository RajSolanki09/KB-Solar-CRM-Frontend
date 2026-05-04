import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_colors.dart';

class AddMaterialCustomerScreen extends StatefulWidget {
  final Color? appBarColor;
  final Map<String, dynamic>? initialCustomer;
  const AddMaterialCustomerScreen({
    super.key,
    this.appBarColor,
    this.initialCustomer,
  });

  @override
  State<AddMaterialCustomerScreen> createState() =>
      _AddMaterialCustomerScreenState();
}

class _AddMaterialCustomerScreenState extends State<AddMaterialCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool get _isEditMode => widget.initialCustomer != null;

  bool _loadingSchema = true;
  bool _saving = false;

  List<Map<String, dynamic>> _sections = const [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadSchema();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSchema() async {
    setState(() => _loadingSchema = true);
    try {
      final schema = await _apiService.getMaterialCustomerFormSchema();
      final sectionsRaw = (schema['sections'] as List?) ?? const [];

      _sections = sectionsRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _prepareFieldState();
    } catch (_) {
      _useFallbackSchema();
    } finally {
      if (!mounted) return;
      setState(() => _loadingSchema = false);
    }
  }

  void _useFallbackSchema() {
    _sections = const [
      {
        'key': 'customer_basic',
        'title': 'Customer Details',
        'fields': [
          {
            'key': 'customerName',
            'label': 'Customer Name',
            'type': 'text',
            'required': true,
          },
          {
            'key': 'mobile',
            'label': 'Mobile Number',
            'type': 'text',
            'required': true,
          },
          {
            'key': 'address',
            'label': 'Address',
            'type': 'multiline',
            'required': true,
            'maxLines': 3,
          },
        ],
      },
    ];

    _prepareFieldState();
  }

  void _prepareFieldState() {
    _controllers.clear();
    for (final section in _sections) {
      final fields = (section['fields'] as List?) ?? const [];
      for (final field in fields.whereType<Map>()) {
        final key = (field['key'] ?? '').toString();
        if (key.isEmpty) continue;
        _controllers.putIfAbsent(key, TextEditingController.new);
      }
    }

    _applyInitialValues();
  }

  void _applyInitialValues() {
    final source = widget.initialCustomer;
    if (source == null) return;

    final normalized = <String, dynamic>{
      ...source,
      ..._extractCustomFields(source),
    };

    for (final entry in _controllers.entries) {
      final value = normalized[entry.key];
      entry.value.text = value == null ? '' : value.toString();
    }
  }

  Map<String, dynamic> _extractCustomFields(Map<String, dynamic> source) {
    final raw = source['customFields'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return const <String, dynamic>{};
  }

  String? _customerId(Map<String, dynamic>? source) {
    if (source == null) return null;
    final dynamic id = source['_id'] ?? source['id'] ?? source['customerId'];
    final value = id?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Future<void> _saveCustomer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{};
      final custom = <String, dynamic>{};

      for (final entry in _controllers.entries) {
        final value = entry.value.text.trim();
        if (value.isEmpty) continue;
        if (_isCoreField(entry.key)) {
          payload[entry.key] = value;
        } else {
          custom[entry.key] = value;
        }
      }

      payload['customFields'] = custom;
      if (_isEditMode) {
        final id = _customerId(widget.initialCustomer);
        if (id == null) {
          throw Exception('Customer id not found for update');
        }
        await _apiService.updateMaterialCustomer(id, payload);
      } else {
        await _apiService.createMaterialCustomer(payload);
      }

      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        _isEditMode
            ? 'Customer updated successfully'
            : 'Customer added successfully',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to save customer: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isCoreField(String key) {
    return {'customerName', 'mobile', 'address'}.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.appBarColor ?? AppColors.primary);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(_isEditMode ? 'Edit Customer' : 'Add Customer'),
      ),
      body: _loadingSchema
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                children: _sections.map(_buildSection).toList(),
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.bgPrimary))),
          ),
          child: ElevatedButton(
            onPressed: _saving ? null : _saveCustomer,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                    _isEditMode ? 'Update Customer' : 'Save Customer',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final title = (section['title'] ?? 'Section').toString();
    final fields = (section['fields'] as List?) ?? const [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgPrimary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          ...fields.whereType<Map>().map((f) {
            final field = Map<String, dynamic>.from(f);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildField(field),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    final key = (field['key'] ?? '').toString();
    final label = (field['label'] ?? key).toString();
    final required = field['required'] == true;
    final type = (field['type'] ?? 'text').toString();
    final isAddress = key.toLowerCase().contains('address') || type == 'multiline';

    return TextFormField(
      controller: _controllers[key],
      keyboardType: key == 'mobile' ? TextInputType.phone : TextInputType.text,
      inputFormatters: key == 'mobile'
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      maxLines: isAddress ? ((field['maxLines'] as num?)?.toInt() ?? 3) : 1,
      decoration: _inputDecoration(label, required),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (required && value.isEmpty) {
          return '$label is required';
        }
        if (key == 'mobile' && value.isNotEmpty) {
          final isValid = RegExp(r'^[6-9][0-9]{9}$').hasMatch(value);
          if (!isValid) return 'Enter valid 10-digit Indian mobile number';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, bool required) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      filled: true,
      fillColor: AppColors.bgSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.bgPrimary)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.bgPrimary)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary), width: 1.3),
      ),
    );
  }
}





