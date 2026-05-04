import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/download_helper.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/data/Repository/solar_leads_repository.dart';
import 'package:solar_project/data/Repository/sprinkler_leads_repository.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_colors.dart';

class AdminRevenueSummaryPage extends StatefulWidget {
  final Color appBarColor;
  const AdminRevenueSummaryPage({
    super.key,
    this.appBarColor = const Color(0xFF14532D),
  });

  @override
  State<AdminRevenueSummaryPage> createState() =>
      _AdminRevenueSummaryPageState();
}

class _AdminRevenueSummaryPageState extends State<AdminRevenueSummaryPage>
    with TickerProviderStateMixin {
  final _solarTabKey = GlobalKey<_ReportTabBodyState>();
  final _sprinklerTabKey = GlobalKey<_ReportTabBodyState>();
  final _materialTabKey = GlobalKey<_ReportTabBodyState>();

  void _triggerDownload() {
    if (_tabController.index == 0) {
      _solarTabKey.currentState?._downloadFilteredXlsx();
    } else if (_tabController.index == 1) {
      _sprinklerTabKey.currentState?._downloadFilteredXlsx();
    } else {
      _materialTabKey.currentState?._downloadFilteredXlsx();
    }
  }

  final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  final _dateFmt = DateFormat('dd-MMM-yy');
  final _solarRepo = SolarLeadRepository(DioClient());
  final _sprinklerRepo = SprinklerLeadRepository(DioClient());
  final _apiService = ApiService();

  bool _isLoading = true;
  String? _error;
  List<SolarLeadsModel> _solarLeads = const [];
  List<SprinklerLeadModel> _sprinklerLeads = const [];
  List<Map<String, dynamic>> _materialCustomers = const [];
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _fetchAllSolarLeads(),
        _fetchAllSprinklerLeads(),
        _fetchAllMaterialCustomers(),
      ]);

      final solar = results[0] as List<SolarLeadsModel>;
      final sprinkler = results[1] as List<SprinklerLeadModel>;
      final material = List<Map<String, dynamic>>.from(results[2] as List);

      solar.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      sprinkler.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _solarLeads = solar;
        _sprinklerLeads = sprinkler;
        _materialCustomers = material;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<SolarLeadsModel>> _fetchAllSolarLeads() async {
    const pageSize = 50;
    final all = <SolarLeadsModel>[];
    var page = 1;

    while (true) {
      final batch = await _solarRepo.getAllLeads(page: page, limit: pageSize);
      if (batch.isEmpty) break;
      all.addAll(batch);
      if (batch.length < pageSize) break;
      page += 1;
      if (page > 100) break;
    }

    return all;
  }

  Future<List<SprinklerLeadModel>> _fetchAllSprinklerLeads() async {
    const pageSize = 20;
    final all = <SprinklerLeadModel>[];
    var page = 1;

    while (true) {
      final batch = await _sprinklerRepo.getAllLeads(page: page);
      if (batch.isEmpty) break;
      all.addAll(batch);
      if (batch.length < pageSize) break;
      page += 1;
      if (page > 100) break;
    }

    return all;
  }

  Future<List<Map<String, dynamic>>> _fetchAllMaterialCustomers() async {
    return _apiService.getMaterialCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _tabController.index == 0
        ? LeadTheme.warning
        : _tabController.index == 1
        ? LeadTheme.secondary
        : const Color(0xFF6366F1);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgSecondary,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.bgSecondary,
          title: const Text(
            'Business Report',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.accent2,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Download Excel',
              onPressed: _isLoading ? null : _triggerDownload,
              icon: AppSvgIcon(
                AppSvgAssets.download,
                size: 24,
                color: AppColors.accent2,
              ),
            ),
            IconButton(
              tooltip: 'Refresh report',
              onPressed: _isLoading ? null : _loadData,
              icon: AppSvgIcon(
                AppSvgAssets.refreshCw,
                color: AppColors.accent2,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadData)
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: activeColor,
                      indicatorWeight: 2.5,
                      labelColor: activeColor,
                      unselectedLabelColor: AppColors.textTertiary,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Project'),
                        Tab(text: 'Sprinkler'),
                        Tab(text: 'Material'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _SolarReportTab(
                          tabKey: _solarTabKey,
                          leads: _solarLeads,
                          currency: _currency,
                          dateFmt: _dateFmt,
                        ),
                        _SprinklerReportTab(
                          tabKey: _sprinklerTabKey,
                          leads: _sprinklerLeads,
                          currency: _currency,
                          dateFmt: _dateFmt,
                        ),
                        _MaterialReportTab(
                          tabKey: _materialTabKey,
                          customers: _materialCustomers,
                          currency: _currency,
                          dateFmt: _dateFmt,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      )
    );
  }
}

