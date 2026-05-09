// lib/screens/Dashboards/Leads/Solar/solar_lead_detail_screen.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/role_helper.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/Steps/edit_basic_info.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/Steps/installation_assigned_screen.dart';
import 'Steps/scheduled_visit_screen.dart';
import 'Steps/technical_visit_screen.dart';
import 'Steps/quotation_screen.dart';
import 'Steps/followup_screen.dart';
import 'Steps/deal_screen.dart';
import 'Steps/installation_started_screen.dart';
import 'Steps/installation_completed_screen.dart';
import 'Steps/agreement_upload_screen.dart';
import 'Steps/portal_screen.dart';
import 'Steps/meter_screen.dart';
import 'Steps/subsidy_screen.dart';
import 'Steps/payment_screen.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

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

class SolarLeadDetailScreen extends StatefulWidget {
  final SolarLeadsModel lead;
  const SolarLeadDetailScreen({super.key, required this.lead});

  @override
  State<SolarLeadDetailScreen> createState() => _SolarLeadDetailScreenState();
}

class _SolarLeadDetailScreenState extends State<SolarLeadDetailScreen> {
  late SolarLeadsModel lead;
  bool _fetching = false;
  bool _downloadingPdf = false;

  // ── PDF fonts — loaded once per download ──────────────────────────────────
  pw.Font? _pdfGujaratiFont;
  pw.Font? _pdfLatinFont;

  List<_TeamMember> _teamMembers = [];
  bool _teamLoading = false;

  UserRole get _role =>
      RoleHelper.roleFrom(context.read<AppStateCubit>().state);
  bool get _isAdmin => _role == UserRole.admin;

  static const int _salesMaxVisibleStepIndex = 8;
  int get _maxVisibleStepIndex => _isAdmin
      ? SolarLeadsModel.workflowSteps.length - 1
      : _salesMaxVisibleStepIndex;
  int get _totalSteps => _maxVisibleStepIndex + 1;

  @override
  void initState() {
    super.initState();
    lead = widget.lead;
    _refresh();
    if (_isAdmin) {
      _fetchInstallTeam();
    }
  }

  Future<void> _fetchInstallTeam() async {
    setState(() => _teamLoading = true);
    try {
      final res = await DioClient().dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminStaff,
        queryParameters: {'role': 'installation', 'limit': 100},
      );
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

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _fetching = true);
    final cubit = context.read<SolarLeadCubit>();
    cubit.refreshLead(lead.id);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _nextStepLabel() {
    final stepIdx = lead.currentStep.index;
    final nextIdx = stepIdx + 1;
    return nextIdx < SolarLeadsModel.workflowSteps.length
        ? SolarLeadsModel.workflowSteps[nextIdx]
        : 'Complete';
  }

  bool get _canDownloadQuotationPdf =>
      lead.currentStep.index >= SolarStep.quotation.index;

  // ── Font loaders ──────────────────────────────────────────────────────────

