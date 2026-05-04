/// TEMPLATE FOR NEW SCREENS IN KB SOLAR CRM
/// 
/// Copy this template when creating new screens/tabs.
/// Replace [SCREEN_NAME] and [DESCRIPTION] with your actual values.
/// Follow the color usage patterns shown below for 100% consistency.
///
/// Usage: Copy this entire file, rename, and replace all TODO sections

import 'package:flutter/material.dart';
import 'package:solar_project/Helper/app_colors.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';

class [SCREEN_NAME]Screen extends StatefulWidget {
  const [SCREEN_NAME]Screen({super.key});

  @override
  State<[SCREEN_NAME]Screen> createState() => _[SCREEN_NAME]ScreenState();
}

class _[SCREEN_NAME]ScreenState extends State<[SCREEN_NAME]Screen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ═══════════════════════════════════════════════════════════════════════
      // BACKGROUND COLOR
      // Always use: AppColors.bgPrimary for pages
      // ═══════════════════════════════════════════════════════════════════════
      backgroundColor: AppColors.bgPrimary,

      // ═══════════════════════════════════════════════════════════════════════
      // APP BAR - Color Usage Example
      // ═══════════════════════════════════════════════════════════════════════
      appBar: AppBar(
        backgroundColor: AppColors.primary,  // Main purple (logo color)
        foregroundColor: AppColors.buttonText,  // White text on purple
        title: const Text('[SCREEN_NAME]'),
        centerTitle: true,
        elevation: 0,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // MAIN BODY CONTENT
      // ═══════════════════════════════════════════════════════════════════════
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═════════════════════════════════════════════════════════════════
            // HEADING TEXT
            // Use: AppColors.textPrimary for main headings
            // ═════════════════════════════════════════════════════════════════
            Text(
              '[DESCRIPTION]',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,  // Dark text
              ),
            ),
            const SizedBox(height: 8),

            // ═════════════════════════════════════════════════════════════════
            // SECONDARY TEXT / SUBTITLE
            // Use: AppColors.textSecondary for secondary info
            // ═════════════════════════════════════════════════════════════════
            Text(
              'Subtitle or description here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,  // Muted gray
              ),
            ),
            const SizedBox(height: 24),

            // ═════════════════════════════════════════════════════════════════
            // CARD WITH CONTENT
            // Use: AppColors.bgSurface for cards (white background)
            // Use: AppColors.borderPrimary for card borders
            // ═════════════════════════════════════════════════════════════════
            _buildContentCard(),
            const SizedBox(height: 16),

            // ═════════════════════════════════════════════════════════════════
            // ERROR MESSAGE (if applicable)
            // Use: AppColors.error for error text/backgrounds
            // ═════════════════════════════════════════════════════════════════
            if (_errorMessage != null) _buildErrorMessage(),
            const SizedBox(height: 16),

            // ═════════════════════════════════════════════════════════════════
            // PRIMARY BUTTON
            // Use: AppColors.buttonPrimary for action buttons
            // ═════════════════════════════════════════════════════════════════
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,  // Logo purple
                  foregroundColor: AppColors.buttonText,      // White text
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _handlePrimaryAction,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.buttonText,  // White spinner
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Primary Action'),
              ),
            ),
            const SizedBox(height: 12),

            // ═════════════════════════════════════════════════════════════════
            // SECONDARY BUTTON
            // Use: AppColors.buttonSecondary for outline/secondary buttons
            // ═════════════════════════════════════════════════════════════════
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.buttonSecondaryText,  // Purple border
                  ),
                  foregroundColor: AppColors.buttonSecondaryText,  // Purple text
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleSecondaryAction,
                child: const Text('Secondary Action'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═════════════════════════════════════════════════════════════════════════════

  /// Content card example - shows all common color usages
  Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,  // White background for card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderPrimary,  // Light purple border
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),  // Subtle shadow
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card heading
          Text(
            'Card Title',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,  // Logo purple for emphasis
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // Row with icon and text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightest,  // Light background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppSvgIcon(
                  AppSvgAssets.checkCircle2,  // TODO: Replace with actual icon
                  size: 20,
                  color: AppColors.iconPrimary,  // Logo purple icon
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Label',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Additional info here',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,  // Muted text
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status badge example
          Wrap(
            spacing: 8,
            children: [
              _buildStatusBadge('Success', AppColors.success),
              _buildStatusBadge('Warning', AppColors.warning),
              _buildStatusBadge('Error', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  /// Status badge helper
  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),  // Light background
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Error message widget
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,  // Light red background
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'An error occurred',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // ACTIONS / METHODS
  // ═════════════════════════════════════════════════════════════════════════════

  void _handlePrimaryAction() {
    // TODO: Implement primary action
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate async operation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // _errorMessage = 'Something went wrong';  // Uncomment to show error
        });
      }
    });
  }

  void _handleSecondaryAction() {
    // TODO: Implement secondary action
    Navigator.pop(context);
  }
}