class _SolarReportTab extends StatelessWidget {
  final List<SolarLeadsModel> leads;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final GlobalKey<_ReportTabBodyState>? tabKey;

  const _SolarReportTab({
    required this.leads,
    required this.currency,
    required this.dateFmt,
    this.tabKey,
  });

  @override
  Widget build(BuildContext context) {
    final total = leads.length;
    final closed = leads
        .where((l) => l.currentStep.index >= SolarStep.dealDone.index)
        .length;
    final completed = leads.where((l) => l.isCompleted).length;
    final totalAmount = leads.fold<double>(0, (sum, l) => sum + l.totalAmount);

    final rows = leads
        .map(
          (l) => _LeadReportRow(
            customerName: l.customerName,
            mobile: l.mobile,
            address: l.village.isNotEmpty ? l.village : l.address,
            sizeText: l.requiredKW != null ? '${l.requiredKW} kw' : '-',
            startDate: l.createdAt,
            endDate: l.isCompleted ? l.updatedAt : null,
            totalRevenue: l.totalAmount,
          ),
        )
        .toList();

    return _ReportTabBody(
      key: tabKey,
      theme: LeadTheme.warning,
      rows: rows,
      currency: currency,
      dateFmt: dateFmt,
      showSystemFarmColumn: true,
      summary: [
        _SummaryTileData(title: 'Total Leads', value: '$total'),
        _SummaryTileData(title: 'Deal Closed', value: '$closed'),
        _SummaryTileData(title: 'Completed', value: '$completed'),
        _SummaryTileData(title: 'Revenue', value: currency.format(totalAmount)),
      ],
      leadType: 'Solar',
    );
  }
}

class _SprinklerReportTab extends StatelessWidget {
  final List<SprinklerLeadModel> leads;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final GlobalKey<_ReportTabBodyState>? tabKey;

  const _SprinklerReportTab({
    required this.leads,
    required this.currency,
    required this.dateFmt,
    this.tabKey,
  });

  @override
  Widget build(BuildContext context) {
    final total = leads.length;
    final closed = leads
        .where((l) => l.currentStep.index >= SprinklerStep.dealDone.index)
        .length;
    final completed = leads.where((l) => l.isCompleted).length;
    final totalAmount = leads.fold<double>(0, (sum, l) => sum + l.totalAmount);

    final rows = leads
        .map(
          (l) => _LeadReportRow(
            customerName: l.customerName,
            mobile: l.phone,
            address: l.village.isNotEmpty ? l.village : l.address,
            sizeText: l.farmSize != null ? '${l.farmSize} acre' : '-',
            startDate: l.createdAt,
            endDate: l.isCompleted ? l.updatedAt : null,
            totalRevenue: l.totalAmount,
          ),
        )
        .toList();

    return _ReportTabBody(
      key: tabKey,
      theme: const Color(0xFF0E7490),
      rows: rows,
      currency: currency,
      dateFmt: dateFmt,
      showSystemFarmColumn: false,
      summary: [
        _SummaryTileData(title: 'Total Leads', value: '$total'),
        _SummaryTileData(title: 'Deal Closed', value: '$closed'),
        _SummaryTileData(title: 'Completed', value: '$completed'),
        _SummaryTileData(title: 'Revenue', value: currency.format(totalAmount)),
      ],
      leadType: 'Sprinkler',
    );
  }
}

