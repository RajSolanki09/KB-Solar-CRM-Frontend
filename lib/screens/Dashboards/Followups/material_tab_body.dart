import 'package:flutter/material.dart';
import 'followup_list_screen.dart';

class MaterialTabBody extends StatelessWidget {
  final List<FollowupItem> items;
  final VoidCallback onRefresh;
  final int page;
  final int totalPages;
  final int totalItems; // ← add kiya
  final ValueChanged<int> onPageChanged;

  const MaterialTabBody({
    super.key,
    required this.items,
    required this.onRefresh,
    required this.page,
    required this.totalPages,
    required this.totalItems, // ← add kiya
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TabBody(items: items, onRefresh: onRefresh),
        ),
        FollowupPagiantionBar(
          currentPage: page,
          totalPages: totalPages,
          totalItems: totalItems, 
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}