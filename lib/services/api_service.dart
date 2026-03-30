import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/exception_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // The 'late' keyword with an assignment acts lazily.
  // It won't run this code until someone calls 'ApiService().dio'
  late final Dio _dio = _setupDio();

  Dio _setupDio() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.requestTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );

    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authorization token
          final token = await getStoredToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Remove null values from request data
          if (options.data != null) {
            options.data = _removeNullValues(options.data);
          }

          // Remove null values from query parameters
          if (options.queryParameters.isNotEmpty) {
            final cleanedParams = _removeNullValues(options.queryParameters);
            options.queryParameters = cleanedParams is Map<String, dynamic>
                ? cleanedParams
                : <String, dynamic>{};
          }

          handler.next(options);
        },
      ),
    );

    // Add logging in debug mode
    dioInstance.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) {
          debugPrint('[API] $object');
        },
      ),
    );

    return dioInstance;
  }

  Future<T?> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return response.data;
    } catch (e) {
      ExceptionHandler.handleException(e);
      return null;
    }
  }

  Future<T?> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );

      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return response.data;
    } catch (e) {
      ExceptionHandler.handleException(e);
      return null;
    }
  }

  Future<T?> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.data == null) {
        throw Exception('No data received from the server');
      }
      return response.data;
    } catch (e) {
      ExceptionHandler.handleException(e);
      return null;
    }
  }

  Future<T?> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return response.data;
    } catch (e) {
      ExceptionHandler.handleException(e);
      return null;
    }
  }

  // Remove null values from payload data recursively
  static dynamic _removeNullValues(dynamic data) {
    if (data is Map<String, dynamic>) {
      final Map<String, dynamic> filteredMap = {};

      for (final entry in data.entries) {
        final value = _removeNullValues(entry.value);

        // Only add non-null values to the filtered map
        if (value != null) {
          filteredMap[entry.key] = value;
        }
      }

      return filteredMap;
    } else if (data is List) {
      // For lists, recursively process each item but keep null items
      // (you might want to filter nulls from lists too if needed)
      return data.map(_removeNullValues).toList();
    } else {
      // For primitive values, return as-is (including null)
      return data;
    }
  }

  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.storageKeys.userToken);
    } catch (e) {
      return null;
    }
  }

  Future<bool> storeToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.storageKeys.userToken, token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.storageKeys.userToken);
      return true;
    } catch (e) {
      return false;
    }
  }
}
