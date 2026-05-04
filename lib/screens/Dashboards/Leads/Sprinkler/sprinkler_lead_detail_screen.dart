// lib/screens/Dashboards/Leads/Sprinkler/sprinkler_lead_detail_screen.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/role_helper.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/deal_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_followup_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/payment_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_quotation_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/scheduled_visit.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_edit_basic_info.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_installation_assigned_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_installation_started_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_installation_completed_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/visit_data.dart';
import 'package:solar_project/Helper/app_colors.dart';

class _TeamMember {
  final String id, name, phone;
  const _TeamMember({
    required this.id,
    required this.name,
    required this.phone,
  });
  factory _TeamMember.fromJson(Map<String, dynamic> j) => _TeamMember(
    id: j['_id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
  );
}

class SprinklerLeadDetailScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SprinklerLeadDetailScreen({super.key, required this.lead});
  @override
  State<SprinklerLeadDetailScreen> createState() =>
      _SprinklerLeadDetailScreenState();
}

class _SprinklerLeadDetailScreenState
    extends State<SprinklerLeadDetailScreen> {
  late SprinklerLeadModel lead;
  bool _fetching = false;
  bool _downloadingPdf = false;

  List<_TeamMember> _teamMembers = [];
  bool _teamLoading = false;

  UserRole get _role =>
      RoleHelper.roleFrom(context.read<AppStateCubit>().state);
  bool get _isAdmin => _role == UserRole.admin;
  bool get _isInstallationRole => _role == UserRole.installation;

  static const int _salesMaxVisibleStepIndex = 8;
  int get _maxVisibleStepIndex => _isAdmin
      ? SprinklerLeadModel.workflowSteps.length - 1
      : _salesMaxVisibleStepIndex;
  int get _totalSteps => _maxVisibleStepIndex + 1;

  @override
  void initState() {
    super.initState();
    lead = widget.lead;
    // FIX: use addPostFrameCallback so context is fully attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
      if (_isAdmin) _fetchInstallTeam();
    });
  }

  Future<void> _fetchInstallTeam() async {
    if (!mounted) return;
    setState(() => _teamLoading = true);
    try {
      final res = await DioClient().dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminStaff,
        queryParameters: {'role': 'installation', 'limit': 100},
      );
      if (!mounted) return;
      final body = res.data ?? {};
      List<dynamic> raw = [];
      for (final key in ['staff', 'data', 'users', 'members', 'results']) {
        if (body[key] is List) {
          raw = body[key] as List;
          break;
        }
      }
      final list = raw
          .map((e) => _TeamMember.fromJson(e as Map<String, dynamic>))
          .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
          .toList();
      if (mounted) setState(() => _teamMembers = list);
    } on DioException catch (e) {
      debugPrint('InstallTeam DioError: ${e.message}');
    } catch (e) {
      debugPrint('InstallTeam error: $e');
    } finally {
      if (mounted) setState(() => _teamLoading = false);
    }
  }

  // FIX: _refresh now safely captures cubit before async gap,
  // guards all setState calls with mounted checks, and does NOT
  // call fetchAllLeads() here (that causes race conditions with
  // BlocListener and can trigger the assertion when context detaches).
  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _fetching = true);
    try {
      context.read<SprinklerLeadCubit>().refreshLead(lead.id);
    } catch (_) {
      // context left the tree — ignore
      if (mounted) setState(() => _fetching = false);
    }
  }

  // FIX: mounted check added before context usage
  void _popWithRefresh() {
    if (!mounted) return;
    try {
      // Trigger list refresh on the way out instead of inside _refresh()
      // to avoid the race condition with BlocListener.
      context.read<SprinklerLeadCubit>().fetchAllLeads();
    } catch (_) {}
    Navigator.pop(context, lead);
  }

  String _nextStepLabel() {
    final stepIdx = lead.currentStep.index;
    final nextIdx = stepIdx + 1;
    return nextIdx < SprinklerLeadModel.workflowSteps.length
        ? SprinklerLeadModel.workflowSteps[nextIdx]
        : 'Complete';
  }

  bool get _canDownloadQuotationPdf =>
      lead.currentStep.index >= SprinklerStep.quotation.index;

  Future<void> _downloadQuotationPdf() async {
    if (_downloadingPdf) return;
    if (!mounted) return;
    setState(() => _downloadingPdf = true);
    try {
      final fileName =
          'Sprinkler_Quotation_${lead.customerName.replaceAll(' ', '_')}_${DateFormat('ddMMMyy').format(DateTime.now())}.pdf';
      final bytes = await _buildQuotationPdf();
      await _uploadQuotationPdf(bytes, fileName);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'PDF Error: $e');
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Future<void> _uploadQuotationPdf(Uint8List bytes, String filename) async {
    try {
      final form = FormData.fromMap({
        'quotationPdf': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse('application/pdf'),
        ),
      });
      await DioClient().dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.sprinklerLead}/${lead.id}/quotation-pdf',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (e) {
      debugPrint('PDF upload error: $e');
    }
  }

  Future<Uint8List> _buildQuotationPdf() async {
    final pdf = pw.Document();
    final q = lead.quotationData;
    final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    final logoBytes = await rootBundle.load('assets/images/logo.jpeg');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final signatureImage = await _loadFirstAvailablePdfImage([
      'assets/images/final-sign.jpg',
    ]);

    const brandDark = PdfColor.fromInt(0xFF0D3B82);
    const brandBlue = PdfColor.fromInt(0xFF42A5F5);
    const softRow = PdfColor.fromInt(0xFFF1F6FF);
    const border = PdfColor.fromInt(0xFFB0BEC5);

    String txt(String? value) => value == null ? '' : value.trim();
    String money(double value) =>
        'Rs ${NumberFormat('#,##,###').format(value.round())}';

    final fallbackItems = <SprinklerQuotationLineItem>[];
    if (txt(q.typeOfSprinkler).isNotEmpty) {
      fallbackItems.add(
        SprinklerQuotationLineItem(
          description: txt(q.typeOfSprinkler),
          quantity: q.noOfSprinklerSet?.toString() ?? '',
          unitPrice: 0,
          total: 0,
        ),
      );
    }
    if (txt(q.pumpDetails).isNotEmpty) {
      fallbackItems.add(
        SprinklerQuotationLineItem(
          description: 'Pump: ${txt(q.pumpDetails)}',
          quantity: '1',
          unitPrice: 0,
          total: 0,
        ),
      );
    }

    final items = q.lineItems.isNotEmpty ? q.lineItems : fallbackItems;
    final grandTotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final resolvedTotal = grandTotal > 0
        ? grandTotal
        : (q.finalAmount > 0 ? q.finalAmount : q.totalAmount);

    final advancePct = q.advancePercent ?? 50;
    final balancePct = q.balancePercent ?? (100 - advancePct);

    final tableData = items
        .map(
          (item) => [
            item.description,
            item.quantity,
            item.unitPrice > 0 ? money(item.unitPrice) : '-',
            item.total > 0 ? money(item.total) : '-',
          ],
        )
        .toList();

    if (tableData.isEmpty) {
      tableData.add([
        'Sprinkler Work Item',
        '1',
        money(resolvedTotal),
        money(resolvedTotal),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 34,
          marginRight: 34,
          marginTop: 28,
          marginBottom: 0,
        ),
        footer: (_) => pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: -34),
          width: double.infinity,
          color: brandBlue,
          padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
          child: pw.Text(
            ' Mota varaccha , Surat -395010  |  Email: kaaryabook@gmail.com  |  Phone: +91 90999 66333 ',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 180,
                      height: 62,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'QUOTATION',
                      style: pw.TextStyle(
                        fontSize: 24,
                        color: brandDark,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.SizedBox(height: 2),
                    pw.Text('Date: $dateStr'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: border),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer:',
                      style: pw.TextStyle(
                        color: brandDark,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      lead.customerName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (txt(lead.address).isNotEmpty)
                      pw.Text(txt(lead.address)),
                    if (txt(lead.village).isNotEmpty)
                      pw.Text(txt(lead.village)),
                    if (txt(lead.phone).isNotEmpty)
                      pw.Text('Phone: ${txt(lead.phone)}'),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KaaryaBook Solar Solutions',
                      style: pw.TextStyle(
                        color: brandBlue,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Mota varachha,'),
                    pw.Text('Surat - 395010'),
                    pw.SizedBox(height: 6),
                    pw.Text('Email: kaaryabook@gmail.com'),
                    pw.Text('Phone: 90999 66333'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const ['DESCRIPTION', 'QUANTITY', 'UNIT PRICE', 'TOTAL'],
            data: tableData,
            headerDecoration: const pw.BoxDecoration(color: brandBlue),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            headerAlignment: pw.Alignment.center,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            oddRowDecoration: const pw.BoxDecoration(color: softRow),
            border: pw.TableBorder.all(color: border, width: 0.6),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.6),
              1: const pw.FlexColumnWidth(1.7),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FlexColumnWidth(2.2),
            },
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: border),
                  bottom: pw.BorderSide(color: border),
                ),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'Grand Total:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    money(resolvedTotal),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Terms & Conditions:',
            style: pw.TextStyle(
              fontSize: 12,
              color: brandDark,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Bullet(
            text: 'Warranty: ${txt(q.warrantyNote)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text: '${advancePct.toStringAsFixed(0)}% advance payment required.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text: '${balancePct.toStringAsFixed(0)}% after installation.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (signatureImage != null)
                  pw.Container(
                    width: 180,
                    height: 46,
                    alignment: pw.Alignment.center,
                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                  ),
                if (signatureImage != null) pw.SizedBox(height: 4),
                pw.Container(width: 180, height: 1, color: border),
                pw.SizedBox(height: 6),
                pw.Text(
                  'For KaaryaBook Solar Solutions',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Authorized Signature',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<pw.MemoryImage?> _loadFirstAvailablePdfImage(
    List<String> assetPaths,
  ) async {
    for (final path in assetPaths) {
      try {
        final data = await rootBundle.load(path);
        if (data.lengthInBytes > 0) {
          return pw.MemoryImage(data.buffer.asUint8List());
        }
      } catch (_) {}
    }
    return null;
  }

  Widget? _screenForSlot(int slot, {bool isEditing = false}) {
    switch (slot) {
      case 0:
        return SprinklerVisitScreen(lead: lead);
      case 1:
        return SpkVisitDataScreen(lead: lead);
      case 2:
        return SprinklerQuotationScreen(lead: lead);
      case 3:
        return SprinklerFollowupScreen(lead: lead, isEditing: isEditing);
      case 4:
        return SprinklerDealScreen(lead: lead);
      case 5:
        return SpkInstallationAssignedScreen(lead: lead, isEditing: isEditing);
      case 6:
        return SpkInstallationStartedScreen(lead: lead, isEditing: isEditing);
      case 7:
        return SpkInstallationCompleteScreen(lead: lead);
      case 9:
        return SprinklerPaymentScreen(lead: lead);
      case 10:
        return SprinklerPaymentScreen(lead: lead);
      default:
        return null;
    }
  }

  // FIX: cubit captured BEFORE Navigator.push to avoid stale context
  Future<void> _openSlot(int slot, {bool isEditing = false}) async {
    final screen = _screenForSlot(slot, isEditing: isEditing);
    if (screen == null) return;
    if (!mounted) return;

    final cubit = context.read<SprinklerLeadCubit>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: cubit, child: screen),
      ),
    );

    // FIX: mounted check after await
    if (!mounted) return;
    await _refresh();
  }

  // FIX: cubit captured BEFORE Navigator.push
  Future<void> _openEditBasicInfo() async {
    if (!mounted) return;
    final cubit = context.read<SprinklerLeadCubit>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: SpkEditBasicInfoScreen(lead: lead),
        ),
      ),
    );

    if (!mounted) return;
    await _refresh();
  }

  bool _canDoCurrentStep() {
    final stepIdx = lead.currentStep.index;
    if (_isAdmin) return true;
    if (_isInstallationRole) return stepIdx >= 6 && stepIdx <= 10;
    return true;
  }

  Future<void> _openStep() async {
    if (!_canDoCurrentStep()) return;
    await _openSlot(lead.currentStep.index);
  }

  bool _canEditStep(int stepIdx) {
    if (stepIdx > lead.currentStep.index) return false;
    if (stepIdx == 0) return !_isInstallationRole;
    if (_isAdmin) return true;
    if (_isInstallationRole && stepIdx >= 7 && stepIdx <= 10) return true;
    if (!_isAdmin && !_isInstallationRole) return true;
    return false;
  }

  void _editStep(int stepIdx) {
    if (stepIdx == 0) {
      _openEditBasicInfo();
      return;
    }
    _openSlot(stepIdx - 1, isEditing: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
      listener: (ctx, state) {
        // FIX: always check mounted before setState in listener
        if (!mounted) return;
        if (state is SprinklerLeadSaved) {
          setState(() {
            lead = state.lead;
            _fetching = false;
          });
        }
        if (state is SprinklerLeadError) {
          setState(() => _fetching = false);
          AppFeedback.showError(context, state.message);
        }
        // FIX: also reset _fetching on loading completion via Loaded state
        if (state is SprinklerLeadsLoaded) {
          if (_fetching) setState(() => _fetching = false);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _popWithRefresh();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F5FF),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: LeadTheme.secondary,
                leading: Navigator.canPop(context)
                    ? IconButton(
                        icon: const AppSvgIcon(
                          AppSvgAssets.chevronLeft,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _popWithRefresh,
                      )
                    : null,
                actions: [
                  if (_canDownloadQuotationPdf)
                    _downloadingPdf
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const AppSvgIcon(
                              AppSvgAssets.fileText,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Download Quotation PDF',
                            onPressed: _downloadQuotationPdf,
                          ),
                  if (_fetching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const AppSvgIcon(
                        AppSvgAssets.refreshCw,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _refresh,
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary), AppColors.primaryLight)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 50, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lead.customerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!_isAdmin)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      _isInstallationRole
                                          ? 'Install'
                                          : 'Sales',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    lead.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const AppSvgIcon(
                                  AppSvgAssets.phone,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lead.phone,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const AppSvgIcon(
                                  AppSvgAssets.mapPin,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${lead.address}${lead.village.isNotEmpty ? ", ${lead.village}" : ""}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 14),
                      if (!lead.isCompleted)
                        _buildNextStepButton()
                      else
                        _buildCompletedBanner(),
                      const SizedBox(height: 20),
                      _buildTimelineHeader(lead.currentStep.index),
                      const SizedBox(height: 12),
                      _buildPipelineUI(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final rows = <Widget>[];
    if (lead.farmSize != null)
      rows.add(
        _infoRow(
          AppSvgAssets.maximize,
          'Farm Size',
          '${lead.farmSize} acres',
        ),
      );
    if (lead.waterSource != null)
      rows.add(
        _infoRow(AppSvgAssets.droplet, 'Water Source', lead.waterSource!),
      );
    if (lead.cropType?.isNotEmpty == true)
      rows.add(_infoRow(AppSvgAssets.leaf, 'Crop Type', lead.cropType!));
    if (lead.source != null)
      rows.add(_infoRow(AppSvgAssets.megaphone, 'Source', lead.source!));
    if (lead.source == 'reference' &&
        lead.referenceName?.trim().isNotEmpty == true)
      rows.add(
        _infoRow(
          AppSvgAssets.userRound,
          'Reference Name',
          lead.referenceName!.trim(),
        ),
      );
    if (lead.note != null && lead.note!.isNotEmpty)
      rows.add(_infoRow(AppSvgAssets.fileText, 'Note', lead.note!));
    if (lead.createdByName != null)
      rows.add(
        _infoRow(AppSvgAssets.userPlus, 'Created By', lead.createdByName!),
      );
    if (lead.assignedToName != null)
      rows.add(
        _infoRow(AppSvgAssets.idCard, 'Assigned To', lead.assignedToName!),
      );
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: LeadTheme.secondary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: LeadTheme.secondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                AppSvgIcon(
                  AppSvgAssets.userRound,
                  size: 14,
                  color: LeadTheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LeadTheme.secondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openEditBasicInfo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LeadTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: LeadTheme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          AppSvgAssets.pencil,
                          size: 11,
                          color: LeadTheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LeadTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String svgAsset, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        AppSvgIcon(svgAsset, size: 14, color: AppColors.textTertiary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );

  Widget _buildNextStepButton() {
    final stepIdx = lead.currentStep.index;
    final isLocked = !_canDoCurrentStep();

    if (isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppSvgIcon(
                AppSvgAssets.lock,
                color: Colors.orange.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for ${stepIdx >= 6 && stepIdx <= 8 ? "Installation Team" : "Admin"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    'Current: ${lead.status}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _openStep,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary), AppColors.primaryLight)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: LeadTheme.secondary.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppSvgIcon(
                AppSvgAssets.arrowRight,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue: ${lead.status}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Next Step → ${_nextStepLabel()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const AppSvgIcon(
              AppSvgAssets.chevronRight,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryLightest),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primaryLightest)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppSvgIcon(
            AppSvgAssets.circleCheckBig,
            color: Colors.green.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Completed! 🎉',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primary),
              ),
            ),
            Text(
              'All $_totalSteps steps done successfully',
              style: TextStyle(fontSize: 11, color: Colors.green.shade600),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildTimelineHeader(int currentStepIndex) {
    final total = _totalSteps;
    final done = currentStepIndex.clamp(0, _maxVisibleStepIndex).toInt();
    final percent = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: LeadTheme.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Progress Timeline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LeadTheme.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$done / $total Steps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LeadTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppColors.borderLight),
              valueColor: AlwaysStoppedAnimation<Color>(
                lead.isCompleted ? Colors.green : LeadTheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lead.isCompleted
                ? 'All steps completed ✓'
                : 'Current: ${lead.status}',
            style: TextStyle(
              fontSize: 11,
              color: lead.isCompleted
                  ? Colors.green.shade600
                  : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineUI() {
    final cur = lead.currentStep.index;
    final visibleCur = cur.clamp(0, _maxVisibleStepIndex).toInt();

    String fmt(DateTime? d) {
      if (d == null) return '';
      final l = d.toLocal();
      return '${l.day}/${l.month}/${l.year}';
    }

    String fmtTimeOnly(DateTime? d) {
      if (d == null) return '';
      final l = d.toLocal();
      if (l.hour == 0 && l.minute == 0) return '';
      final h = l.hour > 12 ? l.hour - 12 : (l.hour == 0 ? 12 : l.hour);
      final ampm = l.hour >= 12 ? 'PM' : 'AM';
      return '${h.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')} $ampm';
    }

    String fmtVisitClock(String? raw) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty) return '';
      final already12h =
          RegExp(r'\b(am|pm)\b', caseSensitive: false).hasMatch(value);
      if (already12h) return value.toUpperCase();
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
      if (m == null) return value;
      final hour24 = int.tryParse(m.group(1)!);
      final minute = int.tryParse(m.group(2)!);
      if (hour24 == null || minute == null || hour24 > 23 || minute > 59)
        return value;
      final isPm = hour24 >= 12;
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
      return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
    }

    String amt(double v) => v >= 100000
        ? '₹ ${(v / 100000).toStringAsFixed(1)}L'
        : v >= 1000
        ? '₹ ${(v / 1000).toStringAsFixed(0)}K'
        : '₹ ${v.toStringAsFixed(0)}';

    final steps = [
      _StepData(0, 'New Lead', AppSvgAssets.plus, [
        if (lead.source != null) _Row('Source', lead.source!),
        if (lead.source == 'reference' &&
            lead.referenceName?.trim().isNotEmpty == true)
          _Row('Reference Name', lead.referenceName!.trim()),
        _Row('Created', fmt(lead.createdAt)),
      ]),
      _StepData(1, 'Visit Scheduled', AppSvgAssets.mapPin, [
        if (lead.siteVisitData.visitDate != null)
          _Row('Visit Date', fmt(lead.siteVisitData.visitDate)),
        if (fmtVisitClock(lead.siteVisitData.visitTime).isNotEmpty)
          _Row('Time', fmtVisitClock(lead.siteVisitData.visitTime)),
        if (lead.salesPerson != null) _Row('Sales Person', lead.salesPerson!),
        if (lead.siteVisitData.fieldConditionNotes != null)
          _Row('Field', lead.siteVisitData.fieldConditionNotes!),
        if (lead.siteVisitData.waterAvailabilityNotes != null)
          _Row('Water', lead.siteVisitData.waterAvailabilityNotes!),
        if (lead.siteVisitData.notes != null)
          _Row('Notes', lead.siteVisitData.notes!),
      ], photos: lead.sitePhotoPaths),
      _StepData(
        2,
        'Visit Data',
        AppSvgAssets.clipboardList,
        [
          if (lead.visitData.noOfPanels != null)
            _Row('No of Panels', '${lead.visitData.noOfPanels}'),
          if (lead.visitData.pumpCapacity != null)
            _Row('Pump Capacity', lead.visitData.pumpCapacity!),
          if (lead.visitData.typeOfPump != null)
            _Row('Type of Pump', lead.visitData.typeOfPump!),
          if (lead.visitData.deliveryPipeLength != null)
            _Row(
              'Delivery Pipe',
              '${lead.visitData.deliveryPipeLength} feet',
            ),
          if (lead.visitData.noOfSprinklers != null)
            _Row('No of Sprinklers', '${lead.visitData.noOfSprinklers}'),
          if (lead.visitData.cableLength != null)
            _Row('Cable Length', '${lead.visitData.cableLength}m'),
          if (lead.visitData.typeOfSite != null)
            _Row('Type of Site', lead.visitData.typeOfSite!),
          if (lead.visitData.notes != null)
            _Row('Notes', lead.visitData.notes!),
        ],
        photos: lead.visitData.visitPhotos,
      ),
      _StepData(3, 'Quotation Sent', AppSvgAssets.fileText, [
        if (lead.quotationData.noOfSprinklerSet != null)
          _Row('Sprinkler Sets', '${lead.quotationData.noOfSprinklerSet}'),
        if (lead.quotationData.typeOfSprinkler != null)
          _Row('Type', lead.quotationData.typeOfSprinkler!),
        if (lead.quotationData.pipeLength != null)
          _Row('Pipe', '${lead.quotationData.pipeLength}m'),
        if (lead.quotationData.sprinklerQty != null)
          _Row('Qty', '${lead.quotationData.sprinklerQty}'),
        if (lead.quotationData.totalAmount > 0)
          _Row('Total', amt(lead.quotationData.totalAmount)),
        if (lead.quotationData.discount > 0)
          _Row('Discount', amt(lead.quotationData.discount)),
        if (lead.quotationData.finalAmount > 0)
          _Row('Final', amt(lead.quotationData.finalAmount)),
        if (lead.quotationData.warrantyNote != null)
          _Row('Warranty', lead.quotationData.warrantyNote!),
        if (lead.quotationData.notes != null)
          _Row('Notes', lead.quotationData.notes!),
      ]),
      _StepData(4, 'Follow-up', AppSvgAssets.phone, [
        if (lead.followupData.followupDate != null)
          _Row('Date', fmt(lead.followupData.followupDate)),
        if (lead.followupData.followupDate != null &&
            fmtTimeOnly(lead.followupData.followupDate).isNotEmpty)
          _Row('Time', fmtTimeOnly(lead.followupData.followupDate)),
        if (lead.followupData.response != null)
          _Row('Response', lead.followupData.response!),
        if (lead.followupData.remarks != null)
          _Row('Remarks', lead.followupData.remarks!),
        if (lead.interestLevel != null) _Row('Interest', lead.interestLevel!),
        if (lead.followupData.notes != null)
          _Row('Notes', lead.followupData.notes!),
      ]),
      _StepData(5, 'Deal Closed', AppSvgAssets.handshake, [
        if (lead.dealData.finalDealAmount != null)
          _Row('Deal Amt', amt(lead.dealData.finalDealAmount!)),
        if (lead.dealData.discountGiven > 0)
          _Row('Discount', amt(lead.dealData.discountGiven)),
        if (lead.dealData.advancePayment != null)
          _Row('Advance', amt(lead.dealData.advancePayment!)),
        if (lead.dealData.paymentMode != null)
          _Row('Mode', lead.dealData.paymentMode!),
        if (lead.dealData.expectedInstallDate != null)
          _Row('Install By', fmt(lead.dealData.expectedInstallDate)),
        if (lead.dealData.notes != null) _Row('Notes', lead.dealData.notes!),
      ]),
      _StepData(
        6,
        'Installation Assigned',
        AppSvgAssets.idCard,
        [
          if (lead.effectiveInstallerNamesString != null)
            _Row('Installer', lead.effectiveInstallerNamesString!),
          if (lead.installationAssignData.scheduledDate != null)
            _Row(
              'Scheduled Date',
              fmt(lead.installationAssignData.scheduledDate),
            ),
          if (lead.installationAssignData.scheduledDate != null &&
              fmtTimeOnly(lead.installationAssignData.scheduledDate).isNotEmpty)
            _Row(
              'Scheduled Time',
              fmtTimeOnly(lead.installationAssignData.scheduledDate),
            ),
          if (lead.installationAssignData.assignedAt != null)
            _Row(
              'Assigned On',
              fmt(lead.installationAssignData.assignedAt),
            ),
          if (lead.installationAssignData.notes?.trim().isNotEmpty ?? false)
            _Row('Notes', lead.installationAssignData.notes!.trim()),
        ],
        adminOnly: true,
        teamMembers: _teamMembers,
        teamLoading: _teamLoading,
        currentTeamId: lead.effectiveInstallerId,
      ),
      _StepData(
        7,
        'Installation Started',
        AppSvgAssets.hammer,
        [
          if (lead.effectiveInstallerNamesString != null)
            _Row('Team', lead.effectiveInstallerNamesString!),
          if (lead.installationData.startedAt != null)
            _Row('Started', fmt(lead.installationData.startedAt)),
          if (lead.installationData.notes != null)
            _Row('Notes', lead.installationData.notes!),
        ],
        adminOnly: true,
        photos: lead.installationData.beforePhotos,
      ),
      _StepData(
        8,
        'Installation Completed',
        AppSvgAssets.circleCheckBig,
        [
          if (lead.installationData.technicianName != null)
            _Row('Technician', lead.installationData.technicianName!),
          if (lead.installationData.installationDate != null)
            _Row('Date', fmt(lead.installationData.installationDate)),
          _Row(
            'Pending Work',
            lead.installationData.pendingWork ? 'Yes' : 'No',
          ),
          if (lead.installationData.pendingWork &&
              (lead.installationData.pendingWorkNote?.trim().isNotEmpty ??
                  false))
            _Row(
              'Pending Note',
              lead.installationData.pendingWorkNote!.trim(),
            ),
          _Row('Testing', lead.installationData.systemTested ? 'Yes' : 'No'),
          if (lead.installationData.paymentReceived != null)
            _Row(
              'Payment Received',
              lead.installationData.paymentReceived! ? 'Yes' : 'No',
            ),
          if (lead.installationData.paymentReceived == false &&
              lead.installationData.followUpDate != null)
            _Row('Follow-up', fmt(lead.installationData.followUpDate)),
          if (lead.installationData.customerReview?.trim().isNotEmpty ?? false)
            _Row(
              'Customer Review',
              lead.installationData.customerReview!.trim(),
            ),
          if (lead.installationData.materialUsed != null)
            _Row('Material', lead.installationData.materialUsed!),
          if (lead.installationData.extraMaterial != null)
            _Row('Extra', lead.installationData.extraMaterial!),
          if (lead.installationData.workNotes != null)
            _Row('Work Notes', lead.installationData.workNotes!),
          if (lead.installationData.notes != null)
            _Row('Notes', lead.installationData.notes!),
        ],
        adminOnly: true,
        photos: lead.installPhotoPaths,
      ),
      _StepData(
        10,
        'Payment Remaining',
        AppSvgAssets.indianRupee,
        [
          _Row('Total', amt(lead.paymentSummary.totalAmount)),
          _Row('Paid', amt(lead.paymentSummary.amountReceived)),
          _Row('Remaining', amt(lead.paymentSummary.remainingBalance)),
          if (lead.paymentHistory.isNotEmpty)
            _Row('Transactions', '${lead.paymentHistory.length}'),
        ],
        adminOnly: true,
      ),
      _StepData(
        11,
        'Project Completed',
        AppSvgAssets.trophy,
        [
          _Row(
            'Payment Status',
            lead.pendingAmount <= 0 ? 'Fully Paid' : 'Pending',
          ),
          _Row('Paid Amount', amt(lead.paymentSummary.amountReceived)),
        ],
        adminOnly: true,
      ),
    ];

    final visibleSteps = steps
        .where((s) => s.index <= _maxVisibleStepIndex)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
        children: List.generate(visibleSteps.length, (i) {
          final s = visibleSteps[i];
          final canEdit = _canEditStep(s.index);
          return _SpkPipelineRow(
            step: s,
            isDone: lead.isCompleted ? true : visibleCur > s.index,
            isCurrent: lead.isCompleted ? false : visibleCur == s.index,
            isLast: i == visibleSteps.length - 1,
            showAdminBadge: false,
            canEdit: canEdit,
            onEdit: canEdit ? () => _editStep(s.index) : null,
            onAssignInstaller: (s.index == 6 && !_isInstallationRole)
                ? () => _openSlot(5, isEditing: true)
                : null,
            installerName: lead.effectiveInstallerName,
          );
        }),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _Row {
  final String label, value;
  const _Row(this.label, this.value);
}

class _StepData {
  final int index;
  final String label;
  final String svgAsset;
  final List<_Row> rows;
  final bool adminOnly;
  final List<String> photos;
  final List<_TeamMember> teamMembers;
  final bool teamLoading;
  final String? currentTeamId;
  const _StepData(
    this.index,
    this.label,
    this.svgAsset,
    this.rows, {
    this.adminOnly = false,
    this.photos = const [],
    this.teamMembers = const [],
    this.teamLoading = false,
    this.currentTeamId,
  });
}

// ── Pipeline Row ──────────────────────────────────────────────────────────────
class _SpkPipelineRow extends StatefulWidget {
  final _StepData step;
  final bool isDone, isCurrent, isLast, showAdminBadge, canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onAssignInstaller;
  final String? installerName;

  const _SpkPipelineRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.canEdit,
    this.showAdminBadge = false,
    this.onEdit,
    this.onAssignInstaller,
    this.installerName,
  });

  @override
  State<_SpkPipelineRow> createState() => _SpkPipelineRowState();
}

class _SpkPipelineRowState extends State<_SpkPipelineRow> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isCurrent;
  }

  @override
  void didUpdateWidget(_SpkPipelineRow old) {
    super.didUpdateWidget(old);
    if (!old.isCurrent && widget.isCurrent && !_expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _expanded = true);
      });
    }
  }

  String _imgUrl(String path) => ApiConstants.imageUrl(path);

  static void _showFullImage(
    BuildContext ctx,
    String url,
    List<String> all,
    int idx,
  ) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(
          urls: all.map((p) => ApiConstants.imageUrl(p)).toList(),
          initialIndex: idx,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.isDone;
    final isCurrent = widget.isCurrent;
    final isLast = widget.isLast;
    final step = widget.step;

    final Color dotColor =
        isDone ? AppColors.primary) : AppColors.textLight);
    final Color lineColor =
        isDone ? AppColors.primaryLightest) : AppColors.borderLight);
    final isNewLead = step.index == 0;
    final hasData =
        (isDone || isCurrent || isNewLead) &&
        step.rows.where((r) => r.value.isNotEmpty).isNotEmpty;
    final hasPhotos = (isDone || isCurrent) && step.photos.isNotEmpty;
    final canToggle = isDone || isNewLead;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: (isDone || isCurrent)
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const AppSvgIcon(
                            AppSvgAssets.check,
                            size: 15,
                            color: Colors.white,
                          )
                        : AppSvgIcon(
                            step.svgAsset,
                            size: isCurrent ? 14 : 13,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.textTertiary),
                          ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: _expanded
                        ? (hasData ? 70 : 24) + (hasPhotos ? 96 : 0)
                        : 24,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: canToggle && (hasData || hasPhotos)
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  behavior: (canToggle && (hasData || hasPhotos))
                      ? HitTestBehavior.opaque
                      : HitTestBehavior.deferToChild,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : isDone
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDone
                                  ? AppColors.primary)
                                  : AppColors.textTertiary),
                            ),
                          ),
                        ),
                        if (widget.canEdit &&
                            (isDone || isCurrent || isNewLead)) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onEdit,
                            behavior: widget.onEdit != null
                                ? HitTestBehavior.opaque
                                : HitTestBehavior.deferToChild,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: LeadTheme.secondary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: LeadTheme.secondary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppSvgIcon(
                                    AppSvgAssets.pencil,
                                    size: 11,
                                    color: LeadTheme.secondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: LeadTheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (widget.onAssignInstaller != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onAssignInstaller,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppSvgIcon(
                                    AppSvgAssets.cog,
                                    size: 11,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.installerName ?? 'Assign',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        if (isDone)
                          _Badge('Done', AppColors.primary))
                        else if (isCurrent)
                          _Badge('Current', LeadTheme.secondary),
                        if (widget.showAdminBadge && !isDone) ...[
                          const SizedBox(width: 4),
                          _Badge('Admin', Colors.purple),
                        ],
                        if (canToggle && (hasData || hasPhotos)) ...[
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: const AppSvgIcon(
                              AppSvgAssets.chevronDown,
                              size: 14,
                              color: AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _expanded
                        ? _buildExpandedBody(isDone, hasData, hasPhotos, step)
                        : _buildCollapsedHint(isDone, hasData, step),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBody(
    bool isDone,
    bool hasData,
    bool hasPhotos,
    _StepData step,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasData) ...[
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primaryLightest)
                  : AppColors.primaryLightest).withValues(alpha: 0.5),
              border: Border.all(
                color: isDone
                    ? AppColors.primaryLightest)
                    : LeadTheme.secondary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: step.rows
                  .where((r) => r.value.isNotEmpty)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 108,
                            child: Text(
                              r.label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.value,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (hasPhotos) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(step.photos.length, (i) {
                  final url = _imgUrl(step.photos[i]);
                  return GestureDetector(
                    onTap: () =>
                        _showFullImage(context, url, step.photos, i),
                    child: Container(
                      width: 88,
                      height: 88,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.borderLight,
                        border: Border.all(color: AppColors.borderPrimary),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, prog) => prog == null
                              ? child
                              : const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Center(
                            child: AppSvgIcon(
                              AppSvgAssets.imageOff,
                              size: 24,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCollapsedHint(bool isDone, bool hasData, _StepData step) {
    if (!hasData || !isDone) return const SizedBox.shrink();

    final hint = step.rows
        .where((r) => r.value.isNotEmpty)
        .map((r) => '${r.label}: ${r.value}')
        .take(2)
        .join('  ·  ');

    if (hint.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 4),
      child: Text(
        hint,
        style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

// ── Photo Viewer ──────────────────────────────────────────────────────────────
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _PhotoViewer({required this.urls, required this.initialIndex});
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const AppSvgIcon(AppSvgAssets.x, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${_current + 1} / ${widget.urls.length}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      centerTitle: true,
    ),
    body: PageView.builder(
      controller: _ctrl,
      itemCount: widget.urls.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (_, i) => InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            widget.urls[i],
            fit: BoxFit.contain,
            loadingBuilder: (_, child, prog) => prog == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
            errorBuilder: (_, __, ___) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSvgIcon(
                  AppSvgAssets.imageOff,
                  color: AppColors.textSecondary,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'Could not load image',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: widget.urls.length > 1
        ? Container(
            color: Colors.black,
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.urls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? Colors.white
                        : AppColors.textSecondary.shade600,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          )
        : null,
  );
}





