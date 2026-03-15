import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class ExceptionHandler {
  static void showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(AppColors.errorColor),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(AppColors.successColor),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showInfoToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(AppColors.primaryColor),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static String handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';
      case DioExceptionType.badResponse:
        final responseData = e.response?.data;
        if (responseData?['message'] != null) {
          return responseData['message'].toString();
        }
        return AppConstants.errorMessages.unknown;
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.unknown:
      default:
        return AppConstants.errorMessages.unknown;
    }
  }

  static String handleGenericException(dynamic e) {
    if (e is DioException) {
      return handleDioException(e);
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  static void handleException(dynamic e) {
    final errorMessage = handleGenericException(e);
    showErrorToast(errorMessage);
  }

  // Extract validation errors from API response
  static String? extractValidationErrors(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final errors = responseData['errors'];
      if (errors is Map<String, dynamic>) {
        final List<String> errorMessages = [];
        errors.forEach((field, messages) {
          if (messages is List) {
            errorMessages.addAll(messages.map((msg) => msg.toString()));
          } else {
            errorMessages.add(messages.toString());
          }
        });
        return errorMessages.isNotEmpty ? errorMessages.first : null;
      }
      final message = responseData['message'];
      if (message is String) {
        return message;
      }
    }
    return null;
  }
}
