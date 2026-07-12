import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../config/constants.dart';
import '../../utils/exception_handler.dart';

class QueryAsyncBody<TData, TError> extends StatelessWidget {
  final QueryResult<TData, TError> state;
  final Widget Function(TData data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  const QueryAsyncBody({
    super.key,
    required this.state,
    required this.data,
    this.onRetry,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || (state.isFetching && state.data == null)) {
      return loading ??
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
    }

    if (state.isError) {
      final message = state.error != null
          ? ExceptionHandler.handleGenericException(state.error)
          : AppConstants.errorMessages.unknown;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final value = state.data;
    if (value == null) {
      return const Center(child: Text('No data'));
    }

    return data(value);
  }
}
