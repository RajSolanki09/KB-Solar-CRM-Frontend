import 'package:flutter/material.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

// ─────────────────────────────────────────────
//  COMPACT CARD
// ─────────────────────────────────────────────
class CompactCard extends StatelessWidget {
  final Widget child;
  const CompactCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

// ─────────────────────────────────────────────
//  COMPACT ROW
// ─────────────────────────────────────────────
class CompactRow extends StatelessWidget {
  final String label;
  final String value;
  const CompactRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION TITLE  ← used in all step screens
// ─────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppColors.primary,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ─────────────────────────────────────────────
//  NEXT STEP BUTTON
// ─────────────────────────────────────────────
class NextStepButton extends StatelessWidget {
  final VoidCallback onPressed;
  const NextStepButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const AppSvgIcon(AppSvgAssets.arrowRight, size: 16),
          label: const Text("Move to Next Step"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  COMPACT STEPPER
// ─────────────────────────────────────────────
class CompactStepper extends StatelessWidget {
  final List<String> steps;
  final dynamic currentStep;

  const CompactStepper({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final int currentIndex = (currentStep is int)
        ? currentStep
        : (currentStep as dynamic).index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progress",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...List.generate(steps.length, (i) {
          final isDone = i < currentIndex;
          final isCurrent = i == currentIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success
                        : isCurrent
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isDone
                        ? const AppSvgIcon(
                            AppSvgAssets.check,
                            size: 13,
                            color: AppColors.surface,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCurrent
                                  ? AppColors.surface
                                  : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isDone
                          ? AppColors.success
                          : isCurrent
                          ? AppColors.primary
                          : AppColors.background,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Current",
                      style: TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
