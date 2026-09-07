import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../error/exceptions.dart';

class ApiClient {
  static const String baseUrl = 'https://taskmanager.uat-lplusltd.com';

  final Dio _dio;
  String? _currentUserId;

  ApiClient({Dio? dio, String? currentUserId})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        _currentUserId = currentUserId {
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  String? get userId => _currentUserId;

  String _formatData(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.clear();

    // 1. Auth Query Parameter Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_currentUserId != null && _currentUserId!.isNotEmpty) {
            final queryParams = Map<String, dynamic>.from(options.queryParameters);
            if (!queryParams.containsKey('user_id')) {
              queryParams['user_id'] = _currentUserId;
              options.queryParameters = queryParams;
            }
          }
          return handler.next(options);
        },
      ),
    );

    // 2. Comprehensive Console Logging Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          developer.log(
            '🌐 [API REQ] ${options.method} ${options.uri}',
            name: 'ApiClient',
          );
          if (options.data != null) {
            developer.log(
              '📦 [API REQ DATA]:\n${_formatData(options.data)}',
              name: 'ApiClient',
            );
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '✅ [API RES ${response.statusCode}] ${response.requestOptions.method} ${response.requestOptions.uri}\n📄 [API RES BODY]:\n${_formatData(response.data)}',
            name: 'ApiClient',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          developer.log(
            '❌ [API ERR ${e.response?.statusCode ?? 'NO_STATUS'}] ${e.requestOptions.method} ${e.requestOptions.uri}\n⚠️ [API ERR MSG]: ${e.message}\n📄 [API ERR BODY]:\n${_formatData(e.response?.data)}',
            name: 'ApiClient',
            error: e,
          );
          return handler.next(e);
        },
      ),
    );

    // 3. Error Mapping Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          final mappedException = _mapDioError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mappedException,
            ),
          );
        },
      ),
    );
  }

  AppException _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException('Connection timed out or network unavailable.');
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      String message = 'Server error occurred.';

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          message = data['message'].toString();
        } else if (data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first.containsKey('msg')) {
              message = first['msg'].toString();
            } else {
              message = detail.toString();
            }
          } else {
            message = detail.toString();
          }
        }
      }

      return ServerException(message, statusCode);
    }

    return ServerException(error.message ?? 'Unknown network or server error.');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