class _MaterialReportTab extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final GlobalKey<_ReportTabBodyState>? tabKey;

  const _MaterialReportTab({
    required this.customers,
    required this.currency,
    required this.dateFmt,
    this.tabKey,
  });

  Map<String, dynamic> _pipelineOf(Map<String, dynamic> customer) {
    final raw = customer['pipeline'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  String _statusOf(Map<String, dynamic> customer) {
    final pipeline = _pipelineOf(customer);
    return (pipeline['status'] ?? 'New').toString();
  }

  bool _isCompletedCustomer(Map<String, dynamic> customer) {
    final pipeline = _pipelineOf(customer);
    final status = _statusOf(customer).trim().toLowerCase();
    final dispatch = pipeline['dispatch'];
    final dispatchDate = dispatch is Map
        ? (dispatch['dispatchDate']?.toString() ?? '')
        : '';

    if (pipeline['isCompleted'] == true) return true;
    if (dispatchDate.isNotEmpty) return true;

    return {
      'completed',
      'project completed',
      'payment completed',
      'payment',
      'won',
    }.contains(status);
  }

  bool _isDealClosed(Map<String, dynamic> customer) {
    final pipeline = _pipelineOf(customer);
    final status = _statusOf(customer).trim().toLowerCase();
    final step = pipeline['currentStep'];
    final stepIndex = step is num ? step.toInt() : -1;
    if (stepIndex >= 2) return true;

    return {
      'won',
      'completed',
      'project completed',
      'payment',
      'payment completed',
      'deal done',
      'quoted',
      'quotation sent',
    }.contains(status);
  }

  double _revenueOf(Map<String, dynamic> customer) {
    final pipeline = _pipelineOf(customer);
    final source = pipeline['source'];
    final dealDone = pipeline['dealDone'];

    final dynamic finalAmount = dealDone is Map
        ? dealDone['finalAmount']
        : null;
    final dynamic materialAmount = source is Map
        ? source['materialAmount']
        : null;

    return _toDouble(finalAmount) ?? _toDouble(materialAmount) ?? 0;
  }

  DateTime _startDateOf(Map<String, dynamic> customer) {
    final createdAt = DateTime.tryParse(
      (customer['createdAt'] ?? '').toString(),
    );
    if (createdAt != null) return createdAt;

    final updatedAt = DateTime.tryParse(
      (customer['updatedAt'] ?? '').toString(),
    );
    if (updatedAt != null) return updatedAt;

    return DateTime.now();
  }

  DateTime? _endDateOf(Map<String, dynamic> customer) {
    final pipeline = _pipelineOf(customer);
    final dispatch = pipeline['dispatch'];
    if (dispatch is Map) {
      final dispatchDate = DateTime.tryParse(
        (dispatch['dispatchDate'] ?? '').toString(),
      );
      if (dispatchDate != null) return dispatchDate;
    }

    if (!_isCompletedCustomer(customer)) return null;
    return DateTime.tryParse((customer['updatedAt'] ?? '').toString());
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final total = customers.length;
    final closed = customers.where(_isDealClosed).length;
    final completed = customers.where(_isCompletedCustomer).length;
    final totalAmount = customers.fold<double>(
      0,
      (sum, c) => sum + _revenueOf(c),
    );

    final rows = customers
        .map(
          (c) => _LeadReportRow(
            customerName: (c['customerName'] ?? '-').toString(),
            mobile: (c['mobile'] ?? '-').toString(),
            address:
                ((c['village'] ?? '').toString().trim().isNotEmpty
                        ? c['village']
                        : c['address'] ?? '-')
                    .toString(),
            sizeText: '-',
            startDate: _startDateOf(c),
            endDate: _endDateOf(c),
            totalRevenue: _revenueOf(c),
          ),
        )
        .toList();

    return _ReportTabBody(
      key: tabKey,
      theme: const Color(0xFF6366F1),
      rows: rows,
      currency: currency,
      dateFmt: dateFmt,
      showSystemFarmColumn: false,
      summary: [
        _SummaryTileData(title: 'Total Leads', value: '$total'),
        _SummaryTileData(title: 'Deal Closed', value: '$closed'),
        _SummaryTileData(title: 'Completed', value: '$completed'),
        _SummaryTileData(title: 'Revenue', value: currency.format(totalAmount)),
      ],
      leadType: 'Material',
    );
  }
}

class _ReportTabBody extends StatefulWidget {
  final Color theme;
  final List<_LeadReportRow> rows;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final bool showSystemFarmColumn;
  final List<_SummaryTileData> summary;
  final String leadType;

  const _ReportTabBody({
    super.key,
    required this.theme,
    required this.rows,
    required this.currency,
    required this.dateFmt,
    required this.showSystemFarmColumn,
    required this.summary,
    required this.leadType,
  });

  @override
  State<_ReportTabBody> createState() => _ReportTabBodyState();
}

enum _TableFilterType { today, thisWeek, thisMonth, duration }

class _ReportTabBodyState extends State<_ReportTabBody> {
  _TableFilterType _selectedFilter = _TableFilterType.thisMonth;
  DateTimeRange? _duration;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _selectedPeriodText() {
    final now = DateTime.now();
    final rangeFmt = DateFormat('d-MMM-yyyy');

    switch (_selectedFilter) {
      case _TableFilterType.today:
        final today = _dateOnly(now);
        return rangeFmt.format(today);
      case _TableFilterType.thisWeek:
        final today = _dateOnly(now);
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return '${rangeFmt.format(startOfWeek)} to ${rangeFmt.format(today)}';
      case _TableFilterType.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return '${rangeFmt.format(startOfMonth)} to ${rangeFmt.format(endOfMonth)}';
      case _TableFilterType.duration:
        if (_duration == null) return 'All Dates';
        final from = _dateOnly(_duration!.start);
        final to = _dateOnly(_duration!.end);
        return '${rangeFmt.format(from)} to ${rangeFmt.format(to)}';
    }
  }

  List<_LeadReportRow> get _filteredRows {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    bool inSelectedRange(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      switch (_selectedFilter) {
        case _TableFilterType.today:
          return d == startOfToday;
        case _TableFilterType.thisWeek:
          final startOfWeek = startOfToday.subtract(
            Duration(days: now.weekday - 1),
          );
          return !d.isBefore(startOfWeek) && !d.isAfter(startOfToday);
        case _TableFilterType.thisMonth:
          return d.year == now.year && d.month == now.month;
        case _TableFilterType.duration:
          if (_duration == null) return true;
          final from = DateTime(
            _duration!.start.year,
            _duration!.start.month,
            _duration!.start.day,
          );
          final to = DateTime(
            _duration!.end.year,
            _duration!.end.month,
            _duration!.end.day,
          );
          return !d.isBefore(from) && !d.isAfter(to);
      }
    }

    return widget.rows.where((row) => inSelectedRange(row.startDate)).toList();
  }

  Future<void> _pickDuration() async {
    DateTime? startDate;
    DateTime? endDate;

    if (_duration != null) {
      startDate = _duration!.start;
      endDate = _duration!.end;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DurationPickerSheet(
        initialStart: startDate,
        initialEnd: endDate,
        onApply: (start, end) {
          setState(() {
            _duration = DateTimeRange(start: start, end: end);
            _selectedFilter = _TableFilterType.duration;
          });
        },
      ),
    );
  }

  Future<void> _downloadFilteredXlsx() async {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final excel = xl.Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    final columns = [
      'Customer',
      'Mobile',
      'Address',
      if (widget.showSystemFarmColumn) 'System Size (kw)',
      'Start Date',
      'End Date',
      'Total Revenue',
    ];

    final type = widget.leadType.toLowerCase();
    final isSolar = type == 'solar';
    final isSprinkler = type == 'sprinkler';
    final titleBg = isSolar
        ? xl.ExcelColor.fromHexString('FFFFF3E0')
        : isSprinkler
        ? xl.ExcelColor.fromHexString('FFEAF4FF')
        : xl.ExcelColor.fromHexString('FFEEF2FF');
    final headerBg = isSolar
        ? xl.ExcelColor.fromHexString('FFF8C471')
        : isSprinkler
        ? xl.ExcelColor.fromHexString('FFB7D8F7')
        : xl.ExcelColor.fromHexString('FFC7D2FE');
    final totalBg = isSolar
        ? xl.ExcelColor.fromHexString('FFFFE5C2')
        : isSprinkler
        ? xl.ExcelColor.fromHexString('FFD6ECFF')
        : xl.ExcelColor.fromHexString('FFE0E7FF');

    final colCount = columns.length;

    // Title row
    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      xl.CellIndex.indexByColumnRow(columnIndex: colCount - 1, rowIndex: 0),
    );
    final titleCell = sheet.cell(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    titleCell.value = xl.TextCellValue(
      widget.leadType == 'Material'
          ? '${widget.leadType} Revenue Report                  Period: ${_selectedPeriodText()}'
          : '${widget.leadType} Project Revenue Report                  Period: ${_selectedPeriodText()}',
    );
    titleCell.cellStyle = xl.CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: xl.ExcelColor.fromHexString('FF2C3E50'),
      backgroundColorHex: titleBg,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    // Header row
    const headerRow = 2;
    for (var c = 0; c < columns.length; c++) {
      final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRow),
      );
      cell.value = xl.TextCellValue(columns[c]);
      cell.cellStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.fromHexString('FF1F2937'),
        backgroundColorHex: headerBg,
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );
    }

    // Data rows
    final dataStartRow = headerRow + 1;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final values = <String>[
        row.customerName,
        row.mobile,
        row.address,
        if (widget.showSystemFarmColumn) row.sizeText,
        widget.dateFmt.format(row.startDate),
        row.endDate != null ? widget.dateFmt.format(row.endDate!) : '-',
        widget.currency.format(row.totalRevenue),
      ];

      for (var c = 0; c < values.length; c++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: c,
            rowIndex: dataStartRow + i,
          ),
        );
        cell.value = xl.TextCellValue(values[c]);
        cell.cellStyle = xl.CellStyle(
          horizontalAlign: c == values.length - 1
              ? xl.HorizontalAlign.Right
              : xl.HorizontalAlign.Left,
          verticalAlign: xl.VerticalAlign.Center,
          backgroundColorHex: i.isEven
              ? xl.ExcelColor.white
              : xl.ExcelColor.fromHexString('FFF8FAFC'),
        );
      }
    }

    final totalRevenue = rows.fold<double>(
      0,
      (sum, row) => sum + row.totalRevenue,
    );

    // Total row
    final totalRowIndex = dataStartRow + rows.length + 1;
    if (colCount > 1) {
      sheet.merge(
        xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
        xl.CellIndex.indexByColumnRow(
          columnIndex: colCount - 2,
          rowIndex: totalRowIndex,
        ),
      );
    }

    final totalLabelCell = sheet.cell(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
    );
    totalLabelCell.value = xl.TextCellValue('Total Revenue');
    totalLabelCell.cellStyle = xl.CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: xl.ExcelColor.fromHexString('FF14532D'),
      backgroundColorHex: totalBg,
      horizontalAlign: xl.HorizontalAlign.Left,
      verticalAlign: xl.VerticalAlign.Center,
    );

    final totalValueCell = sheet.cell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: colCount - 1,
        rowIndex: totalRowIndex,
      ),
    );
    totalValueCell.value = xl.TextCellValue(
      widget.currency.format(totalRevenue),
    );
    totalValueCell.cellStyle = xl.CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: xl.ExcelColor.fromHexString('FF14532D'),
      backgroundColorHex: totalBg,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
    );

    // Professional column widths
    sheet.setColumnWidth(0, 22);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 24);
    var dynamicColumn = 3;
    if (widget.showSystemFarmColumn) {
      sheet.setColumnWidth(dynamicColumn, 18);
      dynamicColumn += 1;
    }
    sheet.setColumnWidth(dynamicColumn, 14); // Start Date
    sheet.setColumnWidth(dynamicColumn + 1, 14); // End Date
    sheet.setColumnWidth(dynamicColumn + 2, 18); // Total Revenue

    final encoded = excel.encode();
    if (encoded == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed')));
      return;
    }

    final bytes = Uint8List.fromList(encoded);
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = '${widget.leadType.toLowerCase()}_report_$timestamp.xlsx';

    try {
      await saveFile(bytes, fileName); // ✅ web + mobile dono handle

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report downloaded ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;
    final filteredTotalRevenue = rows.fold<double>(
      0,
      (sum, row) => sum + row.totalRevenue,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.summary
              .map((s) => _SummaryTile(data: s, color: widget.theme))
              .toList(),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8E4)),
          ))
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(
                'Today',
                _selectedFilter == _TableFilterType.today,
                () {
                  setState(() => _selectedFilter = _TableFilterType.today);
                },
              ),
              _filterChip(
                'This Week',
                _selectedFilter == _TableFilterType.thisWeek,
                () {
                  setState(() => _selectedFilter = _TableFilterType.thisWeek);
                },
              ),
              _filterChip(
                'This Month',
                _selectedFilter == _TableFilterType.thisMonth,
                () {
                  setState(() => _selectedFilter = _TableFilterType.thisMonth);
                },
              ),
              _filterChip(
                'Duration',
                _selectedFilter == _TableFilterType.duration,
                _pickDuration,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        '${widget.leadType} Project Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: widget.theme,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No records found for selected filter'),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          showCheckboxColumn: false,
                          headingRowHeight: 44,
                          dataRowMinHeight: 46,
                          dataRowMaxHeight: 56,
                          horizontalMargin: 10,
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFFFFAF0),
                          ),
                          dataRowColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFFE2EAF7);
                            }
                            return null;
                          }),
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.blueGrey.shade50,
                            ),
                            bottom: BorderSide(color: Colors.blueGrey.shade100),
                            top: BorderSide(color: Colors.blueGrey.shade100),
                          ),
                          columns:
                              [
                                DataColumn(
                                  label: Text(
                                    'Customer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Mobile',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme,
                                    ),
                                  ),
                                ),
                              ] +
                              (widget.showSystemFarmColumn
                                  ? [
                                      DataColumn(
                                        label: Text(
                                          'System Size(KW)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: widget.theme,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : const []) +
                              [
                                DataColumn(
                                  label: Text(
                                    'Start Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'End Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Total Revenue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme,
                                    ),
                                  ),
                                ),
                              ],
                          rows: rows
                              .map(
                                (r) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        r.customerName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        r.mobile,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          r.address,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (widget.showSystemFarmColumn)
                                      DataCell(
                                        Text(
                                          r.sizeText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary),
                                          ),
                                        ),
                                      ),
                                    DataCell(
                                      Text(
                                        widget.dateFmt.format(r.startDate),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        r.endDate != null
                                            ? widget.dateFmt.format(r.endDate!)
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        widget.currency.format(r.totalRevenue),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(
              0xFF16A34A,
            ).withValues(alpha: 0.08), // ✅ green tint
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF16A34A).withValues(alpha: 0.25),
            ), // ✅ green border
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: const Color(0xFF16A34A),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Revenue',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const Spacer(),
              Text(
                widget.currency.format(filteredTotalRevenue),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: widget.theme.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? widget.theme : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? widget.theme : const Color(0xFFE2E8E4),
      ),
      backgroundColor: Colors.white,
    );
  }
}

