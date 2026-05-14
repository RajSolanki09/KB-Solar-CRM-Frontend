import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

class MonthlyRevenueDetailPage extends StatelessWidget {
  final String monthName;
  final int monthNumber;
  final int year;
  final double totalRevenue;
  final double solarRevenue;
  final double sprinklerRevenue;
  final double serviceRevenue;
  final int totalLeads;

  const MonthlyRevenueDetailPage({
    super.key,
    required this.monthName,
    required this.monthNumber,
    required this.year,
    required this.totalRevenue,
    required this.solarRevenue,
    required this.sprinklerRevenue,
    required this.serviceRevenue,
    required this.totalLeads,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final categories = [
      _Category(
        'Solar',
        solarRevenue,
          AppColors.amber,
        AppSvgAssets.sun,
      ),
      _Category(
        'Sprinkler',
        sprinklerRevenue,
          AppColors.cyan,
        AppSvgAssets.droplet,
      ),
      _Category(
        'Service',
        serviceRevenue,
          AppColors.green,
        AppSvgAssets.cog,
      ), // ✅ updated to green
    ];

    return Scaffold(
      backgroundColor:   AppColors.slate50,
      appBar: AppBar(
        backgroundColor:   AppColors.slate50,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '$monthName $year',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.slate800,
          ),
        ),
        leading: IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.chevronLeft,
            color: AppColors.slate800,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.success, AppColors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:   AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AppSvgIcon(
                          AppSvgAssets.calendarDays,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$monthName Total Revenue',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currency.format(totalRevenue),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalLeads total entries this month',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Revenue Breakdown ──
            const Text(
              'Revenue Breakdown',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
            const SizedBox(height: 14),

            // Stacked bar
            if (totalRevenue > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: categories
                        .where((c) => c.amount > 0)
                        .map(
                          (c) => Expanded(
                            flex: (c.amount * 100 / totalRevenue).round().clamp(
                              1,
                              100,
                            ),
                            child: Container(color: c.color),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Category cards
            ...categories.map(
              (c) => _CategoryCard(
                category: c,
                total: totalRevenue,
                currency: currency,
              ),
            ),

            const SizedBox(height: 24),

            // ── Summary Stats ──
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Total Revenue',
                    value: currency.format(totalRevenue),
                    isBold: true,
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'Total Leads / Services',
                    value: '$totalLeads',
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'Avg. per Lead / Service',
                    value: totalLeads > 0
                        ? currency.format(totalRevenue / totalLeads)
                        : '₹0',
                  ),
                  if (solarRevenue > 0 || sprinklerRevenue > 0) ...[
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Top Category',
                      value:
                          solarRevenue >= sprinklerRevenue &&
                              solarRevenue >= serviceRevenue
                          ? 'Solar'
                          : sprinklerRevenue >= serviceRevenue
                          ? 'Sprinkler'
                          : 'Service',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String name;
  final double amount;
  final Color color;
  final String svgAsset;
  const _Category(this.name, this.amount, this.color, this.svgAsset);
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final double total;
  final NumberFormat currency;

  const _CategoryCard({
    required this.category,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (category.amount / total * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppSvgIcon(
              category.svgAsset,
              color: category.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0
                        ? (category.amount / total).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: category.color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(category.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: category.color,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color:   AppColors.slate800,
          ),
        ),
      ],
    );
  }
}




