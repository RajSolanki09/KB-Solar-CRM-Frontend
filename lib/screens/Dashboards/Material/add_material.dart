import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_colors.dart';

class AddMaterialScreen extends StatefulWidget {
  final Color? appBarColor;
  final Map<String, dynamic>? initialMaterial;
  const AddMaterialScreen({
    super.key,
    this.appBarColor,
    this.initialMaterial,
  });

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool get _isEditMode => widget.initialMaterial != null;

  bool _loadingSchema = true;
  bool _saving = false;

  List<Map<String, dynamic>> _sections = const [];
  Map<String, List<String>> _options = const {};

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};

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
      final schema = await _apiService.getMaterialFormSchema();
      final sectionsRaw = (schema['sections'] as List?) ?? const [];
      final gstOptions = ((schema['gstOptions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();

      _sections = sectionsRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _options = {
        'gstOptions': gstOptions,
      };

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
        'key': 'material_basic',
        'title': 'Material Details',
        'fields': [
          {
            'key': 'materialName',
            'label': 'Material Name',
            'type': 'text',
            'required': true,
          },
          {
            'key': 'brand',
            'label': 'Brand',
            'type': 'text',
            'required': false,
          },
        ],
      },
      {
        'key': 'pricing',
        'title': 'Pricing',
        'fields': [
          {
            'key': 'purchasePrice',
            'label': 'Purchase Price',
            'type': 'number',
            'required': true,
          },
          {
            'key': 'sellingPrice',
            'label': 'Selling Price',
            'type': 'number',
            'required': true,
          },
          {
            'key': 'gstRate',
            'label': 'GST %',
            'type': 'dropdown',
            'required': false,
            'optionsFrom': 'gstOptions',
          },
        ],
      },
      {
        'key': 'note',
        'title': 'Note',
        'fields': [
          {
            'key': 'note',
            'label': 'Internal Note',
            'type': 'multiline',
            'required': false,
            'maxLines': 4,
          },
        ],
      },
    ];

    _options = {
      'gstOptions': const ['0%', '5%', '12%', '18%', '28%'],
    };

    _prepareFieldState();
  }

  void _prepareFieldState() {
    for (final section in _sections) {
      final fields = (section['fields'] as List?) ?? const [];
      for (final field in fields.whereType<Map>()) {
        final f = Map<String, dynamic>.from(field);
        final key = (f['key'] ?? '').toString();
        final type = (f['type'] ?? 'text').toString();
        if (key.isEmpty) continue;

        if (type == 'dropdown') {
          _dropdownValues.putIfAbsent(key, () => null);
        } else {
          _controllers.putIfAbsent(key, TextEditingController.new);
        }
      }
    }

    _applyInitialValues();
  }

  void _applyInitialValues() {
    final source = widget.initialMaterial;
    if (source == null) return;

    final normalized = <String, dynamic>{
      ...source,
      ..._extractCustomFields(source),
    };

    for (final entry in _controllers.entries) {
      final value = normalized[entry.key];
      entry.value.text = value == null ? '' : value.toString();
    }

    for (final key in _dropdownValues.keys) {
      final raw = normalized[key];
      final value = raw?.toString().trim();
      _dropdownValues[key] = (value == null || value.isEmpty) ? null : value;
    }
  }

  Map<String, dynamic> _extractCustomFields(Map<String, dynamic> source) {
    final raw = source['customFields'];
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    return const <String, dynamic>{};
  }

  String? _materialId(Map<String, dynamic>? source) {
    if (source == null) return null;
    final dynamic id = source['_id'] ?? source['id'] ?? source['materialId'];
    final value = id?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Future<void> _saveMaterial() async {
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

      for (final entry in _dropdownValues.entries) {
        final value = entry.value?.trim();
        if (value == null || value.isEmpty) continue;
        if (_isCoreField(entry.key)) {
          payload[entry.key] = value;
        } else {
          custom[entry.key] = value;
        }
      }

      if (payload['purchasePrice'] != null) {
        payload['purchasePrice'] =
            double.tryParse(payload['purchasePrice'].toString()) ?? 0;
      }
      if (payload['sellingPrice'] != null) {
        payload['sellingPrice'] =
            double.tryParse(payload['sellingPrice'].toString()) ?? 0;
      }

      payload['customFields'] = custom;

      if (_isEditMode) {
        final id = _materialId(widget.initialMaterial);
        if (id == null) {
          throw Exception('Material id not found for update');
        }
        await _apiService.updateMaterial(id, payload);
      } else {
        await _apiService.createMaterial(payload);
      }

      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        _isEditMode
            ? 'Material updated successfully'
            : 'Material saved successfully',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Failed to save material: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isCoreField(String key) {
    return {
      'materialName',
      'brand',
      'purchasePrice',
      'sellingPrice',
      'gstRate',
      'note',
    }.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.appBarColor ?? AppColors.primary);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(_isEditMode ? 'Edit Material' : 'Add Material'),
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
            onPressed: _saving ? null : _saveMaterial,
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
                  _isEditMode ? 'Update Material' : 'Save Material',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
    final type = (field['type'] ?? 'text').toString();
    final required = field['required'] == true;

    if (type == 'dropdown') {
      final optionsFrom = (field['optionsFrom'] ?? '').toString();
      final options = _options[optionsFrom] ?? const [];
      final selectedValue = _dropdownValues[key];
      return DropdownButtonFormField<String>(
        value: options.contains(selectedValue) ? selectedValue : null,
        isExpanded: true,
        decoration: _inputDecoration(label, required),
        items: options
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) => setState(() => _dropdownValues[key] = v),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return '$label is required';
          }
          return null;
        },
      );
    }

    final keyboardType = type == 'number'
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text;

    final formatters = type == 'number'
        ? <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ]
        : null;

    final maxLines = type == 'multiline'
        ? ((field['maxLines'] as num?)?.toInt() ?? 4)
        : 1;

    return TextFormField(
      controller: _controllers[key],
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      decoration: _inputDecoration(label, required),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return '$label is required';
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





