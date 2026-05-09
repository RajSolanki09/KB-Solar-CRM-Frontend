import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/core/app_colors.dart';

class _InstallMember {
  final String id;
  final String name;
  final String phone;

  const _InstallMember({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory _InstallMember.fromJson(Map<String, dynamic> j) => _InstallMember(
    id: j['_id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
  );
}

class SpkInstallationAssignedScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  final bool isEditing;

  const SpkInstallationAssignedScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });

  @override
  State<SpkInstallationAssignedScreen> createState() =>
      _SpkInstallationAssignedScreenState();
}

class _SpkInstallationAssignedScreenState
    extends State<SpkInstallationAssignedScreen> {
  final _notesC = TextEditingController();

  List<_InstallMember> _teamMembers = [];
  final Set<String> _selectedIds = {};
  List<_InstallMember> get _selectedMembers =>
      _teamMembers.where((m) => _selectedIds.contains(m.id)).toList();
  bool _teamLoading = false;
  String _teamError = '';
  bool _saving = false;

  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  @override
  void initState() {
    super.initState();
    _notesC.text = widget.lead.installationAssignData.notes ?? '';
    _scheduledDate = widget.lead.installationAssignData.scheduledDate;
    _selectedIds.addAll(widget.lead.effectiveInstallerIds);
    _fetchInstallTeam();
  }

  @override
  void dispose() {
    _notesC.dispose();
    super.dispose();
  }

  Future<void> _fetchInstallTeam() async {
    setState(() {
      _teamLoading = true;
      _teamError = '';
    });

    final candidates = <Future<dynamic> Function()>[
      () => DioClient().dio.get<dynamic>(
        ApiEndpoints.adminStaff,
        queryParameters: {'role': 'installation', 'limit': 100},
      ),
      () => DioClient().dio.get<dynamic>(
        ApiEndpoints.adminUsers,
        queryParameters: {'role': 'installation', 'limit': 100},
      ),
    ];

    for (final attempt in candidates) {
      try {
        final res = await attempt();
        final body = res.data;
        List<dynamic> raw = [];
        if (body is List) {
          raw = body;
        } else if (body is Map) {
          for (final key in [
            'staff',
            'data',
            'users',
            'members',
            'results',
            'list',
          ]) {
            if (body[key] is List) {
              raw = body[key] as List;
              break;
            }
          }
        }

        final list = raw
            .whereType<Map<String, dynamic>>()
            .map(_InstallMember.fromJson)
            .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
            .toList();

        if (mounted) {
          setState(() {
            _teamMembers = list;
            _selectedIds.removeWhere((id) => !list.any((m) => m.id == id));
            _teamLoading = false;
          });
        }
        return;
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        if (code != 404) break;
      } catch (_) {
        break;
      }
    }

    if (mounted) {
      setState(() {
        _teamLoading = false;
        _teamError = 'Could not load installation team members.';
      });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate:
          _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: LeadTheme.secondary),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) {
      setState(() => _scheduledDate = d);
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: LeadTheme.secondary),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) {
      setState(() => _scheduledTime = t);
    }
  }

  void _save() {
    if (_selectedIds.isEmpty) {
      AppFeedback.showError(
        context,
        'Please select at least one installation team member.',
      );
      return;
    }

    DateTime? finalDateTime = _scheduledDate;
    if (finalDateTime != null && _scheduledTime != null) {
      finalDateTime = DateTime(
        finalDateTime.year,
        finalDateTime.month,
        finalDateTime.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
    }

    setState(() => _saving = true);

    final notes = _notesC.text.trim().isEmpty ? null : _notesC.text.trim();

    final installerIds = _selectedMembers.map((m) => m.id).toList();

    context.read<SprinklerLeadCubit>().assignInstaller(
      widget.lead.id,
      installerIds: installerIds,
      scheduledDate: finalDateTime,
      notes: notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        if (state is SprinklerLeadSaved) Navigator.pop(context);
        if (state is SprinklerLeadError) {
          setState(() => _saving = false);
          AppFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor:   AppColors.background,
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
          title: Text(
            widget.isEditing ? 'Edit Assignment' : 'Assign Installation Team',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LeadTheme.bg,
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
            _customerBanner(widget.lead),
            const SizedBox(height: 10),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: SectionTitle('Assign To Person')),
                      if (_teamLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LeadTheme.secondary,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _fetchInstallTeam,
                          child: const AppSvgIcon(
                            AppSvgAssets.refreshCw,
                            size: 16,
                            color: LeadTheme.secondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTeamDropdown(),
                ],
              ),
            ),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Installation Schedule'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: _dateTile(
                      AppSvgAssets.calendarDays,
                      'Installation Date',
                      _scheduledDate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickTime,
                    child: _timeTile(_scheduledTime),
                  ),
                ],
              ),
            ),
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesC,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LeadTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Assignment notes...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                      filled: true,
                      fillColor: LeadTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _saveButton(
              _saving,
              _save,
              widget.isEditing
                  ? 'Update Assignment'
                  : 'Confirm Installation Assigned',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamDropdown() {
    if (_teamLoading) {
      return _hintTile('Loading team members...');
    }

    if (_teamMembers.isEmpty) {
      return _warningTile(
        _teamError.isNotEmpty
            ? _teamError
            : 'No installation staff found. Tap refresh.',
      );
    }

    final hasSelection = _selectedIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSelection) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedMembers.map((m) {
              return Chip(
                avatar: const AppSvgIcon(
                  AppSvgAssets.cog,
                  size: 14,
                  color: LeadTheme.secondary,
                ),
                label: Text(
                  m.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _selectedIds.remove(m.id)),
                backgroundColor: LeadTheme.secondary.withValues(alpha: 0.1),
                side: BorderSide(
                  color: LeadTheme.secondary.withValues(alpha: 0.35),
                ),
                labelStyle: const TextStyle(color: AppColors.textDark),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: LeadTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSelection
                  ? LeadTheme.secondary.withValues(alpha: 0.5)
                  : Colors.grey.shade300,
              width: hasSelection ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: null,
              isExpanded: true,
              icon: const AppSvgIcon(
                AppSvgAssets.chevronDown,
                size: 20,
                color: LeadTheme.secondary,
              ),
              hint: Row(
                children: [
                  AppSvgIcon(
                    AppSvgAssets.userPlus,
                    size: 16,
                    color: AppColors.background,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasSelection
                        ? 'Add another member...'
                        : 'Select team member(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: LeadTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              items: _teamMembers
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Row(
                        children: [
                          const AppSvgIcon(
                            AppSvgAssets.cog,
                            size: 16,
                            color: LeadTheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedIds.contains(m.id)
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: LeadTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (m.phone.isNotEmpty)
                            Text(
                              m.phone,
                              style: const TextStyle(
                                fontSize: 11,
                                color: LeadTheme.textSecondary,
                              ),
                            ),
                          if (_selectedIds.contains(m.id))
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: AppSvgIcon(
                                AppSvgAssets.circleCheckBig,
                                size: 14,
                                color: LeadTheme.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  if (_selectedIds.contains(id)) {
                    _selectedIds.remove(id);
                  } else {
                    _selectedIds.add(id);
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _customerBanner(SprinklerLeadModel lead) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LeadTheme.secondary.withOpacity(0.06),
        border: Border.all(color: LeadTheme.secondary.withOpacity(0.2)),
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

  Widget _dateTile(String svgAsset, String label, DateTime? date) {
    final selected = date != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? LeadTheme.secondary.withOpacity(0.08)
            : LeadTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? LeadTheme.secondary.withOpacity(0.35)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            svgAsset,
            size: 16,
            color: selected ? LeadTheme.secondary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LeadTheme.textSecondary,
                  ),
                ),
                Text(
                  selected
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Tap to select date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? LeadTheme.secondary
                        : LeadTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppSvgIcon(
            selected ? AppSvgAssets.circleCheckBig : AppSvgAssets.chevronRight,
            size: 14,
            color: selected ? LeadTheme.secondary : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _timeTile(TimeOfDay? time) {
    final selected = time != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? LeadTheme.secondary.withOpacity(0.08)
            : LeadTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? LeadTheme.secondary.withOpacity(0.35)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            AppSvgAssets.clock,
            size: 16,
            color: selected ? LeadTheme.secondary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installation Time',
                  style: TextStyle(
                    fontSize: 11,
                    color: LeadTheme.textSecondary,
                  ),
                ),
                Text(
                  selected ? time.format(context) : 'Tap to select time',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? LeadTheme.secondary
                        : LeadTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppSvgIcon(
            selected ? AppSvgAssets.circleCheckBig : AppSvgAssets.chevronRight,
            size: 14,
            color: selected ? LeadTheme.secondary : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _hintTile(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppSvgIcon(AppSvgAssets.circle, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningTile(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.solar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.solar),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            AppSvgAssets.triangleAlert,
            size: 14,
            color: AppColors.solar,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: AppColors.solar),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton(bool saving, VoidCallback onTap, String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: saving ? null : onTap,
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
}
