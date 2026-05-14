// lib/Helper/profile_widgets.dart
//
// Shared widgets and helpers for all profile screens (Admin, Sales,
// Installation).  Eliminates identical error-view, photo-source sheet, and
// logout-dialog code that was previously copy-pasted into every profile page.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

/// Centred error state shown when a profile fails to load.
///
/// Identical to the private `_buildError()` method that each profile page
/// previously implemented inline.
class ProfileErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final Color accentColor;

  const ProfileErrorView({
    required this.message,
    required this.onRetry,
    this.accentColor = AppColors.textLight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSvgIcon(AppSvgAssets.triangleAlert, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message ?? 'Failed to load profile',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const AppSvgIcon(AppSvgAssets.refreshCw, size: 20, color: Colors.white),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Source Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the bottom sheet that lets the user pick a photo source (camera or
/// gallery).  Returns the chosen [ImageSource], or `null` if dismissed.
///
/// Replaces the identical `showModalBottomSheet` block that was copy-pasted
/// into every profile page's `_pickAndUploadImage` method.
Future<ImageSource?> showProfilePhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Upload Profile Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.purpleLight1,
              child: AppSvgIcon(AppSvgAssets.camera, color: AppColors.purple500),
            ),
            title: const Text('Take a Photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.purpleLight1,
              child: AppSvgIcon(
                AppSvgAssets.images,
                color: AppColors.purple500,
              ),
            ),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a logout confirmation [AlertDialog] for profile pages.
///
/// Calls [onConfirm] (synchronously) when the user taps "Logout".
/// The caller is responsible for performing the actual logout work
/// (e.g. `apiService.logout()` + cubit update).
Future<void> showProfileLogoutConfirmation(
  BuildContext context, {
  required Future<void> Function() onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          AppSvgIcon(AppSvgAssets.logOut, color: Colors.red),
          SizedBox(width: 10),
          Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'Are you sure you want to logout from your account?',
        style: TextStyle(fontSize: 15, color: Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Logout',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) await onConfirm();
}