  /// Gujarati font — tries local asset first, falls back to Google Fonts.
  Future<pw.Font> _loadGujaratiPdfFont() async {
    try {
      return pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansGujarati-Regular.ttf'),
      );
    } catch (_) {
      return PdfGoogleFonts.notoSansGujaratiRegular();
    }
  }

  /// Latin font — tries local asset first, falls back to Google Fonts.
  Future<pw.Font> _loadLatinPdfFont() async {
    try {
      return pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      );
    } catch (_) {
      return PdfGoogleFonts.notoSansRegular();
    }
  }

  // ── Text style helper (uses fontFallback for Gujarati support) ────────────
  pw.TextStyle _pdfTextStyle({
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) {
    final fallback = <pw.Font>[];
    if (_pdfGujaratiFont != null) fallback.add(_pdfGujaratiFont!);
    if (_pdfLatinFont != null) fallback.add(_pdfLatinFont!);
    return pw.TextStyle(
      font: _pdfGujaratiFont, // Gujarati font as base
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFallback: fallback,
    );
  }

  // ── Download & upload ─────────────────────────────────────────────────────
  Future<void> _downloadQuotationPdf() async {
    if (_downloadingPdf) return;
    setState(() => _downloadingPdf = true);
    try {
      final fileName =
          'Solar_Quotation_${lead.customerName.replaceAll(' ', '_')}_${DateFormat('ddMMMyy').format(DateTime.now())}.pdf';
      final bytes = await _buildQuotationPdf();

      // Share / save on device
      await Printing.sharePdf(bytes: bytes, filename: fileName);

      // Upload to backend (background — failure is non-fatal)
      Object? uploadError;
      try {
        await _uploadQuotationPdf(bytes, fileName);
      } catch (e) {
        uploadError = e;
      }

      if (!mounted) return;
      if (uploadError == null) {
        AppFeedback.showSuccess(context, 'PDF Downloaded Successfully');
      } else {
        AppFeedback.showSuccess(context, 'PDF Downloaded (upload failed)');
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'PDF Error: $e');
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Future<void> _uploadQuotationPdf(Uint8List bytes, String filename) async {
    final form = FormData.fromMap({
      'quotationPdf': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse('application/pdf'),
      ),
    });

    await DioClient().dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.solarLead}/${lead.id}/quotation-pdf',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  // ── PDF builder ───────────────────────────────────────────────────────────
  Future<Uint8List> _buildQuotationPdf() async {
    // Load both fonts before building
    _pdfGujaratiFont = await _loadGujaratiPdfFont();
    _pdfLatinFont = await _loadLatinPdfFont();

    final pdf = pw.Document();

    final pdfTheme = pw.ThemeData.withFont(
      base: _pdfGujaratiFont!,
      bold: _pdfGujaratiFont!,
      italic: _pdfGujaratiFont!,
      boldItalic: _pdfGujaratiFont!,
    );

    final q = lead.quotationData;
    final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    final logoBytes = await rootBundle.load('assets/images/splash-logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final brandStrong = PdfColor.fromInt(AppColors.primary.value);
    final brandLight = PdfColor.fromInt(AppColors.divider.value);
    final brandTextDark = PdfColor.fromInt(AppColors.textDark.value);

    String txt(String? v) => (v == null || v.trim().isEmpty) ? '' : v.trim();
    String money(double? v) {
      final val = (v ?? 0).toDouble();
      if (val == 0) return '';
      return 'Rs. ${NumberFormat('#,##,###').format(val.toInt())}';
    }

    final hasSplitCosts =
        q.rooftopSystemCost > 0 ||
        q.elevatedStructureCost > 0 ||
        q.netMeterCost > 0 ||
        q.premiumOtherCost > 0;

    final rooftop = hasSplitCosts ? q.rooftopSystemCost : q.totalAmount;
    final elevated = hasSplitCosts ? q.elevatedStructureCost : 0.0;
    final netMeter = hasSplitCosts ? q.netMeterCost : 0.0;
    final premium = hasSplitCosts ? q.premiumOtherCost : 0.0;
    final totalCost = hasSplitCosts
        ? (rooftop + elevated + netMeter + premium)
        : q.totalAmount;
    final subsidy = q.subsidyAmount;
    final systemAfterSubsidy = q.customerPayable > 0
        ? q.customerPayable
        : (totalCost - subsidy);
    final connection = txt(lead.electricityConnection);

    pdf.addPage(
      pw.MultiPage(
        theme: pdfTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(12, 10, 12, 0),
        footer: (_) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: -12),
          child: pw.Container(
            width: double.infinity,
            color: PdfColor.fromInt(AppColors.background.value),
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            child: pw.Text(
              ' Mota varaccha , Surat -395010  |  Email: contact@kaaryabook.com  |  Phone: +91 87805 03913 ',
              textAlign: pw.TextAlign.center,
              style: _pdfTextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(AppColors.textDark.value),
              ),
            ),
          ),
        ),
        build: (_) => [
          // ── Header ────────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 160,
                  height: 70,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.topCenter,
                    child: pw.Image(logoImage, fit: pw.BoxFit.fitWidth),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Mota varachha, Surat - 395010',
                        style: _pdfTextStyle(
                          fontSize: 8.8,
                          color: brandTextDark,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Email: contact@kaaryabook.com',
                        style: _pdfTextStyle(
                          fontSize: 8.2,
                          color: brandTextDark,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Mobile: +91 87805 03913',
                        style: _pdfTextStyle(
                          fontSize: 8.8,
                          fontWeight: pw.FontWeight.bold,
                          color: brandTextDark,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: brandLight),
          pw.SizedBox(height: 12),

          // ── Customer Details ──────────────────────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  _tdHeader('Name:'),
                  _td(txt(lead.customerName)),
                  _tdHeader('GEB ID 1Φ/3Φ'),
                  _td(connection),
                ],
              ),
              pw.TableRow(
                children: [
                  _tdHeader('Address:'),
                  _td(txt(lead.address)),
                  _tdHeader('TPL ID 1Φ/3Φ'),
                  _td(connection),
                ],
              ),
              pw.TableRow(
                children: [
                  _tdHeader('Mobile No:'),
                  _td(txt(lead.mobile)),
                  _tdHeader('City:'),
                  _td(txt(lead.village)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // ── Drawings ─────────────────────────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Terrance Drawing',
                      style: _pdfTextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text('', style: _pdfTextStyle(fontSize: 8)),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Solar Panel Arrangement',
                      style: _pdfTextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Align(
                        alignment: pw.Alignment.bottomLeft,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 4, bottom: 2),
                          child: pw.Text(
                            'Nos:',
                            style: _pdfTextStyle(fontSize: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // ── Quotation Table ───────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            color: PdfColor.fromInt(AppColors.background.value),
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Text(
              'Quotation :',
              style: _pdfTextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(20),
              1: const pw.FlexColumnWidth(2.8),
              2: const pw.FixedColumnWidth(24),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              _pdfTableRow(
                '1',
                'Per KW Solar System Cost(એક કિલોવોટ નો સોલાર સિસ્ટમ નો ખર્ચ)',
                '',
                '',
              ),
              _pdfTableRow(
                '2',
                'Solar Rooftop System Total Cost(સોલર રૂફટોપ સિસ્ટમ નો ટોટલ ખર્ચ)',
                '',
                money(rooftop),
              ),
              _pdfTableRow(
                '3',
                'Heighted/Elevated Structure Cost(એલિવેટેડ ફ્રેબિકેશન નો ખર્ચ)',
                '+',
                money(elevated),
              ),
              _pdfTableRow(
                '4',
                'GEB/Torrent Net Meter Cost(મીટર ખર્ચ)',
                '+',
                money(netMeter),
              ),
              _pdfTableRow(
                '5',
                'Solar Panel Premium Charge/Other Cost(સોલર પેનલ પ્રીમિયમ ચાર્જ / અન્ય ખર્ચ)',
                '+',
                money(premium),
              ),
              _pdfTableRow(
                '',
                'Total Net Payable(ટોટલ ભરવા પાત્ર રકમ)',
                '',
                money(totalCost),
                isEmphasis: true,
              ),
              _pdfTableRow(
                '*',
                'Subsidy(સબસિડી - મીટર લાગ્યા પછી 30 દિવસમાં ગ્રાહકના બેંક ખાતા માં જમા થશે)',
                '-',
                money(subsidy),
              ),
              _pdfTableRow(
                '*',
                'System Cost After Subsidy(સિસ્ટમ નો સબસિડી બાદ કર્યા પછી નો ખર્ચ)',
                '',
                money(systemAfterSubsidy),
                isEmphasis: true,
                isBold: true,
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // ── Terms & Conditions ────────────────────────────────────────────
          pw.Text(
            'Terms & Condition',
            style: _pdfTextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(50),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  _tdHeader('પેમેન્ટ ૦૧'),
                  _td(
                    '10% એડવાન્સ રજીસ્ટ્રેશન, મીટર ચાર્જ માટે - Non Refundable.',
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _tdHeader('પેમેન્ટ ૦૨'),
                  _td('80% સ્ટ્રક્ચર બની જાય પછી અને પેનલ પહોંચે પહેલા.'),
                ],
              ),
              pw.TableRow(
                children: [
                  _tdHeader('પેમેન્ટ ૦૩'),
                  _td('10% સિસ્ટમ ઇન્સ્ટોલ થઈ જાય પછી.'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'કોટેશન પ્રમાણે વસ્તુ, સર્વિસ કે અન્ય કામમાં પાછળ થી કરેલો ફેરફાર એ વધારાના ખર્ચ સાથે રહેશે.',
            style: _pdfTextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'જીઇબી અથવા ટોરન્ટ ઘરની સુરક્ષા માટે ઇઝબ/ફ્યૂઝ લગાડવા નું કહે અથવા લોડ વધારાનું કહે તો એ ગ્રાહકની જવાબદારી માં રહેશે.',
            style: _pdfTextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // ── Additional Notes ──────────────────────────────────────────────
          if ((q.notes ?? '').isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Additional Notes:',
                  style: _pdfTextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(txt(q.notes), style: _pdfTextStyle(fontSize: 9)),
                pw.SizedBox(height: 10),
              ],
            ),

          // ── Signature row ─────────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Date: $dateStr',
                      style: _pdfTextStyle(fontSize: 9),
                    ),
                    pw.Text('Place:', style: _pdfTextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Name Of Engineer:',
                          style: _pdfTextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Container(
                          width: 100,
                          height: 0.5,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 14),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Mobile Number:',
                          style: _pdfTextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Container(
                          width: 100,
                          height: 0.5,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'જરૂરી ડોક્યુમેન્ટ્સ: લાઇટ બિલ, વેરા બિલ/પંચાયત વેરો, આધાર કાર્ડ, પાન કાર્ડ, કેન્સલ ચેક, પાસપોર્ટ ફોટા.',
            style: _pdfTextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Table helpers ─────────────────────────────────────────────────────────
  pw.TableRow _pdfTableRow(
    String no,
    String item,
    String symbol,
    String amount, {
    bool isEmphasis = false,
    bool isHeader = false,
    bool isBold = false,
  }) {
    final textStyle = isHeader
        ? _pdfTextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.brown900,
          )
        : (isEmphasis || isBold)
        ? _pdfTextStyle(fontWeight: pw.FontWeight.bold)
        : _pdfTextStyle();
    final bgColor = isHeader
        ? PdfColor.fromInt(AppColors.primary.value)
        : (isEmphasis ? PdfColor.fromInt(AppColors.background.value) : null);

    return pw.TableRow(
      decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(no, style: textStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(item, style: textStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(symbol, style: textStyle),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(amount, style: textStyle),
          ),
        ),
      ],
    );
  }

  pw.Widget _td(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(text, style: _pdfTextStyle(fontSize: 10)),
  );

  pw.Widget _tdHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: _pdfTextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  );

  // ── Edit basic info ───────────────────────────────────────────────────────
  Future<void> _editNewLead() async {
    final cubit = context.read<SolarLeadCubit>();

    final result = await Navigator.push<SolarLeadsModel>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: EditLeadBasicInfoScreen(lead: lead),
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() => lead = result);
    } else {
      _refresh();
    }
  }

  // ── Slot → Screen mapping ─────────────────────────────────────────────────
  Widget? _screenForSlot(int slot, {bool isEditing = false}) {
    switch (slot) {
      case 0:
        return SolarVisitScheduledScreen(lead: lead, isEditing: isEditing);
      case 1:
        return SolarTechnicalVisitScreen(lead: lead, isEditing: isEditing);
      case 2:
        return SolarQuotationScreen(lead: lead, isEditing: isEditing);
      case 3:
        return SolarFollowupScreen(lead: lead, isEditing: isEditing);
      case 4:
        return SolarDealScreen(lead: lead, isEditing: isEditing);
      case 5:
        return SolarInstallationAssignScreen(lead: lead, isEditing: isEditing);
      case 6:
        return SolarInstallationStartedScreen(lead: lead, isEditing: isEditing);
      case 7:
        return SolarInstallationScreen(lead: lead, isEditing: isEditing);
      case 8:
        return SolarAgreementUploadScreen(lead: lead, isEditing: isEditing);
      case 9:
        return SolarMeterScreen(lead: lead, isEditing: isEditing);
      case 10:
        return SolarPortalScreen(lead: lead, isEditing: isEditing);
      case 11:
        return SolarSubsidyScreen(lead: lead, isEditing: isEditing);
      case 12:
      case 13:
      case 14:
        return SolarPaymentScreen(lead: lead, isEditing: isEditing);
      default:
        return null;
    }
  }

  Future<void> _openSlot(int slot, {bool isEditing = false}) async {
    final screen = _screenForSlot(slot, isEditing: isEditing);
    if (screen == null) return;

    final cubit = context.read<SolarLeadCubit>();
    final beforeState = cubit.state;

    final result = await Navigator.push<SolarLeadsModel>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: cubit, child: screen),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() => lead = result);
      return;
    }

    final afterState = cubit.state;
    await _refresh();

    if (mounted) await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (afterState is SolarLeadSaved && !identical(afterState, beforeState)) {
      Navigator.pop(context, afterState.lead);
    }
  }

  Future<void> _openStep() async {
    final stepIdx = lead.currentStep.index;
    await _openSlot(stepIdx, isEditing: false);
  }

  bool _canEditStep(int stepIdx) {
    if (stepIdx == 0) return true;
    return stepIdx <= lead.currentStep.index;
  }

  void _editStep(int stepIdx) {
    if (stepIdx == 0) {
      _editNewLead();
      return;
    }
    _openSlot(stepIdx - 1, isEditing: true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<SolarLeadCubit, SolarLeadState>(
      listener: (ctx, state) {
        if (state is SolarLeadSaved) {
          setState(() {
            lead = state.lead;
            _fetching = false;
          });
        }
        if (state is SolarLeadDetailLoaded) {
          setState(() {
            lead = state.lead;
            _fetching = false;
          });
        }
        if (state is SolarLeadError) {
          setState(() => _fetching = false);
          AppFeedback.showError(context, state.message);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.pop(context, lead);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── APP BAR ───────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: LeadTheme.orange,
                leading: Navigator.canPop(context)
                    ? IconButton(
                        icon: const AppSvgIcon(
                          AppSvgAssets.chevronLeft,
                          color: AppColors.surface,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context, lead),
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
                                color: AppColors.surface,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const AppSvgIcon(
                              AppSvgAssets.fileText,
                              color: AppColors.surface,
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
                          color: AppColors.surface,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const AppSvgIcon(
                        AppSvgAssets.refreshCw,
                        color: AppColors.surface,
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
                        colors: [AppColors.primary, AppColors.primaryDark],
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
                                      color: AppColors.surface,
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
                                      color: AppColors.surface.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.surface.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Sales',
                                      style: TextStyle(
                                        color: AppColors.surface,
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
                                    color: AppColors.surface.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.surface.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    lead.status,
                                    style: const TextStyle(
                                      color: AppColors.surface,
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
                                  color: AppColors.surface,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lead.mobile,
                                  style: const TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const AppSvgIcon(
                                  AppSvgAssets.mapPin,
                                  size: 12,
                                  color: AppColors.surface,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${lead.address}${lead.village.isNotEmpty ? ", ${lead.village}" : ""}',
                                    style: const TextStyle(
                                      color: AppColors.surface,
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
                      _buildPipeline(),
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

  // ── Info card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final rows = <Widget>[];
    if (lead.landSize != null)
      rows.add(
        _infoRow(AppSvgAssets.maximize, 'Land Size', '${lead.landSize} Sq Ft'),
      );
    if (lead.requiredKW != null)
      rows.add(
        _infoRow(AppSvgAssets.zap, 'Required KW', '${lead.requiredKW} kW'),
      );
    if (lead.electricityConnection != null)
      rows.add(
        _infoRow(AppSvgAssets.zap, 'Connection', lead.electricityConnection!),
      );
    if (lead.source != null)
      rows.add(_infoRow(AppSvgAssets.megaphone, 'Source', lead.source!));
    if (lead.source == 'reference' &&
        lead.referenceName != null &&
        lead.referenceName!.isNotEmpty)
      rows.add(
        _infoRow(AppSvgAssets.userRound, 'Reference', lead.referenceName!),
      );
    if (lead.note != null && lead.note!.isNotEmpty)
      rows.add(_infoRow(AppSvgAssets.fileText, 'Note', lead.note!));
    rows.add(
      _infoRow(
        AppSvgAssets.userRound,
        'Created By',
        lead.createdBy?.trim().isNotEmpty == true ? lead.createdBy! : 'Unknown',
      ),
    );
    rows.add(
      _infoRow(
        AppSvgAssets.clock,
        'Created At',
        DateFormat('dd MMM yyyy  hh:mm a').format(lead.createdAt),
      ),
    );
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              color: LeadTheme.orange.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: LeadTheme.orange.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                AppSvgIcon(
                  AppSvgAssets.userRound,
                  size: 14,
                  color: LeadTheme.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LeadTheme.orange,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _editNewLead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LeadTheme.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: LeadTheme.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          AppSvgAssets.pencil,
                          size: 11,
                          color: LeadTheme.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LeadTheme.orange,
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
        AppSvgIcon(svgAsset, size: 14, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    ),
  );

  Widget _buildNextStepButton() {
    return GestureDetector(
      onTap: _openStep,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: LeadTheme.orange.withValues(alpha: 0.4),
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
                color: AppColors.surface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppSvgIcon(
                AppSvgAssets.arrowRight,
                color: AppColors.surface,
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
                      color: AppColors.surface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Next Step → ${_nextStepLabel()}',
                    style: TextStyle(
                      color: AppColors.surface.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const AppSvgIcon(
              AppSvgAssets.chevronRight,
              color: AppColors.surface,
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
      color: AppColors.successLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.successLight),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppSvgIcon(
            AppSvgAssets.circleCheckBig,
            color: AppColors.success,
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
                color: AppColors.success,
              ),
            ),
            Text(
              'All $_totalSteps steps done successfully',
              style: TextStyle(fontSize: 11, color: AppColors.success),
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
        color: AppColors.surface,
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
                  color: LeadTheme.orange,
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
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: LeadTheme.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$done / $total Steps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LeadTheme.orange,
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
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                lead.isCompleted ? AppColors.success : LeadTheme.orange,
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
              color: lead.isCompleted ? AppColors.success : AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  // ── 15-step Pipeline ──────────────────────────────────────────────────────
  Widget _buildPipeline() {
    final cur = lead.currentStep.index;
    final visibleCur = cur.clamp(0, _maxVisibleStepIndex).toInt();

    String fmt(DateTime? d) => d == null ? '' : '${d.day}/${d.month}/${d.year}';

    String fmtTimeOnly(DateTime? d) {
      if (d == null) return '';
      if (d.hour == 0 && d.minute == 0) return '';
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      final p = d.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    }

    String amt(double v) => v >= 100000
        ? '₹${(v / 100000).toStringAsFixed(1)}L'
        : v >= 1000
        ? '₹${(v / 1000).toStringAsFixed(0)}K'
        : '₹${v.toStringAsFixed(0)}';

    dynamic agreementData;
    try {
      agreementData = (lead as dynamic).agreementUploadData;
    } catch (_) {
      agreementData = null;
    }
    final bool agreementUploaded = agreementData?.agreementUploaded == true;
    final bool installationDetailsProvided =
        agreementData?.installationDetailsProvided == true;
    final String? agreementStatus = agreementData?.status?.toString();

    String agreementStatusLabel(String? value) {
      switch (value) {
        case 'underReview':
          return 'Under Review';
        case 'approved':
          return 'Approved';
        case 'rejected':
          return 'Rejected';
        default:
          return value ?? '';
      }
    }

    final steps = [
      _StepData(0, 'New Lead', AppSvgAssets.plus, [
        if (lead.source != null) _Row('Source', lead.source!),
        if (lead.source == 'reference' &&
            lead.referenceName != null &&
            lead.referenceName!.isNotEmpty)
          _Row('Reference', lead.referenceName!),
        _Row(
          'Created',
          DateFormat('dd MMM yyyy, hh:mm a').format(lead.createdAt),
        ),
      ]),
      _StepData(1, 'Visit Scheduled', AppSvgAssets.calendarDays, [
        if (lead.visitDate != null) _Row('Visit Date', fmt(lead.visitDate)),
        if (lead.salesAssigned != null)
          _Row('Assigned To', lead.salesAssigned!),
        if (lead.geoLocation != null) _Row('Location', lead.geoLocation!),
      ]),
      _StepData(2, 'Technical Visit Data', AppSvgAssets.zap, [
        if (lead.technicalVisitData.systemKW != null)
          _Row('System KW', lead.technicalVisitData.systemKW!),
        if (lead.technicalVisitData.inverterBoardType != null)
          _Row('Inverter Board', lead.technicalVisitData.inverterBoardType!),
        if (lead.technicalVisitData.panelCapacity != null)
          _Row('Panel Capacity', lead.technicalVisitData.panelCapacity!),
        if (lead.technicalVisitData.structureHeight != null)
          _Row('Structure Height', lead.technicalVisitData.structureHeight!),
        if (lead.technicalVisitData.estimatedCost != null)
          _Row('Est. Cost', lead.technicalVisitData.estimatedCost!),
      ], photos: lead.technicalPhotoPaths),
      _StepData(3, 'Quotation Sent', AppSvgAssets.fileText, [
        if (lead.systemSize != null) _Row('System', '${lead.systemSize} kW'),
        if (lead.panelType != null) _Row('Panel', lead.panelType!),
        if (lead.inverterType != null) _Row('Inverter', lead.inverterType!),
        if (lead.totalAmount > 0) _Row('Total', amt(lead.totalAmount)),
        if (lead.subsidyAmount != null)
          _Row('Subsidy', amt(lead.subsidyAmount!)),
        if (lead.customerPayable > 0)
          _Row('Customer Payable', amt(lead.customerPayable)),
      ]),
      _StepData(4, 'Follow-up', AppSvgAssets.phone, [
        if (lead.followupDate != null) _Row('Date', fmt(lead.followupDate)),
        if (lead.followupDate != null &&
            fmtTimeOnly(lead.followupDate).isNotEmpty)
          _Row('Time', fmtTimeOnly(lead.followupDate)),
        if (lead.followupOutcome != null)
          _Row('Response', lead.followupOutcome!),
        if (lead.interestLevel != null) _Row('Interest', lead.interestLevel!),
        if (lead.followupData.notes != null)
          _Row('Notes', lead.followupData.notes!),
      ]),
      _StepData(5, 'Deal Closed', AppSvgAssets.handshake, [
        if (lead.finalAmount != null)
          _Row('Final Amount', amt(lead.finalAmount!)),
        if (lead.advancePayment != null)
          _Row('Advance Paid', amt(lead.advancePayment!)),
        if (lead.finalAmount != null)
          _Row('Remaining', amt(lead.pendingAmount.clamp(0, double.infinity))),
        if (lead.paymentMode != null) _Row('Payment Mode', lead.paymentMode!),
        if (lead.expectedInstallDate != null)
          _Row('Expected Install', fmt(lead.expectedInstallDate)),
      ]),
      _StepData(
        6,
        'Installation Assigned',
        AppSvgAssets.idCard,
        [
          if (lead.installationAssignData.teamMemberName != null)
            _Row('Team Member', lead.installationAssignData.teamMemberName!),
          if (lead.installationAssignData.scheduledDate != null)
            _Row('Scheduled', fmt(lead.installationAssignData.scheduledDate)),
          if (lead.installationAssignData.notes != null)
            _Row('Notes', lead.installationAssignData.notes!),
          if (lead.installationTeamMemberNames.isNotEmpty)
            _Row('Team', lead.installationTeamMemberNames.join(', ')),
        ],
        adminOnly: true,
        teamMembers: _teamMembers,
        teamLoading: _teamLoading,
        currentTeamId: lead.installationTeamId,
      ),
      _StepData(
        7,
        'Installation Started',
        AppSvgAssets.hammer,
        [
          if (lead.installationAssignData.teamMemberName != null)
            _Row(
              'Team',
              lead.installationAssignData.teamMemberNames.isNotEmpty
                  ? lead.installationAssignData.teamMemberNames.join(', ')
                  : lead.installationAssignData.teamMemberName!,
            ),
          if (lead.installationData.startDate != null)
            _Row('Started', fmt(lead.installationData.startDate)),
          if (lead.installationData.notes != null)
            _Row('Notes', lead.installationData.notes!),
        ],
        adminOnly: true,
        photos: lead.beforePhotoPaths,
      ),
      _StepData(
        8,
        'Installation Completed',
        AppSvgAssets.sun,
        [
          _Row('Structure', lead.installationData.structureDone ? 'Yes' : 'No'),
          _Row('Wiring', lead.installationData.wiringDone ? 'Yes' : 'No'),
          _Row('Panel', lead.installationData.plumeDone ? 'Yes' : 'No'),
          _Row(
            'Inverter/AC/DC',
            lead.installationData.inverterAcDone ? 'Yes' : 'No',
          ),
          _Row(
            'Fully Project',
            lead.installationData.fullyComplete ? 'Yes' : 'No',
          ),
          _Row('System Tested', lead.systemTested ? '✓ Yes' : '✗ No'),
          _Row('Customer Signed', lead.customerSigned ? '✓ Yes' : '✗ No'),
          if (lead.installationData.completedDate != null)
            _Row('Completed', fmt(lead.installationData.completedDate)),
          if ((lead.installationData.structureVendorName ?? '').isNotEmpty)
            _Row(
              'Structure Vendor',
              lead.installationData.structureVendorName!,
            ),
          if ((lead.installationData.structureVendorCo ?? '').isNotEmpty)
            _Row(
              'Structure Completed Date',
              fmt(DateTime.tryParse(lead.installationData.structureVendorCo!)),
            ),
          if ((lead.installationData.wiringVendorName ?? '').isNotEmpty)
            _Row('Wiring Vendor', lead.installationData.wiringVendorName!),
          if ((lead.installationData.wiringVendorCo ?? '').isNotEmpty)
            _Row(
              'Wiring Completed Date',
              fmt(DateTime.tryParse(lead.installationData.wiringVendorCo!)),
            ),
          if (lead.installationData.notes != null)
            _Row('Notes', lead.installationData.notes!),
        ],
        adminOnly: true,
        photos: lead.afterPhotoPaths,
      ),
      _StepData(9, 'Agreement Upload', AppSvgAssets.fileText, [
        _Row('Agreement Upload', agreementUploaded ? 'Yes' : 'No'),
        _Row(
          'Installation Details',
          installationDetailsProvided ? 'Yes' : 'No',
        ),
        if ((agreementStatus ?? '').isNotEmpty)
          _Row('Status', agreementStatusLabel(agreementStatus)),
      ], adminOnly: true),
      _StepData(10, 'Meter Process', AppSvgAssets.gauge, [
        if (lead.meterGebFileHandover != null)
          _Row(
            'GEB File Handover / Upload',
            lead.meterGebFileHandover! ? 'Yes' : 'No',
          ),
        if ((lead.meterInstallationStatus ?? '').isNotEmpty)
          _Row(
            'Meter Installation',
            lead.meterInstallationStatus == 'done' ? 'Done' : 'Pending',
          ),
        if ((lead.meterSystemRunStatus ?? '').isNotEmpty)
          _Row(
            'System Run',
            lead.meterSystemRunStatus == 'done' ? 'Done' : 'Pending',
          ),
        if (lead.meterApplicationDate != null)
          _Row('Applied', fmt(lead.meterApplicationDate)),
        if (lead.meterInspectionDate != null)
          _Row('Inspection Date', fmt(lead.meterInspectionDate)),
        if (lead.meterInstalledDate != null)
          _Row('Meter Installation Date', fmt(lead.meterInstalledDate)),
      ], adminOnly: true),
      _StepData(11, 'Portal Submitted', AppSvgAssets.trendingUp, [
        if (lead.applicationId != null) _Row('App ID', lead.applicationId!),
        if (lead.portalStatus != null) _Row('Status', lead.portalStatus!),
        if (lead.portalData.notes != null)
          _Row('Notes', lead.portalData.notes!),
      ], adminOnly: true),
      _StepData(12, 'Subsidy Completed', AppSvgAssets.building2, [
        if (lead.subsidyClaim != null)
          _Row('Subsidy Claim', lead.subsidyClaim! ? 'Yes' : 'No'),
        if (lead.subsidyReceivedAmount != null)
          _Row('Received Amount', lead.subsidyReceivedAmount! ? 'Yes' : 'No'),
        if (lead.subsidyData.notes != null)
          _Row('Notes', lead.subsidyData.notes!),
      ], adminOnly: true),
      _StepData(13, 'Payment Remaining', AppSvgAssets.indianRupee, [
        _Row('Total', amt(lead.finalAmount ?? lead.paymentSummary.totalAmount)),
        _Row('Paid', amt(lead.paidAmount)),
        _Row('Pending', amt(lead.pendingAmount.clamp(0, double.infinity))),
        if (lead.paymentHistory.isNotEmpty)
          _Row('Transactions', '${lead.paymentHistory.length} payment(s)'),
      ], adminOnly: true),
      _StepData(14, 'Project Completed', AppSvgAssets.trophy, [
        _Row(
          'Payment Status',
          lead.pendingAmount <= 0 ? 'Fully Paid' : 'Pending',
        ),
        _Row('Paid Amount', amt(lead.paidAmount)),
      ], adminOnly: true),
    ];

    final visibleSteps = steps
        .where((s) => s.index <= _maxVisibleStepIndex)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          return _PipelineRow(
            step: s,
            isDone: lead.isCompleted ? true : visibleCur > s.index,
            isCurrent: lead.isCompleted ? false : visibleCur == s.index,
            isLast: i == visibleSteps.length - 1,
            showAdminBadge: false,
            canEdit: _canEditStep(s.index),
            onEdit: _canEditStep(s.index) ? () => _editStep(s.index) : null,
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
class _PipelineRow extends StatefulWidget {
  final _StepData step;
  final bool isDone, isCurrent, isLast, showAdminBadge, canEdit;
  final VoidCallback? onEdit;
  const _PipelineRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.canEdit,
    this.showAdminBadge = false,
    this.onEdit,
  });

  @override
  State<_PipelineRow> createState() => _PipelineRowState();
}

class _PipelineRowState extends State<_PipelineRow> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isCurrent;
  }

  @override
  void didUpdateWidget(_PipelineRow old) {
    super.didUpdateWidget(old);
    if (!old.isCurrent && widget.isCurrent && !_expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_expanded) setState(() => _expanded = true);
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

    final Color dotColor = isDone
        ? AppColors.success
        : isCurrent
        ? LeadTheme.orange
        : AppColors.divider;

    final Color lineColor = isDone ? AppColors.success : AppColors.divider;

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
          // ── Left dot + line ────────────────────────────────────────────
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
                            color: AppColors.surface,
                          )
                        : isCurrent
                        ? AppSvgIcon(
                            step.svgAsset,
                            size: 14,
                            color: AppColors.surface,
                          )
                        : Text(
                            '${step.index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
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

          // ── Right: title + body ────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
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
                                  ? AppColors.success
                                  : isCurrent
                                  ? LeadTheme.orange
                                  : AppColors.textLight,
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
                                color: LeadTheme.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: LeadTheme.orange.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppSvgIcon(
                                    AppSvgAssets.pencil,
                                    size: 11,
                                    color: LeadTheme.orange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: LeadTheme.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        if (isDone)
                          _Badge('Done', AppColors.success)
                        else if (isCurrent)
                          _Badge('Current', LeadTheme.orange),
                        if (widget.showAdminBadge && !isDone) ...[
                          const SizedBox(width: 4),
                          _Badge('Admin', AppColors.primary),
                        ],
                        if (canToggle && (hasData || hasPhotos)) ...[
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: const AppSvgIcon(
                              AppSvgAssets.chevronDown,
                              size: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Collapsible body
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _expanded
                        ? _PipelineExpandedBody(
                            isDone: isDone,
                            hasData: hasData,
                            hasPhotos: hasPhotos,
                            step: step,
                            imgUrl: _imgUrl,
                            onShowImage: (url, i) =>
                                _showFullImage(context, url, step.photos, i),
                          )
                        : _PipelineCollapsedHint(
                            isDone: isDone,
                            hasData: hasData,
                            step: step,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expanded body ─────────────────────────────────────────────────────────────
class _PipelineExpandedBody extends StatelessWidget {
  final bool isDone, hasData, hasPhotos;
  final _StepData step;
  final String Function(String) imgUrl;
  final void Function(String url, int idx) onShowImage;

  const _PipelineExpandedBody({
    required this.isDone,
    required this.hasData,
    required this.hasPhotos,
    required this.step,
    required this.imgUrl,
    required this.onShowImage,
  });

  @override
  Widget build(BuildContext context) {
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
                  ? LeadTheme.orange.withValues(alpha: 0.05)
                  : LeadTheme.orange.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDone
                    ? LeadTheme.orange.withValues(alpha: 0.25)
                    : LeadTheme.orange.withValues(alpha: 0.15),
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
                            width: 120,
                            child: Text(
                              r.label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textGray,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.value,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
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
                  final url = imgUrl(step.photos[i]);
                  return GestureDetector(
                    onTap: () => onShowImage(url, i),
                    child: Container(
                      width: 88,
                      height: 88,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.divider,
                        border: Border.all(color: Colors.grey.shade300),
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
                              color: AppColors.textLight,
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
}

// ── Collapsed hint ────────────────────────────────────────────────────────────
class _PipelineCollapsedHint extends StatelessWidget {
  final bool isDone, hasData;
  final _StepData step;
  const _PipelineCollapsedHint({
    required this.isDone,
    required this.hasData,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
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
        style: const TextStyle(fontSize: 10.5, color: AppColors.textLight),
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
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

// ── Photo viewer ──────────────────────────────────────────────────────────────
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
        icon: const AppSvgIcon(AppSvgAssets.x, color: AppColors.surface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${_current + 1} / ${widget.urls.length}',
        style: const TextStyle(color: AppColors.surface, fontSize: 14),
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
                    child: CircularProgressIndicator(color: AppColors.surface),
                  ),
            errorBuilder: (_, __, ___) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSvgIcon(AppSvgAssets.imageOff, color: Colors.grey, size: 48),
                SizedBox(height: 8),
                Text(
                  'Could not load image',
                  style: TextStyle(color: Colors.grey),
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
                        ? AppColors.surface
                        : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          )
        : null,
  );
}
