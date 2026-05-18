import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/admin_user_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/core/app_colors.dart';

const _kPrimary     = AppColors.primary;
const _kPrimaryDark = AppColors.primaryDark;
const _kSurface     = AppColors.purple50;
const _kCard        = Colors.white;

class AdminManageUsersPage extends StatefulWidget {
  final Color appBarColor;
  const AdminManageUsersPage({super.key, this.appBarColor = _kPrimary});

  @override
  State<AdminManageUsersPage> createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends State<AdminManageUsersPage>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  late final AnimationController _fadeCtrl;

  List<UserModel> users = [];
  bool _isLoading = true;
  bool _isRefreshing = false; // separate flag — keeps main Scaffold alive during refresh
  String? _error;
  String _search = "";
  String _myRole = "";
  String _selectedRole = "admin";

  static const _roles      = ["admin", "sales", "service", "installation"];
  static const _roleTitles = ["Admin", "Sales", "Service", "Install"];
  static const _roleSvgs   = [
    AppSvgAssets.shield,
    AppSvgAssets.trendingUp,
    AppSvgAssets.cog,
    AppSvgAssets.hammer,
  ];

  bool get _isAdmin => _myRole.toLowerCase() == "admin";

  int get adminCount        => users.where((u) => u.role.toLowerCase() == "admin").length;
  int get salesCount        => users.where((u) => u.role.toLowerCase() == "sales").length;
  int get installationCount => users.where((u) => u.role.toLowerCase() == "installation").length;
  int get serviceCount      => users.where((u) => u.role.toLowerCase() == "service").length;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadMyRole();
    _loadUsers();
    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _search = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyRole() async {
    try {
      final raw = await TokenStorage.readUser();
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (mounted) setState(() => _myRole = map['role']?.toString() ?? "");
      }
    } catch (_) {}
  }

  // ✅ FIX: Always use the Scaffold's own context (this._scaffoldContext),
  //         never a dialog/sheet context that may already be popped.
  void _showFlush(String message, {bool isError = false}) {
    if (!mounted) return;
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: isError ? AppColors.purple700 : AppColors.primaryLight,
      icon: AppSvgIcon(
        isError ? AppSvgAssets.triangleAlert : AppSvgAssets.circleCheckBig,
        color: Colors.white,
      ),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context); // ← always `context` (Scaffold), never dialogContext/sheetCtx
  }

  Future<void> _loadUsers({bool isRefresh = false}) async {
    if (!mounted) return;
    // On initial load → show full loading screen.
    // On refresh → do NOT setState before data arrives; this prevents any rebuild
    // from happening while the dialog closing animation is still in flight,
    // which is what causes '_dependents.isEmpty' crash.
    if (!isRefresh) {
      setState(() { _isLoading = true; _error = null; });
    }
    try {
      final data = await _api.getUsers();
      if (!mounted) return;
      setState(() {
        users = data.map((e) => UserModel.fromJson(e)).toList();
        _isLoading = false;
        _isRefreshing = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; _isRefreshing = false; });
    }
  }

  List<UserModel> get _filtered => users.where((u) {
    if (_search.isEmpty) return true;
    return u.name.toLowerCase().contains(_search.toLowerCase()) ||
        u.email.toLowerCase().contains(_search.toLowerCase());
  }).toList();

  _RoleStyle _roleStyle(String role) {
    switch (role.toLowerCase()) {
      case "admin":
        return _RoleStyle(color: AppColors.primary,      bg: AppColors.purple100, svgAsset: AppSvgAssets.shield);
      case "sales":
        return _RoleStyle(color: AppColors.primaryLight, bg: AppColors.purple100, svgAsset: AppSvgAssets.trendingUp);
      case "installation":
        return _RoleStyle(color: AppColors.purple700,    bg: AppColors.purple100, svgAsset: AppSvgAssets.hammer);
      case "service":
        return _RoleStyle(color: AppColors.purple400,    bg: AppColors.purple100, svgAsset: AppSvgAssets.cog);
      default:
        return _RoleStyle(color: AppColors.textGray,     bg: AppColors.gray100,   svgAsset: AppSvgAssets.userRound);
    }
  }

  List<UserModel> _usersByRole(String role) =>
      _filtered.where((u) => u.role.toLowerCase() == role.toLowerCase()).toList();

  String? _validateIndianPhone(String phone) {
    if (phone.isEmpty) return null;
    if (phone.length != 10) return "Phone number must be exactly 10 digits";
    final indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!indianPhoneRegex.hasMatch(phone)) {
      return "Enter a valid Indian mobile number (must start with 6-9)";
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(UserModel user) async {
    if (!_isAdmin) { _showFlush("Only admins can delete users", isError: true); return; }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.purple100, borderRadius: BorderRadius.circular(32)),
                child: const AppSvgIcon(AppSvgAssets.trash2, color: AppColors.purple700, size: 32),
              ),
              const SizedBox(height: 20),
              const Text("Delete User",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to remove\n${user.name} from the system?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textGray, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text("Cancel",
                        style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ✅ FIX: Dialog is already closed here — use parent `mounted` + parent context
    if (confirm == true) {
      try {
        await _api.deleteUser(user.id);
        if (!mounted) return;
        _showFlush("User deleted successfully");
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        await _loadUsers(isRefresh: true);
      } catch (e) {
        if (!mounted) return;
        _showFlush("Delete failed: $e", isError: true);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHANGE PASSWORD SHEET
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openChangePasswordSheet(UserModel user) async {
    if (!_isAdmin) { _showFlush("Only admins can change passwords", isError: true); return; }

    final newPassCtrl     = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool showNew     = false;
    bool showConfirm = false;
    bool isLoading   = false;

    bool sheetSuccess = false;
    String? sheetApiError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        // ✅ sheetError shown INSIDE sheet via setState — sheet stays open on errors
        String? sheetError;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kPrimary, _kPrimaryDark],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const AppSvgIcon(AppSvgAssets.keyRound, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Change Password",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                            Text(user.name,
                              style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ✅ Inline error banner inside sheet
                    if (sheetError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.purple100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.purple700.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const AppSvgIcon(AppSvgAssets.triangleAlert, color: AppColors.purple700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(sheetError!,
                                style: const TextStyle(color: AppColors.purple700, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],

                    _buildTextField(
                      controller: newPassCtrl, label: "New Password",
                      obscure: !showNew, prefixSvgAsset: AppSvgAssets.lock,
                      suffix: IconButton(
                        icon: AppSvgIcon(
                          showNew ? AppSvgAssets.eyeOff : AppSvgAssets.eye,
                          color: AppColors.textLight, size: 20,
                        ),
                        onPressed: () => setSheetState(() => showNew = !showNew),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: confirmPassCtrl, label: "Confirm Password",
                      obscure: !showConfirm, prefixSvgAsset: AppSvgAssets.lock,
                      suffix: IconButton(
                        icon: AppSvgIcon(
                          showConfirm ? AppSvgAssets.eyeOff : AppSvgAssets.eye,
                          color: AppColors.textLight, size: 20,
                        ),
                        onPressed: () => setSheetState(() => showConfirm = !showConfirm),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary, foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isLoading ? null : () async {
                          final newPass     = newPassCtrl.text.trim();
                          final confirmPass = confirmPassCtrl.text.trim();

                          // ✅ Validation: show error INSIDE sheet, do NOT pop
                          if (newPass.isEmpty || confirmPass.isEmpty) {
                            setSheetState(() => sheetError = "Both fields are required");
                            return;
                          }
                          if (newPass.length < 6) {
                            setSheetState(() => sheetError = "Password must be at least 6 characters");
                            return;
                          }
                          if (newPass != confirmPass) {
                            setSheetState(() => sheetError = "Passwords do not match");
                            return;
                          }

                          setSheetState(() { sheetError = null; isLoading = true; });

                          try {
                            await _api.adminResetPassword(user.id, newPass);
                            // ✅ success: close sheet (controllers still alive here)
                            sheetSuccess = true;
                            Navigator.of(sheetCtx).pop();
                          } catch (e) {
                            // ✅ API error: show inside sheet, stay open
                            sheetApiError = "Error: $e";
                            setSheetState(() { isLoading = false; sheetError = sheetApiError; });
                          }
                        },
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Update Password",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // ✅ Sheet fully closed — defer dispose so sheet closing animation finishes
    // Same fix: immediate dispose after pop() triggers '_dependents.isEmpty' crash.
    Future.microtask(() {
      newPassCtrl.dispose();
      confirmPassCtrl.dispose();
    });

    if (!mounted) return;
    if (sheetSuccess) {
      _showFlush("Password changed successfully");
    }
    // API errors already shown as inline banner inside sheet
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADD / EDIT USER DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openUserDialog(UserModel? existing) async {
    if (!_isAdmin) { _showFlush("Only admins can manage users", isError: true); return; }

    final isEditing = existing != null;
    final nameCtrl  = TextEditingController(text: existing?.name ?? "");
    final emailCtrl = TextEditingController(text: existing?.email ?? "");
    final phoneCtrl = TextEditingController(text: existing?.phone ?? "");
    final passCtrl  = TextEditingController();
    String role     = existing?.role ?? "admin";

    // outcome flags — read AFTER dialog is fully closed
    bool?   success;
    String? apiError;
    bool    openChangePassword = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // ✅ dialogError shown INSIDE the dialog via its own setState — no flush needed
        String? dialogError;
        bool    isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kPrimary, _kPrimaryDark],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AppSvgIcon(
                              isEditing ? AppSvgAssets.pencil : AppSvgAssets.userPlus,
                              color: Colors.white, size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEditing ? "Edit User" : "Add New User",
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                              Text(isEditing ? "Update user details" : "Fill in the details below",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Body ────────────────────────────────────────────
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Inline error banner — dialog stays open on validation fail
                            if (dialogError != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.purple100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.purple700.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const AppSvgIcon(AppSvgAssets.triangleAlert, color: AppColors.purple700, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(dialogError!,
                                        style: const TextStyle(color: AppColors.purple700, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            _buildTextField(controller: nameCtrl, label: "Full Name", prefixSvgAsset: AppSvgAssets.userRound),
                            const SizedBox(height: 14),
                            _buildTextField(controller: emailCtrl, label: "Email Address",
                              prefixSvgAsset: AppSvgAssets.mail, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: phoneCtrl, label: "Phone Number",
                              prefixSvgAsset: AppSvgAssets.phone, keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              helperText: "Indian mobile number (6-9 start, 10 digits)",
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: role,
                              isExpanded: true,
                              icon: const AppSvgIcon(AppSvgAssets.chevronDown, size: 18),
                              decoration: InputDecoration(
                                labelText: "Role",
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: AppSvgIcon(AppSvgAssets.idCard, color: AppColors.textLight, size: 20),
                                ),
                                labelStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
                                filled: true,
                                fillColor: AppColors.purple50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.purple200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.purple200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                                ),
                              ),
                              items: ["admin", "sales", "installation", "service"]
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e[0].toUpperCase() + e.substring(1),
                                          style: const TextStyle(fontSize: 14)),
                                      ))
                                  .toList(),
                              onChanged: (val) { if (val != null) setDialogState(() => role = val); },
                            ),
                            if (!isEditing) ...[
                              const SizedBox(height: 14),
                              _buildTextField(controller: passCtrl, label: "Password",
                                prefixSvgAsset: AppSvgAssets.lock, obscure: true),
                            ],
                            if (isEditing) ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () {
                                  openChangePassword = true;
                                  Navigator.of(dialogContext).pop();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.purple200),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.purple100,
                                  ),
                                  child: const Row(
                                    children: [
                                      AppSvgIcon(AppSvgAssets.keyRound, size: 18, color: _kPrimary),
                                      SizedBox(width: 10),
                                      Text("Change Password",
                                        style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                      Spacer(),
                                      AppSvgIcon(AppSvgAssets.chevronRight, size: 14, color: _kPrimary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── Footer buttons ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: const BorderSide(color: AppColors.purple200),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                              child: const Text("Cancel",
                                style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary, foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isSaving ? null : () async {
                                // ── Validation: show error INSIDE dialog, do NOT pop ──
                                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                                  setDialogState(() => dialogError = "Name and email are required");
                                  return;
                                }
                                final phoneError = _validateIndianPhone(phoneCtrl.text.trim());
                                if (phoneError != null) {
                                  setDialogState(() => dialogError = phoneError);
                                  return;
                                }
                                if (!isEditing && passCtrl.text.trim().isEmpty) {
                                  setDialogState(() => dialogError = "Password is required for new user");
                                  return;
                                }

                                // Clear any previous error, show loading
                                setDialogState(() { dialogError = null; isSaving = true; });

                                final data = <String, String>{
                                  "name":  nameCtrl.text.trim(),
                                  "email": emailCtrl.text.trim(),
                                  "phone": phoneCtrl.text.trim(),
                                  "role":  role,
                                };
                                if (!isEditing) data["password"] = passCtrl.text.trim();

                                try {
                                  if (!isEditing) {
                                    await _api.createUser(data);
                                  } else {
                                    await _api.updateUser(existing.id, data);
                                  }
                                  // ✅ success: close dialog (controllers still alive here)
                                  success = true;
                                  Navigator.of(dialogContext).pop();
                                } catch (e) {
                                  // ✅ API error: show inside dialog, stay open
                                  apiError = "Error: $e";
                                  setDialogState(() { isSaving = false; dialogError = apiError; });
                                }
                              },
                              child: isSaving
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(isEditing ? "Save Changes" : "Create User",
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // ── Cleanup — defer dispose so dialog closing animation fully finishes ────
    // Disposing immediately after pop() causes '_dependents.isEmpty' assertion
    // because the dialog fade-out animation still holds a ref to the controllers.
    Future.microtask(() {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      passCtrl.dispose();
    });

    if (!mounted) return;

    // ✅ Change password flow — open sheet after dialog is fully gone
    if (openChangePassword && existing != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await _openChangePasswordSheet(existing);
      return;
    }

      // ✅ Show flush and refresh after the dialog close animation completes.
      // Navigator.of(dialogContext).pop() returns immediately, but the route transition
      // (≈300ms) may still be playing. We schedule the UI updates after a short delay.
      if (success == true) {
        // Give the dialog fade‑out animation extra time (≈600 ms)
        // before we touch the widget tree. This removes the short‑window
        // where a setState could orphan dependents.
        Future.delayed(const Duration(milliseconds: 600), () async {
          if (!mounted) return;
          _showFlush(isEditing ? "User updated successfully" : "User created successfully");
          await _loadUsers(isRefresh: true);
        });
      }

    // Note: API errors are already shown inside the dialog as inline banner,
    // so no extra flush needed here.
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT FIELD BUILDER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String prefixSvgAsset,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
        counterText: "",
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11, color: AppColors.textLight),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppSvgIcon(prefixSvgAsset, color: AppColors.textLight, size: 20),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.purple50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB CONTENT (DataTable)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabContent(bool isDesktop) {
    final roleUsers = _usersByRole(_selectedRole);
    final rs = _roleStyle(_selectedRole);

    if (roleUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSvgIcon(AppSvgAssets.users, size: 56, color: AppColors.purple300),
            const SizedBox(height: 12),
            Text(
              _search.isNotEmpty ? 'No users match "$_search"' : "No users in this section",
              style: const TextStyle(color: AppColors.textLight, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final table = DataTable(
      headingRowHeight: 46,
      dataRowMinHeight: 54,
      dataRowMaxHeight: 62,
      horizontalMargin: 16,
      columnSpacing: isDesktop ? 36 : 24,
      headingRowColor: WidgetStateProperty.all(AppColors.purple100),
      headingTextStyle: const TextStyle(
        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12,
      ),
      dataTextStyle: const TextStyle(color: AppColors.textDark, fontSize: 13),
      columns: [
        const DataColumn(label: Text("Name")),
        const DataColumn(label: Text("Email")),
        const DataColumn(label: Text("Phone")),
        const DataColumn(label: Text("Role")),
        if (_isAdmin) const DataColumn(label: Text("Actions")),
      ],
      rows: roleUsers.map((user) {
        return DataRow(cells: [
          DataCell(Text(user.name)),
          DataCell(SizedBox(
            width: isDesktop ? 320 : 240,
            child: Text(user.email, overflow: TextOverflow.ellipsis),
          )),
          DataCell(Text(user.phone.isEmpty ? "-" : user.phone)),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rs.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rs.color.withValues(alpha: 0.25)),
            ),
            child: Text(
              _selectedRole[0].toUpperCase() + _selectedRole.substring(1),
              style: TextStyle(color: rs.color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          )),
          if (_isAdmin)
            DataCell(Row(children: [
              IconButton(
                tooltip: "Edit",
                onPressed: () => _openUserDialog(user),
                icon: const AppSvgIcon(AppSvgAssets.pencil, color: AppColors.primary, size: 19),
              ),
              IconButton(
                tooltip: "Delete",
                onPressed: () => _confirmDelete(user),
                icon: const AppSvgIcon(AppSvgAssets.trash2, color: AppColors.purple700, size: 19),
              ),
            ])),
        ]);
      }).toList(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 16, 0, isDesktop ? 32 : 16, 100),
      child: FadeTransition(
        opacity: _fadeCtrl,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple200),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: isDesktop
              ? table
              : ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbVisibility: WidgetStateProperty.all(false),
                    trackVisibility: WidgetStateProperty.all(false),
                    thickness: WidgetStateProperty.all(4),
                    radius: const Radius.circular(4),
                    thumbColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.5)),
                    trackColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
                  ),
                  child: Scrollbar(
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: table,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STAT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatCard(
    String label, int count, Color color, Color bgColor, String svgAsset, bool isMini,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMini ? 8 : 12, vertical: isMini ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSvgIcon(svgAsset, color: color, size: isMini ? 16 : 20),
            SizedBox(height: isMini ? 6 : 8),
            Text("$count",
              style: TextStyle(fontSize: isMini ? 20 : 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: isMini ? 10 : 11,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop   = screenWidth > 1000;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _kSurface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kPrimaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
              ),
              const SizedBox(height: 16),
              const Text("Loading users...", style: TextStyle(color: AppColors.textGray, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _kSurface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSvgIcon(AppSvgAssets.wifiOff, size: 56, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadUsers,
                icon: const AppSvgIcon(AppSvgAssets.refreshCw),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(AppSvgAssets.chevronLeft, color: Colors.white, size: 18),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Row(
          children: [
            AppSvgIcon(AppSvgAssets.userRoundCog, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Manage Users',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white),
            onPressed: _isRefreshing ? null : () => _loadUsers(isRefresh: true),
          ),
        ],
        // Fixed preferredSize avoids layout thrashing (changing height mid-tree
        // can orphan InheritedWidget dependents). Always reserve 3px; hide via opacity.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: AnimatedOpacity(
            opacity: _isRefreshing ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 3,
            ),
          ),
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openUserDialog(null),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const AppSvgIcon(AppSvgAssets.plus, color: Colors.white, size: 18),
              label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 16, vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat cards
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isMini = constraints.maxWidth < 400;
                    return Row(
                      children: [
                        _buildStatCard("Admins",  adminCount,        AppColors.primary,      AppColors.purple100, AppSvgAssets.shield,     isMini),
                        const SizedBox(width: 10),
                        _buildStatCard("Sales",   salesCount,        AppColors.primaryLight, AppColors.purple100, AppSvgAssets.trendingUp, isMini),
                        const SizedBox(width: 10),
                        _buildStatCard("Install", installationCount, AppColors.purple700,    AppColors.purple100, AppSvgAssets.hammer,     isMini),
                        const SizedBox(width: 10),
                        _buildStatCard("Service", serviceCount,      AppColors.purple400,    AppColors.purple100, AppSvgAssets.cog,        isMini),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Search bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.purple200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 8, offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search by name or email...",
                      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: AppSvgIcon(AppSvgAssets.search, size: 16, color: AppColors.primary),
                      ),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const AppSvgIcon(AppSvgAssets.x, size: 18, color: AppColors.textLight),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Text(
                      _search.isEmpty ? "All Users" : 'Results for "$_search"',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("${_filtered.length}",
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Role tab bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.purple100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.purple200, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: List.generate(_roles.length, (i) {
                  final isSelected = _selectedRole == _roles[i];
                  final rs   = _roleStyle(_roles[i]);
                  final count = _usersByRole(_roles[i]).length;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = _roles[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          border: isSelected
                              ? Border.all(color: rs.color.withValues(alpha: 0.18))
                              : Border.all(color: Colors.transparent),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(color: rs.color.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 3)),
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: isSelected ? rs.color.withValues(alpha: 0.10) : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: AppSvgIcon(
                                  _roleSvgs[i], size: 13,
                                  color: isSelected ? rs.color : AppColors.textLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                _roleTitles[i],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? rs.color : AppColors.textLight,
                                ),
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? rs.color : AppColors.purple200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text("$count",
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.textGray,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: SingleChildScrollView(
                key: ValueKey(_selectedRole),
                child: _buildTabContent(isDesktop),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleStyle {
  final Color color;
  final Color bg;
  final String svgAsset;
  const _RoleStyle({required this.color, required this.bg, required this.svgAsset});
}