import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';

class ServiceProfilePage extends StatefulWidget {
  const ServiceProfilePage({super.key});

  @override
  State<ServiceProfilePage> createState() => _ServiceProfilePageState();
}

class _ServiceProfilePageState extends State<ServiceProfilePage> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _error;

  // Locally picked image shown instantly before upload completes
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Fetch Profile ──────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // ── Build full image URL from backend path ─────────────────────────────────
  // Backend saves: "uploads/profiles/123.jpg"
  // Full URL is resolved from the shared API config.
  ImageProvider? _buildImageProvider() {
    // Show local file instantly while uploading
    if (_localImage != null) return FileImage(_localImage!);

    final rawPath = _user?['image'] as String?;
    final url = ApiService.buildImageUrl(rawPath);
    if (url == null) return null;
    return NetworkImage(url);
  }

  // ── Pick & Upload Profile Image ────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final source = await showModalBottomSheet<ImageSource>(
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
                child: AppSvgIcon(AppSvgAssets.images, color: AppColors.purple500),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;

      final file = File(picked.path);

      // Show local image immediately
      setState(() {
        _localImage = file;
        _isUploadingImage = true;
      });

      // ✅ Upload to backend — saves to uploads/profiles/
      final updatedUser = await _apiService.updateProfile(
        imagePath: picked.path,
        imageBytes: await picked.readAsBytes(),
        imageFilename: picked.name,
      );

      if (mounted) {
        setState(() {
          _user = updatedUser;
          _localImage = null; // clear local, use network image now
          _isUploadingImage = false;
        });
          AppFeedback.showSuccess(context, 'Profile photo updated!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localImage = null; // revert on failure
          _isUploadingImage = false;
        });
          AppFeedback.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // ── Logout Confirmation ────────────────────────────────────────────────────
  Future<void> _confirmLogout() async {
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

    if (confirmed == true && mounted) {
      await _apiService.logout();
      context.read<AppStateCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:   AppColors.slate50,
      appBar: AppBar(
        backgroundColor:   AppColors.slate50,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.purple500,
          ),
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.refreshCw,
              color: AppColors.purple500,
            ),
            onPressed: _loadProfile,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple500),
            )
          : _error != null
          ? _buildError()
          : _buildProfile(),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSvgIcon(AppSvgAssets.triangleAlert, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load profile',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const AppSvgIcon(AppSvgAssets.refreshCw),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor:   AppColors.purple500,
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

  // ── Main Profile Content ───────────────────────────────────────────────────
  Widget _buildProfile() {
    final name = _user?['name'] ?? 'N/A';
    final email = _user?['email'] ?? 'N/A';
    final phone = _user?['phone'] ?? 'N/A';
    final role = _user?['role'] ?? 'N/A';
    final status = _user?['status'] ?? 'N/A';

    final roleDisplay = role.toString().isNotEmpty
        ? role.toString()[0].toUpperCase() + role.toString().substring(1)
        : role.toString();

    final isActive = status.toString().toLowerCase() == 'active';
    final imageProvider = _buildImageProvider();
    final hasImage = imageProvider != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Profile Header Card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple500, AppColors.purpleVariant1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:   AppColors.purple500.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Avatar with Camera Icon ──────────────────────────────
                Stack(
                  children: [
                    // Profile picture
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: hasImage ? imageProvider : null,
                      child: !hasImage
                          ? const AppSvgIcon(
                              AppSvgAssets.userRound,
                              size: 40,
                              color: AppColors.purple500,
                            )
                          : null,
                    ),

                    // Uploading spinner overlay
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.black45,
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),

                    // Camera button
                    if (!_isUploadingImage)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:   AppColors.purple500,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const AppSvgIcon(
                              AppSvgAssets.camera,
                              size: 16,
                              color: AppColors.purple500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 20),

                // ── Name, Role, Status ───────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        roleDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Info Tiles ───────────────────────────────────────────────────
          _infoTile(AppSvgAssets.mail, 'Email', email),
          _infoTile(AppSvgAssets.phone, 'Phone', phone),
          _infoTile(AppSvgAssets.idCard, 'Role', roleDisplay),

          const SizedBox(height: 30),

          // ── Logout Button ────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const AppSvgIcon(AppSvgAssets.logOut, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Info Tile ─────────────────────────────────────────────────────
  Widget _infoTile(String svgAsset, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          AppSvgIcon(svgAsset, color:   AppColors.purple500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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




