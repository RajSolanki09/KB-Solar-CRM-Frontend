import 'package:flutter/material.dart';
import 'package:solar_project/core/app_colors.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final Color activeColor;
  final bool showItemCount;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.totalItems = 0,
    this.activeColor =  AppColors.gray300,
    this.showItemCount = true,
  });

  List<Widget> _buildPageNumbers() {
    if (totalPages <= 0) {
      return [
        _PageNumBtn(page: 1, current: currentPage, onTap: onPageChanged, activeColor: activeColor),
      ];
    }

    final pages = <Widget>[];
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (start + 4).clamp(1, totalPages);
    start = (end - 4).clamp(1, totalPages);

    if (start > 1) {
      pages.add(_PageNumBtn(page: 1, current: currentPage, onTap: onPageChanged, activeColor: activeColor));
      if (start > 2) {
        pages.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.gray300, fontSize: 13)),
        ));
      }
    }

    for (int i = start; i <= end; i++) {
      pages.add(_PageNumBtn(page: i, current: currentPage, onTap: onPageChanged, activeColor: activeColor));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) {
        pages.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.gray300, fontSize: 13)),
        ));
      }
      pages.add(_PageNumBtn(page: totalPages, current: currentPage, onTap: onPageChanged, activeColor: activeColor));
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowBtn(
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
          activeColor: activeColor,
        ),
        const SizedBox(width: 4),
        ..._buildPageNumbers(),
        const SizedBox(width: 4),
        _ArrowBtn(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
          activeColor: activeColor,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray300)),
      ),
      child: showItemCount
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: "X results · Page N of N"
                Text(
                  '$totalItems results  ·  Page $currentPage of $totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                buttons,
              ],
            )
          : Center(child: buttons),
    );
  }
}

// ─── Page number button ───────────────────────────────────────────────────────

class _PageNumBtn extends StatelessWidget {
  final int page;
  final int current;
  final ValueChanged<int> onTap;
  final Color activeColor;

  const _PageNumBtn({
    required this.page,
    required this.current,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = page == current;
    return GestureDetector(
      onTap: isActive ? null : () => onTap(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor :  AppColors.gray300,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white :  AppColors.gray300,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Arrow button ─────────────────────────────────────────────────────────────

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final Color activeColor;

  const _ArrowBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color:  AppColors.gray300),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? activeColor :  AppColors.gray300,
        ),
      ),
    );
  }
}




