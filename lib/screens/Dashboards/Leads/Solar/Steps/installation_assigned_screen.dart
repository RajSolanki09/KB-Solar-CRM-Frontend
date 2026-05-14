// lib/screens/Solar/Steps/installation_assign_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_form_widgets.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/lead_widgets.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';

class _InstallMember {
  final String id, name, phone;
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

// ─────────────────────────────────────────────────────────────────────────────
class SolarInstallationAssignScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  final bool isEditing;
  const SolarInstallationAssignScreen({
    super.key,
    required this.lead,
    this.isEditing = false,
  });
  @override
  State<SolarInstallationAssignScreen> createState() => _State();
}

class _State extends State<SolarInstallationAssignScreen> {
  final _manualNameC = TextEditingController();
  final _manualPhoneC = TextEditingController();
  final _notesC = TextEditingController();

  bool _useManualEntry = false;
  List<_InstallMember> _teamMembers = [];

  /// Multi-select: set of selected members
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
    // Pre-fill notes and scheduled date
    _notesC.text = widget.lead.installationData.notes ?? '';
    _scheduledDate = widget.lead.expectedInstallDate;
    // Pre-select already-assigned members
    _selectedIds.addAll(widget.lead.installationTeamMemberIds);
    _fetchInstallTeam();
  }

  @override
  void dispose() {
    _manualNameC.dispose();
    _manualPhoneC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  Future<void> _fetchInstallTeam() async {
    setState(() {
      _teamLoading = true;
      _teamError = '';
      _useManualEntry = false;
    });

    final candidates = <Future<Response<dynamic>> Function()>[
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
          for (final key in ['staff', 'data', 'users', 'members', 'results', 'list']) {
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

        if (mounted) setState(() { _teamMembers = list; _teamLoading = false; });
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
        _teamError = 'Could not load staff from server.';
        _useManualEntry = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.primary),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _scheduledDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: LeadTheme.primary),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => _scheduledTime = t);
  }

  void _save() {
    List<String> memberIds = [];
    List<String> memberNames = [];

    if (_useManualEntry && _manualNameC.text.trim().isNotEmpty) {
      memberNames = [_manualNameC.text.trim()];
    } else {
      memberIds = _selectedMembers.map((m) => m.id).toList();
      memberNames = _selectedMembers.map((m) => m.name).toList();
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
    final cubit = context.read<SolarLeadCubit>();
    final id = widget.lead.id;
    final notes = _notesC.text.trim().isEmpty ? null : _notesC.text.trim();

    if (widget.isEditing) {
      cubit.editInstallationAssign(
        id,
        installationTeamMemberIds: memberIds.isNotEmpty ? memberIds : null,
        installationTeamNames: memberNames.isNotEmpty ? memberNames : null,
        scheduledDate: finalDateTime,
        notes: notes,
      );
    } else {
      cubit.saveInstallationAssign(
        id,
        installationTeamMemberIds: memberIds.isNotEmpty ? memberIds : null,
        installationTeamNames: memberNames.isNotEmpty ? memberNames : null,
        scheduledDate: finalDateTime,
        notes: notes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            widget.isEditing ? 'Edit Assignment' : 'Assign Installation Team',
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

            // ── Deal summary reminder ──────────────────────────────────
            if (widget.lead.finalAmount != null)
              _dealSummaryCard(widget.lead),

            // ── Assign Team ───────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: SectionTitle('Assign Team Member')),
                      if (_teamLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LeadTheme.primary,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _fetchInstallTeam,
                          child: AppSvgIcon(
                            AppSvgAssets.refreshCw,
                            size: 16,
                            color: LeadTheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTeamDropdown(),
                ],
              ),
            ),

            // ── Schedule ──────────────────────────────────────────────
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

            // ── Notes ─────────────────────────────────────────────────
            CompactCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Notes'),
                  const SizedBox(height: 8),
                  _field(
                    _notesC,
                    'Assignment notes...',
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
      return _loadingTile('Loading team members...');
    }

    if (_useManualEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _warningTile(
            'Staff list unavailable — enter name manually.',
            onRefresh: _fetchInstallTeam,
          ),
          const SizedBox(height: 8),
          _field(_manualNameC, 'Technician Name', AppSvgAssets.userRound),
          const SizedBox(height: 8),
          _field(_manualPhoneC, 'Technician Phone', AppSvgAssets.phone),
        ],
      );
    }

    if (_teamMembers.isEmpty) {
      return _warningTile(
        _teamError.isNotEmpty
            ? _teamError
            : 'No installation staff found. Tap refresh.',
        onRefresh: _fetchInstallTeam,
        color: Colors.orange,
      );
    }

    final hasSelection = _selectedIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Selected chips row ──────────────────────────────────────────
        if (hasSelection) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedMembers.map((m) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: LeadTheme.primary,
                  child: Text(
                    m.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
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
                backgroundColor: LeadTheme.primary.withValues(alpha: 0.1),
                side: BorderSide(
                  color: LeadTheme.primary.withValues(alpha: 0.4),
                ),
                labelStyle: const TextStyle(color: AppColors.textDark),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // ── Dropdown to add more members ────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: LeadTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSelection
                  ? LeadTheme.primary.withValues(alpha: 0.5)
                  : Colors.grey.shade300,
              width: hasSelection ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: null, // always null so hint shows
              isExpanded: true,
              icon: AppSvgIcon(
                AppSvgAssets.chevronDown,
                size: 20,
                color: LeadTheme.primary,
              ),
              hint: Row(
                children: [
                  AppSvgIcon(
                    AppSvgAssets.userPlus,
                    size: 16,
                    color: LeadTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasSelection
                        ? 'Add another member...'
                        : 'Select team member(s)',
                    style: TextStyle(
                      fontSize: 13,
                      color: LeadTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              items: _teamMembers.map((m) {
                final isSelected = _selectedIds.contains(m.id);
                return DropdownMenuItem<String>(
                  value: m.id,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected
                            ? LeadTheme.primary
                            : LeadTheme.primary.withValues(alpha: 0.12),
                        radius: 14,
                        child: Text(
                          m.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : LeadTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color:   AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (m.phone.isNotEmpty)
                              Text(
                                m.phone,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGray,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const AppSvgIcon(
                          AppSvgAssets.circleCheckBig,
                          size: 16,
                          color: LeadTheme.primary,
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  if (_selectedIds.contains(id)) {
                    _selectedIds.remove(id); // tap again to deselect
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
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _dealSummaryCard(SolarLeadsModel lead) {
  String amt(double v) => v >= 100000
      ? '₹${(v / 100000).toStringAsFixed(1)}L'
      : v >= 1000
      ? '₹${(v / 1000).toStringAsFixed(0)}K'
      : '₹${v.toStringAsFixed(0)}';

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      border: Border.all(color: Colors.blue.shade200),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        AppSvgIcon(AppSvgAssets.handshake, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Deal Closed  •  ${amt(lead.finalAmount!)}  •  Advance: ${amt(lead.advancePayment ?? 0)}',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
          ),
        ),
      ],
    ),
  );
}

Widget _loadingTile(String msg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  decoration: BoxDecoration(
    color:   AppColors.gray100,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade200),
  ),
  child: Row(
    children: [
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: LeadTheme.primary),
      ),
      const SizedBox(width: 10),
      Text(msg, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
    ],
  ),
);

Widget _warningTile(
  String msg, {
  required VoidCallback onRefresh,
  Color color = Colors.amber,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.07),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color.withValues(alpha: 0.35)),
  ),
  child: Row(
    children: [
      AppSvgIcon(AppSvgAssets.triangleAlert, size: 15, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          msg,
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9)),
        ),
      ),
      GestureDetector(
        onTap: onRefresh,
        child: AppSvgIcon(AppSvgAssets.refreshCw, size: 16, color: color),
      ),
    ],
  ),
);

Widget _timeTile(TimeOfDay? time) {
  final hasTime = time != null;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: hasTime ? Colors.green.shade50 :   AppColors.gray100,
      border: Border.all(
        color: hasTime ? Colors.green.shade300 : Colors.grey.shade300,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        AppSvgIcon(
          AppSvgAssets.clock,
          size: 16,
          color: hasTime ? Colors.green : LeadTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Installation Time',
              style: TextStyle(fontSize: 11, color: LeadTheme.textSecondary),
            ),
            Text(
              hasTime ? _fmt(time) : 'Tap to select time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: hasTime ? Colors.green : LeadTheme.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        AppSvgIcon(
          hasTime ? AppSvgAssets.circleCheckBig : AppSvgAssets.arrowRight,
          size: 14,
          color: hasTime ? Colors.green : Colors.grey.shade400,
        ),
      ],
    ),
  );
}

String _fmt(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  final p = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$m $p';
}

Widget _dateTile(String svgAsset, String label, DateTime? date) {
  final c = date != null ? Colors.green : LeadTheme.textSecondary;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: date != null ? Colors.green.shade50 : LeadTheme.surface,
      border: Border.all(
        color: date != null ? Colors.green.shade300 : Colors.grey.shade300,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        AppSvgIcon(svgAsset, size: 16, color: c),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: LeadTheme.textSecondary)),
            Text(
              date == null
                  ? 'Tap to select date'
                  : '${date.day}/${date.month}/${date.year}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: date == null ? LeadTheme.textMuted : c,
              ),
            ),
          ],
        ),
        const Spacer(),
        AppSvgIcon(
          date != null ? AppSvgAssets.circleCheckBig : AppSvgAssets.arrowRight,
          size: 14,
          color: date != null ? Colors.green : Colors.grey.shade400,
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
      const AppSvgIcon(AppSvgAssets.userRound, size: 16, color: LeadTheme.primary),
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
                  color: LeadTheme.textPrimary),
            ),
            Text(
              '${lead.mobile}  ·  ${lead.address}',
              style: const TextStyle(
                  fontSize: 11, color: LeadTheme.textSecondary),
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
}) => LeadTextFormField(
  controller: c,
  label: label,
  svgIcon: svgAsset,
  accentColor: LeadTheme.orange,
  required: false,
  maxLines: maxLines,
  bottomSpacing: 0,
);

Widget _saveBtn(bool saving, VoidCallback onPressed, String label) => SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    onPressed: saving ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: LeadTheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: saving
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
        : Text(
            label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
  ),
);

