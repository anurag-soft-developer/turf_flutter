/// Disables flutter_query automatic retries (default is exponential backoff).
///
/// Return `null` from a [RetryResolver] to stop retrying after a failure.
Duration? noRetry(int count, Object? error) => null;

/// A few short retries for cold-start / flaky first requests.
Duration? shortRetry(int count, Object? error) {
  if (count >= 3) return null;
  return Duration(milliseconds: 400 * (count + 1));
}

