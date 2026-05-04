import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/admin_user_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_colors.dart';

const _kPrimary = AppColors.primary;
const _kPrimaryDark = AppColors.primaryLight;
const _kSurface = Color(0xFFF8F9FC);
const _kCard = Colors.white;

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
  String? _error;
  String _search = "";
  String _myRole = "";
  final Map<String, bool> _expandedSections = {
    "admin": true,
    "sales": true,
    "service": true,
    "installation": true,
  };

  bool get _isAdmin => _myRole.toLowerCase() == "admin";

  int get adminCount =>
      users.where((u) => u.role.toLowerCase() == "admin").length;
  int get salesCount =>
      users.where((u) => u.role.toLowerCase() == "sales").length;
  int get installationCount =>
      users.where((u) => u.role.toLowerCase() == "installation").length;
  int get serviceCount =>
      users.where((u) => u.role.toLowerCase() == "service").length;

  @override
  void initState() {
    super.initState(;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadMyRole();
    _loadUsers();
    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _search = _searchCtrl.text);
    };
  }

  @override
  void dispose() {
    _searchCtrl.dispose(;
    _fadeCtrl.dispose(;
    super.dispose(;
  }

  Future<void> _loadMyRole() async {
    try {
      final raw = await TokenStorage.readUser();
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (mounted) setState(() => _myRole = map['role']?.toString() ?? "";
      }
    } catch (_) {}
  }

  void _showFlush(String message, {bool isError = false}) {
    if (!mounted) return;
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3,
      margin: const EdgeInsets.all(16,
      borderRadius: BorderRadius.circular(12,
      backgroundColor: isError
          ? AppColors.error
          : const Color(0xFF22C55E,
      icon: AppSvgIcon(
        isError ? AppSvgAssets.triangleAlert : AppSvgAssets.circleCheckBig,
        color: Colors.white,
      ,
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context;
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    };
    try {
      final data = await _api.getUsers();
      if (!mounted) return;
      setState(() {
        users = data.map((e) => UserModel.fromJson(e)).toList();
        _isLoading = false;
      }
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      };
    }
  }

  List<UserModel> get _filtered => users.where((u) {
    if (_search.isEmpty) return true;
    return u.name.toLowerCase().contains(_search.toLowerCase()) ||
        u.email.toLowerCase().contains(_search.toLowerCase());
  }).toList(;

  _RoleStyle _roleStyle(String role) {
    switch (role.toLowerCase()) {
      case "admin":
        return _RoleStyle(
          color: AppColors.primary,
          bg: AppColors.primaryLightest,
          svgAsset: AppSvgAssets.shield,
        );
      case "sales":
        return _RoleStyle(
          color: AppColors.primary,
          bg: AppColors.primaryLightest,
          svgAsset: AppSvgAssets.trendingUp,
        );
      case "installation":
        return _RoleStyle(
          color: AppColors.primary,
          bg: AppColors.primaryLightest,
          svgAsset: AppSvgAssets.hammer,
        );
      case "service":
        return _RoleStyle(
          color: AppColors.primary,
          bg: AppColors.primaryLightest,
          svgAsset: AppSvgAssets.cog,
        );
      default:
        return _RoleStyle(
          color: AppColors.primary,
          bg: AppColors.primaryLightest,
          svgAsset: AppSvgAssets.userRound,
        );
    }
  }

  List<UserModel> _usersByRole(String role) {
    return _filtered
        .where((u) => u.role.toLowerCase() == role.toLowerCase())
        .toList();
  }

  String? _validateIndianPhone(String phone) {
    if (phone.isEmpty) return null;
    if (phone.length != 10) return "Phone number must be exactly 10 digits";
    final indianPhoneRegex = RegExp(r'^[6-9]\d{9}$';
    if (!indianPhoneRegex.hasMatch(phone)) {
      return "Enter a valid Indian mobile number (must start with 6-9)";
    }
    return null;
  }

  Future<void> _confirmDelete(UserModel user) async {
    if (!_isAdmin) {
      _showFlush("Only admins can delete users", isError: true);
      return;
    }
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(32),
                ,
                child: const AppSvgIcon(
                  AppSvgAssets.trash2,
                  color: AppColors.error,
                          size: 32,
                        ),
              ,
              const SizedBox(height: 20,
              const Text(
                "Delete User",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ,
              ,
              const SizedBox(height: 8,
              Text(
                "Are you sure you want to remove\n${user.name} from the system?",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ,
              ,
              const SizedBox(height: 28,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13,
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12,
                        ,
                      ,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ,
                      ,
                    ,
                  ,
                  const SizedBox(width: 12,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ,
                  ,
                    ],
                            ),
                          ],
                        ),
                      ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24,
                        ,
                      ,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12,
                            ,
                            child: AppSvgIcon(
                              isEditing
                                  ? AppSvgAssets.pencil
                                  : AppSvgAssets.userPlus,
                              color: Colors.white,
                              size: 22,
                            ,
                          ,
                          const SizedBox(width: 14,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? "Edit User" : "Add New User",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ,
                              ,
                              Text(
                                isEditing
                                    ? "Update user details"
                                    : "Fill in the details below",
                                style: TextStyle(
                                   color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ,
                              ,
        ],
      ),
                ],
              ),
            ),
                                },
                                borderRadius: BorderRadius.circular(12,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                    horizontal: 16,
                                  ,
                                  decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.borderLight,
                          ),
                                      Spacer(,
                                      AppSvgIcon(
                                        AppSvgAssets.chevronRight,
                                        size: 14,
                                        color: _kPrimary,
                                      ,
          ],
        ),
      ),
                              ,
                            ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                    ,
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ,
                                side: const BorderSide(
                                  color: AppColors.borderLight,
                                ,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12,
                                ,
                              ,
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ,
                              ,
                            ,
                          ,
                          const SizedBox(width: 12,
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12,
                                ,
                              ,
                              onPressed: () async {
                                 if (nameCtrl.text.trim().isEmpty ||
                                     emailCtrl.text.trim().isEmpty) {
                                   _showFlush(
                                     "Name and email required",
                                     isError: true,
                                   );
                                   return;
                                 }
                                 final phoneError = _validateIndianPhone(
                                   phoneCtrl.text.trim(),
                                 );
                                 if (phoneError != null) {
                                   _showFlush(phoneError, isError: true);
                                   return;
                                 }
                                final data = <String, String>{
                                  "name": nameCtrl.text.trim(,
                                  "email": emailCtrl.text.trim(,
                                   "phone": phoneCtrl.text.trim(),
                                   "role": role,
                                 };
                                if (!isEditing) {
                                  if (passCtrl.text.trim().isEmpty) {
                                    _showFlush(
                                      "Password required for new user",
                                      isError: true,
                                    ;
                                    return;
                                  }
                                   data["password"] = passCtrl.text.trim();
                                 }
                                 final nav = Navigator.of(dialogContext);
                                 try {
                                   if (!isEditing) {
                                     await _api.createUser(data);
                                   } else {
                                     await _api.updateUser(existing.id, data);
                                   }
                                   if (!mounted) return;
                                   nav.pop();
                                   await _loadUsers();
                                   _showFlush(
                                     isEditing
                                         ? "User updated successfully"
                                         : "User created successfully",
                                   );
                                 } catch (e) {
                                   _showFlush("Error: $e", isError: true);
                                 }
                              },
                              child: Text(
                                isEditing ? "Save Changes" : "Create User",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ,
                              ,
                            ,
                          ,
                          ],
                        ),
                      ),
                              ],
                            ),
              ,
            ;
          },
        ;
      },
    ;
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
  }

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
      style: const TextStyle(fontSize: 14,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14,
        counterText: "",
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0,
          child: AppSvgIcon(
            prefixSvgAsset,
            color: AppColors.textTertiary,
            size: 20,
          ,
        ,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        );
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;

    // -- Loading --------------------------------------------------------------
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _kSurface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ,
                  borderRadius: BorderRadius.circular(20,
                ,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ,
                ,
              ,
              const SizedBox(height: 16,
              const Text(
                "Loading users...",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14,
              ,
            ],
          ,
        ,
      ;
    }

    // -- Error ----------------------------------------------------------------
    if (_error != null) {
      return Scaffold(
        backgroundColor: _kSurface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSvgIcon(
                AppSvgAssets.wifiOff,
                size: 56,
                color: AppColors.textTertiary,
              ,
              const SizedBox(height: 16,
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ,
              const SizedBox(height: 24,
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                ,
                onPressed: _loadUsers,
                icon: const AppSvgIcon(AppSvgAssets.refreshCw,
                label: const Text("Retry",
              ,
            ],
          ,
        ,
      ;
    }

    // -- Main -----------------------------------------------------------------
    return Scaffold(
      backgroundColor: _kSurface,
      // -- AppBar (Sprinkler style) -------------------------------------------
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                  size: 18,
                ,
                onPressed: () => Navigator.maybePop(context,
              )
            : null,
        title: const Row(
          children: [
            AppSvgIcon(
              AppSvgAssets.userRoundCog,
              color: Colors.white,
              size: 18,
            ,
            SizedBox(width: 8,
            Text(
              'Manage Users',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ,
            ,
          ],
        ,
        actions: [
          IconButton(
            icon: const AppSvgIcon(AppSvgAssets.refreshCw, color: Colors.white,
            onPressed: _loadUsers,
          ,
        ],
      ,
      // -- FAB ---------------------------------------------------------------
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openUserDialog(null,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const AppSvgIcon(
                AppSvgAssets.plus,
                color: Colors.white,
                size: 18,
              ,
              label: const Text(
                'Add User',
                style: TextStyle(fontWeight: FontWeight.w700,
              ,
            )
          : null,
      // -- Body --------------------------------------------------------------
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 16,
                vertical: 24,
              ,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- Stat cards -----------------------------------------
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isMini = constraints.maxWidth < 400;
                      return Row(
                        children: [
                          _buildStatCard(
                            "Admins",
                            adminCount,
                            AppColors.primary,
                            AppColors.primaryLightest,
                            AppSvgAssets.shield,
                            isMini,
                          ,
                          const SizedBox(width: 10,
                          _buildStatCard(
                            "Sales",
                            salesCount,
                            AppColors.primary,
                            AppColors.primaryLightest,
                            AppSvgAssets.trendingUp,
                            isMini,
                          ,
                          const SizedBox(width: 10,
                          _buildStatCard(
                            "Install",
                            installationCount,
                            AppColors.primary,
                            AppColors.primaryLightest,
                            AppSvgAssets.hammer,
                            isMini,
                          ,
                          const SizedBox(width: 10,
                          _buildStatCard(
                            "Service",
                            serviceCount,
                            AppColors.primary,
                            AppColors.primaryLightest,
                            AppSvgAssets.cog,
                            isMini,
                          ,
                        ],
                      ;
                    },
                  ,

              const SizedBox(height: 24),

                  // -- Search bar -----------------------------------------
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14,
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
                    ,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 14,
                      decoration: InputDecoration(
                        hintText: "Search by name or email...",
                        hintStyle: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ,
                        prefixIcon: const AppSvgIcon(
                          AppSvgAssets.search,
                          color: AppColors.textTertiary,
                          size: 20,
                        ,
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const AppSvgIcon(
                                  AppSvgAssets.x,
                                  size: 18,
                                  color: AppColors.textTertiary,
                                ,
                                onPressed: () => _searchCtrl.clear(,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ,
                      ,
                    ,
                  ,

              const SizedBox(height: 20),

                  // -- Results label --------------------------------------
                  Row(
                    children: [
                      Text(
                        _search.isEmpty
                            ? "All Users"
                            : 'Results for "$_search"',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ,
                      ,
                      const SizedBox(width: 8,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.1,
                          borderRadius: BorderRadius.circular(20,
                        ,
                        child: Text(
                          "${_filtered.length}",
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ,
                        ,
                      ,
                    ],
                  ,

                  const SizedBox(height: 12,
                ],
              ,
            ,
          ,

          // -- Users list ---------------------------------------------------
          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSvgIcon(
                      AppSvgAssets.users,
                      size: 56,
                      color: AppColors.textLight,
                    ,
                    const SizedBox(height: 12,
                    Text(
                      _search.isNotEmpty
                          ? 'No users match "$_search"'
                          : "No users found",
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                      ,
                    ,
                  ],
                ,
              ,
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 16,
                  0,
                  isDesktop ? 32 : 16,
                  100, // extra bottom padding for FAB
                ,
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: Column(
                    children: [
                      _buildRoleSectionTable(
                        title: "Admins",
                        roleKey: "admin",
                        svgAsset: AppSvgAssets.shield,
                      ,
                      const SizedBox(height: 14,
                      _buildRoleSectionTable(
                        title: "Sales",
                        roleKey: "sales",
                        svgAsset: AppSvgAssets.trendingUp,
                      ,
                      const SizedBox(height: 14,
                      _buildRoleSectionTable(
                        title: "Service",
                        roleKey: "service",
                        svgAsset: AppSvgAssets.cog,
                      ,
                      const SizedBox(height: 14,
                      _buildRoleSectionTable(
                        title: "Installation",
                        roleKey: "installation",
                        svgAsset: AppSvgAssets.hammer,
                      ,
            ],
          ),
        ),
      ),
            ,
        ],
      ,
    ;
  }

  Widget _buildRoleSectionTable({
    required String title,
    required String roleKey,
    required String svgAsset,
  }) {
    final rs = _roleStyle(roleKey;
    final roleUsers = _usersByRole(roleKey;
    final isExpanded = _expandedSections[roleKey] ?? true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03,
            blurRadius: 10,
            offset: const Offset(0, 3,
          ,
        ],
      ,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16),
            onTap: () {
              setState(() {
                _expandedSections[roleKey] = !isExpanded;
              };
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12,
              decoration: BoxDecoration(
                color: rs.bg,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16,
                  bottom: Radius.circular(isExpanded ? 0 : 16,
                ,
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: rs.color.withValues(alpha: 0.2,
                        ,
                      )
                    : null,
              ,
              child: Row(
                children: [
                  AppSvgIcon(svgAsset, size: 18, color: rs.color,
                  const SizedBox(width: 8,
                  Text(
                    title,
                    style: TextStyle(
                      color: rs.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ,
                  ,
                  const Spacer(,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999,
                    border: Border.all(color: rs.color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    "${roleUsers.length}",
                    style: TextStyle(
                      color: rs.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ,
                  const SizedBox(width: 8,
                  AppSvgIcon(
                    isExpanded
                        ? AppSvgAssets.chevronUp
                        : AppSvgAssets.chevronDown,
                    color: rs.color,
                  ,
                ],
              ,
            ,
          ,
          if (isExpanded && roleUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No users in this section",
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            )
          else if (isExpanded)
            LayoutBuilder(
              builder: (context, constraints) {
                final sw = MediaQuery.of(context).size.width;
                final isLargeScreen = sw > 1200;
                final isXLargeScreen = sw > 1600;

                final Widget table = DataTable(
                  headingRowHeight: 46,
                  dataRowMinHeight: 54,
                  dataRowMaxHeight: 62,
                  horizontalMargin: 16,
                  columnSpacing: isXLargeScreen
                      ? 56
                      : isLargeScreen
                      ? 36
                      : 24,
                  headingTextStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ,
                  dataTextStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ,
                  columns: [
                    const DataColumn(label: Text("Name")),
                    const DataColumn(label: Text("Email")),
                    const DataColumn(label: Text("Phone")),
                    const DataColumn(label: Text("Role")),
                    if (_isAdmin) const DataColumn(label: Text("Actions")),
                  ],
                  rows: roleUsers.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(Text(user.name),
                        DataCell(
                          SizedBox(
                          width: isXLargeScreen
                              ? 480
                              : isLargeScreen
                                  ? 320
                                  : 240,
                               child: Text(
                                 user.email,
                                 overflow: TextOverflow.ellipsis,
                               ),
                          ,
                        ,
                         DataCell(Text(user.phone.isEmpty ? "-" : user.phone)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ,
                            decoration: BoxDecoration(
                              color: rs.bg,
                              borderRadius: BorderRadius.circular(20,
                              border: Border.all(
                                 color: rs.color.withValues(alpha: 0.25),
                               ),
                             ),
                             child: Text(
                               roleKey[0].toUpperCase() + roleKey.substring(1),
                               style: TextStyle(
                                 color: rs.color,
                                 fontSize: 11,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                            ,
                          ,
                        ,
                        if (_isAdmin)
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: "Edit",
                                  onPressed: () => _openUserDialog(user,
                                  icon: const AppSvgIcon(
                                    AppSvgAssets.pencil,
                                    color: AppColors.info,
                                    size: 19,
                                  ,
                                ,
                                IconButton(
                                  tooltip: "Delete",
                                  onPressed: () => _confirmDelete(user,
                                  icon: const AppSvgIcon(
                                    AppSvgAssets.trash2,
                                    color: AppColors.error,
                                    size: 19,
                                  ,
                                ,
                              ],
                            ,
                          ,
                      ],
                    );
                  }).toList(),
                );

                if (sw < 1000) {
                  return ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbVisibility: WidgetStateProperty.all(false),
                      trackVisibility: WidgetStateProperty.all(false),
                      thickness: WidgetStateProperty.all(4),
                      radius: const Radius.circular(4),
                      thumbColor: WidgetStateProperty.all(
                        const Color(0xFFEC4899).withValues(alpha: 0.5),
                      ),
                      trackColor: WidgetStateProperty.all(
                        const Color(0xFFEC4899).withValues(alpha: 0.08),
                      ),
) ,
child: Scrollbar(
                      thumbVisibility: false,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: table,
                      ),
                    ),
                }

                return SizedBox(width: constraints.maxWidth, child: table);
              },
            ),
        ],
      ,
    ;
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color color,
    Color bgColor,
    String svgAsset,
    bool isMini,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMini ? 8 : 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSvgIcon(svgAsset, color: color, size: isMini ? 16 : 20),
            SizedBox(height: isMini ? 6 : 8),
            Text(
              "$count",
              style: TextStyle(
                fontSize: isMini ? 20 : 24,
                fontWeight: FontWeight.w800,
                color: color,
              ,
              const SizedBox(height: isMini ? 4 : 8,),
             SizedBox(height: isMini ? 6 : 8,
            Text(
              label,
              style: TextStyle(
                fontSize: isMini ? 10 : 11,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
  }
}

class _RoleStyle {
  final Color color;
  final Color bg;
  final String svgAsset;
  const _RoleStyle({
    required this.color,
    required this.bg,
    required this.svgAsset,
  });
}








