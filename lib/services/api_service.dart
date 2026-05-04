import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:solar_project/core/constants/api_constants.dart';
import 'package:solar_project/core/network/dio_client.dart'; // ← TokenStorage lives here

class ApiService {
  late final Dio _dio;

  // ── Simple in-memory cache ─────────────────────────────────────────────────
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  static void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  /// Converts backend image path → full URL
  static String? buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return imagePath;
    return ApiConstants.imageUrl(imagePath);
  }

  ApiService({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.serverUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ── Cache Helper ───────────────────────────────────────────────────────────
  Future<dynamic> _cachedGet(String url, {Map<String, dynamic>? params}) async {
    final cacheKey = params != null ? '$url?${params.toString()}' : url;
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) return cached.data;
    final resp = await _dio.get(url, queryParameters: params);
    _cache[cacheKey] = _CacheEntry(resp.data);
    return resp.data;
  }

  // =============================
  // 🔐 AUTH APIs
  // =============================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final resp = await _dio.post(
        ApiConstants.apiPath(ApiEndpoints.authLogin),
        data: {'email': email, 'password': password},
      );
      print('Login response: ${resp.data}'); // Debug print
      if (resp.data['success'] == true) {
        final token = resp.data['token'] as String;
        final user = resp.data['user'] as Map<String, dynamic>;
        await TokenStorage.write(token);
        await TokenStorage.writeUser(jsonEncode(user));
        clearCache();
        return user;
      }
      throw Exception(resp.data['message']);
    } on DioException catch (e) {
      print('Login DioException: ${e.response?.data}'); // Debug print
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.apiPath(ApiEndpoints.authLogout));
    } catch (_) {}
    await TokenStorage.clearAll();
    clearCache();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final resp = await _dio.put(
        ApiConstants.apiPath(ApiEndpoints.authChangePassword),
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      if (resp.data['success'] != true) {
        throw Exception(resp.data['message'] ?? 'Failed to change password');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to change password',
      );
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final data = await _cachedGet(ApiConstants.apiPath(ApiEndpoints.authProfile));
      if (data['success'] == true) {
        final user = Map<String, dynamic>.from(data['user']);
        await TokenStorage.writeUser(jsonEncode(user));
        return user;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? imagePath,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final formData = FormData();
      if (name != null && name.isNotEmpty) {
        formData.fields.add(MapEntry('name', name));
      }
      if (email != null && email.isNotEmpty) {
        formData.fields.add(MapEntry('email', email));
      }
      if (phone != null && phone.isNotEmpty) {
        formData.fields.add(MapEntry('phone', phone));
      }
      if (imageBytes != null && imageBytes.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              imageBytes,
              filename: imageFilename ?? 'profile.jpg',
            ),
          ),
        );
      } else if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imagePath,
              filename: imageFilename ?? imagePath.split('/').last,
            ),
          ),
        );
      }
      final resp = await _dio.put(
        ApiConstants.apiPath(ApiEndpoints.authProfile),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (resp.data['success'] == true) {
        final user = Map<String, dynamic>.from(resp.data['user']);
        await TokenStorage.writeUser(jsonEncode(user));
        clearCache(ApiConstants.apiPath(ApiEndpoints.authProfile));
        return user;
      }
      throw Exception(resp.data['message'] ?? 'Failed to update profile');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  // =============================
  // 👤 USER MANAGEMENT APIs
  // =============================

  Future<List<dynamic>> getUsers() async {
    try {
      final data = await _cachedGet(ApiConstants.apiPath(ApiEndpoints.admin));
      print('Get users response: $data'); // Debug print
      return data['staff'] ?? [];
    } on DioException catch (e) {
      print('Get users DioException: ${e.response?.data}'); // Debug print
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch users');
    }
  }

  Future<List<dynamic>> getStaff({
    String? role,
    String? status,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (role != null && role.isNotEmpty) params['role'] = role;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final data = await _cachedGet(
        ApiConstants.apiPath(ApiEndpoints.adminStaff),
        params: params,
      );
      return data['staff'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch staff');
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      print('Creating user with data: $data'); // Debug print
      final resp = await _dio.post(ApiConstants.apiPath(ApiEndpoints.admin), data: data);
      print('Create user response: ${resp.data}'); // Debug print
      clearCache(ApiConstants.apiPath(ApiEndpoints.admin));
    } on DioException catch (e) {
      print('Create user DioException: ${e.response?.data}'); // Debug print
      throw Exception(e.response?.data['message'] ?? 'Failed to create user');
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await _dio.put(ApiConstants.apiPath(ApiEndpoints.adminById(id)), data: data);
      clearCache(ApiConstants.apiPath(ApiEndpoints.admin));
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update user');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete(ApiConstants.apiPath(ApiEndpoints.adminById(id)));
      clearCache(ApiConstants.apiPath(ApiEndpoints.admin));
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete user');
    }
  }

  Future<void> toggleUserStatus(String id, bool status) async {
    try {
      await _dio.patch(
        ApiConstants.apiPath(ApiEndpoints.adminStatus(id)),
        data: {'isActive': status},
      );
      clearCache(ApiConstants.apiPath(ApiEndpoints.admin));
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to toggle user status',
      );
    }
  }

  /// Admin-only: reset any user's password with proper bcrypt hashing
  /// Calls PUT /api/admin/:id/reset-password
  Future<void> adminResetPassword(String userId, String newPassword) async {
    try {
      final resp = await _dio.put(
        ApiConstants.apiPath(ApiEndpoints.adminResetPassword(userId)),
        data: {'newPassword': newPassword},
      );
      if (resp.data['success'] != true) {
        throw Exception(resp.data['message'] ?? 'Failed to update password');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update password',
      );
    }
  }

  // =============================
  // 🛠️ SERVICE REQUEST APIS
  // =============================

  Future<Map<String, dynamic>> getServices({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
    String? priority,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (priority != null && priority.isNotEmpty) {
        params['priority'] = priority;
      }

      final data = await _cachedGet(ApiEndpoints.service, params: params);
      if (data['success'] == true) return Map<String, dynamic>.from(data);
      throw Exception(data['message'] ?? 'Failed to load services');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load services');
    }
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    try {
      final resp = await _dio.post(ApiEndpoints.service, data: data);
      if (resp.statusCode == 201 || resp.data['success'] == true) {
        clearCache(ApiEndpoints.service);
        return Map<String, dynamic>.from(resp.data['service'] ?? resp.data);
      }
      throw Exception(resp.data['message'] ?? 'Failed to create service');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create service',
      );
    }
  }

  Future<Map<String, dynamic>> updateService(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final resp = await _dio.put(ApiEndpoints.serviceById(id), data: data);
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(ApiEndpoints.service);
        return Map<String, dynamic>.from(resp.data['service'] ?? resp.data);
      }
      throw Exception(resp.data['message'] ?? 'Failed to update service');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update service',
      );
    }
  }

  Future<void> deleteService(String id) async {
    try {
      final resp = await _dio.delete(ApiEndpoints.serviceById(id));
      if (resp.statusCode != 200 && resp.data['success'] != true) {
        throw Exception(resp.data['message'] ?? 'Failed to delete service');
      }
      clearCache(ApiEndpoints.service);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete service',
      );
    }
  }

  Future<Map<String, dynamic>> assignService(
    String id,
    String technicianId,
  ) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.serviceAssign(id),
        data: {'assignedTo': technicianId},
      );
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(ApiEndpoints.service);
        return Map<String, dynamic>.from(resp.data['service'] ?? resp.data);
      }
      throw Exception(resp.data['message'] ?? 'Failed to assign service');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to assign service',
      );
    }
  }

  // =============================
  // 📦 MATERIAL APIs
  // =============================

  static String get _materialApiPath => ApiConstants.apiPath(ApiEndpoints.material);
  static String get _materialCustomerApiPath => ApiConstants.apiPath(ApiEndpoints.materialCustomer);
  static String get _materialSalesApiPath => ApiConstants.apiPath(ApiEndpoints.materialSalesStaff);

  Future<Map<String, dynamic>> getMaterialFormSchema() async {
    try {
      final data = await _cachedGet('$_materialApiPath/schema');
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['schema'] ?? {});
      }
      throw Exception(data['message'] ?? 'Failed to load material schema');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load material schema',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMaterials() async {
    try {
      final data = await _cachedGet(_materialApiPath);
      final raw = (data['materials'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch materials',
      );
    }
  }

  Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.post(_materialApiPath, data: payload);
      if (resp.statusCode == 201 || resp.data['success'] == true) {
        clearCache(_materialApiPath);
        clearCache('$_materialApiPath/schema');
        return Map<String, dynamic>.from(resp.data['material'] ?? {});
      }
      throw Exception(resp.data['message'] ?? 'Failed to create material');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to create material',
      );
    }
  }

  Future<Map<String, dynamic>> updateMaterial(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.put('$_materialApiPath/$id', data: payload);
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(_materialApiPath);
        clearCache('$_materialApiPath/schema');
        return Map<String, dynamic>.from(resp.data['material'] ?? {});
      }
      throw Exception(resp.data['message'] ?? 'Failed to update material');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to update material',
      );
    }
  }

  Future<void> deleteMaterial(String id) async {
    try {
      final resp = await _dio.delete('$_materialApiPath/$id');
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(_materialApiPath);
        clearCache('$_materialApiPath/schema');
        return;
      }
      throw Exception(resp.data['message'] ?? 'Failed to delete material');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to delete material',
      );
    }
  }

  Future<Map<String, dynamic>> getMaterialCustomerFormSchema() async {
    try {
      final data = await _cachedGet('$_materialCustomerApiPath/schema');
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['schema'] ?? {});
      }
      throw Exception(
        data['message'] ?? 'Failed to load material customer schema',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Failed to load material customer schema',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMaterialCustomers() async {
    try {
      final data = await _cachedGet(_materialCustomerApiPath);
      final raw = (data['customers'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch material customers',
      );
    }
  }

  Future<Map<String, dynamic>> getMaterialCustomerById(String id) async {
    try {
      final data = await _cachedGet('$_materialCustomerApiPath/$id');
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['customer'] ?? {});
      }
      throw Exception(data['message'] ?? 'Failed to fetch material customer');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch material customer',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMaterialSalesPeople() async {
    try {
      final data = await _cachedGet(_materialSalesApiPath);
      final raw = (data['staff'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch sales staff',
      );
    }
  }

  Future<Map<String, dynamic>> createMaterialCustomer(
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.post(_materialCustomerApiPath, data: payload);
      if (resp.statusCode == 201 || resp.data['success'] == true) {
        clearCache(_materialCustomerApiPath);
        clearCache('$_materialCustomerApiPath/schema');
        return Map<String, dynamic>.from(resp.data['customer'] ?? {});
      }
      throw Exception(
        resp.data['message'] ?? 'Failed to create material customer',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to create material customer',
      );
    }
  }

  Future<Map<String, dynamic>> updateMaterialCustomer(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.put('$_materialCustomerApiPath/$id', data: payload);
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(_materialCustomerApiPath);
        clearCache('$_materialCustomerApiPath/schema');
        return Map<String, dynamic>.from(resp.data['customer'] ?? {});
      }
      throw Exception(resp.data['message'] ?? 'Failed to update material customer');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to update material customer',
      );
    }
  }

  Future<Map<String, dynamic>> updateMaterialCustomerPipeline(
    String id, {
    required String step,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final data = <String, dynamic>{'step': step, ...payload};
      final resp = await _dio.put(
        '$_materialCustomerApiPath/$id/pipeline',
        data: data,
      );
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(_materialCustomerApiPath);
        clearCache('$_materialCustomerApiPath/$id');
        return Map<String, dynamic>.from(resp.data['customer'] ?? {});
      }
      throw Exception(
        resp.data['message'] ?? 'Failed to update customer pipeline',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to update customer pipeline',
      );
    }
  }

  Future<Map<String, dynamic>> markMaterialCustomerFollowupDone(
    String id,
  ) async {
    try {
      final resp = await _dio.put('$_materialCustomerApiPath/$id/followup-done');
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(_materialCustomerApiPath);
        clearCache('$_materialCustomerApiPath/$id');
        return Map<String, dynamic>.from(resp.data['customer'] ?? {});
      }
      throw Exception(resp.data['message'] ?? 'Failed to mark follow-up done');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to mark follow-up done',
      );
    }
  }

  Future<void> deleteMaterialCustomer(String id) async {
    try {
      final resp = await _dio.delete('$_materialCustomerApiPath/$id');
      if (resp.statusCode == 200 || resp.data['success'] == true) {
        clearCache(_materialCustomerApiPath);
        clearCache('$_materialCustomerApiPath/schema');
        return;
      }
      throw Exception(resp.data['message'] ?? 'Failed to delete material customer');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to delete material customer',
      );
    }
  }
}

// ── Cache Entry ────────────────────────────────────────────────────────────────
class _CacheEntry {
  final dynamic data;
  final DateTime _createdAt;
  _CacheEntry(this.data) : _createdAt = DateTime.now();
  bool get isExpired =>
      DateTime.now().difference(_createdAt) > ApiService._cacheDuration;
}