class _DurationPickerSheet extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final void Function(DateTime start, DateTime end) onApply;

  const _DurationPickerSheet({
    this.initialStart,
    this.initialEnd,
    required this.onApply,
  });

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  DateTime? _start;
  DateTime? _end;
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final initial = isStart ? (_start ?? now) : (_end ?? _start ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.success),
            onSurface: AppColors.textPrimary),
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        // agar start > end ho toh end reset karo
        if (_end != null && picked.isAfter(_end!)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  bool get _canApply => _start != null && _end != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: AppColors.success),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Select Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date selectors
          Row(
            children: [
              Expanded(
                child: _DateSelector(
                  label: 'From',
                  date: _start,
                  dateFmt: _dateFmt,
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 12),
              // Arrow icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateSelector(
                  label: 'To',
                  date: _end,
                  dateFmt: _dateFmt,
                  onTap: _start == null ? null : () => _pickDate(false),
                  disabled: _start == null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected range preview
          if (_start != null && _end != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_end!.difference(_start!).inDays + 1} days selected',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_dateFmt.format(_start!)}  –  ${_dateFmt.format(_end!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick presets
          const Text(
            'Quick Presets',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _preset('Last 7 days', () {
                final now = DateTime.now();
                setState(() {
                  _start = now.subtract(const Duration(days: 6));
                  _end = now;
                });
              }),
              _preset('Last 30 days', () {
                final now = DateTime.now();
                setState(() {
                  _start = now.subtract(const Duration(days: 29));
                  _end = now;
                });
              }),
              _preset('Last 3 months', () {
                final now = DateTime.now();
                setState(() {
                  _start = DateTime(now.year, now.month - 3, now.day);
                  _end = now;
                });
              }),
              _preset('This Year', () {
                final now = DateTime.now();
                setState(() {
                  _start = DateTime(now.year, 1, 1);
                  _end = now;
                });
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.borderLight)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _canApply
                      ? () {
                          widget.onApply(_start!, _end!);
                          Navigator.pop(context);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _preset(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat dateFmt;
  final VoidCallback? onTap;
  final bool disabled;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.dateFmt,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.bgSecondary)
              : hasDate
              ? AppColors.success).withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate
                ? AppColors.success).withValues(alpha: 0.4)
                : AppColors.borderLight),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hasDate
                    ? AppColors.success)
                    : AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: hasDate
                      ? AppColors.success)
                      : AppColors.textTertiary),
                ),
                const SizedBox(width: 6),
                Text(
                  hasDate ? dateFmt.format(date!) : 'Select',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? AppColors.textPrimary)
                        : AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTileData {
  final String title;
  final String value;
  const _SummaryTileData({required this.title, required this.value});
}

class _SummaryTile extends StatelessWidget {
  final _SummaryTileData data;
  final Color color;
  const _SummaryTile({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LeadReportRow {
  final String customerName;
  final String mobile;
  final String address;
  final String sizeText;
  final DateTime startDate;
  final DateTime? endDate;
  final double totalRevenue;

  const _LeadReportRow({
    required this.customerName,
    required this.mobile,
    required this.address,
    required this.sizeText,
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
  });
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}







