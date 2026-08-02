/// Disables flutter_query automatic retries (default is exponential backoff).
///
/// Return `null` from a [RetryResolver] to stop retrying after a failure.
Duration? noRetry(int count, Object? error) => null;
