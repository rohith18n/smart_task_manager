import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

    // 2. Debug Logging Interceptor
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[API REQ] ${options.method} ${options.uri}');
            if (options.data != null) {
              debugPrint('[API BODY] ${options.data}');
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '[API RES] ${response.statusCode} from ${response.requestOptions.uri}',
            );
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            debugPrint(
              '[API ERR] ${e.response?.statusCode}: ${e.message} at ${e.requestOptions.uri}',
            );
            return handler.next(e);
          },
        ),
      );
    }

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
